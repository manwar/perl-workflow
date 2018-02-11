package Workflow::Persister::DBIx;

use warnings;
use strict;
use base qw( Workflow::Persister );

use DateTime;
use Log::Log4perl qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );
use Workflow::History;
use Carp qw(croak);
use English qw( -no_match_vars );

$Workflow::Persister::DBIx::VERSION = '1.00';

my @FIELDS = qw( 
    schema
    dsn
    user
    password
);

my @CUSTOM_FIELDS = qw(
    time_zone

    workflow_table
    workflow_field_id
    workflow_field_type
    workflow_field_state
    workflow_field_last_update
    workflow_field_context

    history_table
    history_field_id
    history_field_workflow_id
    history_field_action
    history_field_description
    history_field_state
    history_field_user
    history_field_date
);

__PACKAGE__->mk_accessors(@FIELDS);
__PACKAGE__->mk_accessors(@CUSTOM_FIELDS);

sub init {
    my ( $self, $params ) = @_;

    $self->SUPER::init($params);

    my $log = get_logger();

    unless ( $params->{dsn} ) {
        configuration_error "DBIx persister configuration must include ",
            "key 'dsn' which maps to the first parameter ",
            "in the DBIx 'connect()' call.";
    }

    $self->dsn($params->{dsn});
    $log->info(
          "The configured dsn is '"
        , $self->dsn
        , "'"
    );

    $self->_assign_customization($params);

    for (qw( user password )) {
        $self->$_( $params->{$_} ) if ( defined $params->{$_} );
    }

    # Connect to Schema
    my $schema;

    eval {
        my $wf_table  = $self->workflow_table;
        my $time_zone = 'floating';

        # Ugly hack I know... But didn't find any other way of making a dynamic schema
        my $to_eval = 'use Workflow::Persister::DBIx::Schema ' .
                      $self->_stringify_customization($params);

        # Use with some variables overrided basically
        eval $to_eval;

        # Rest is pretty normal
        $schema =   Workflow::Persister::DBIx::Schema->connect(
                          $self->dsn
                        , $self->user
                        , $self->password
                    );

        # Load dynamic classes
        $schema->load_namespaces(
            result_namespace => '+Workflow::Persister::DBIx::Schema'
        );

        # Quote names so keywords can be used
        $schema->storage->sql_maker->quote_char('`');
        $schema->storage->sql_maker->name_sep('.');

        $self->_assign_mapping($schema);

    } or persist_error "Failed to connect to db ", $@;

    $self->schema($schema);

    $log->is_debug && $log->debug(
        "Connected successfully to '"
        , $self->dsn
        , "'"
    );
}

sub _assign_customization {
    my ( $self, $params ) = @_;

    for ( @CUSTOM_FIELDS ) {
        $self->$_( $params->{$_} ) if ( defined $params->{$_} );
    }
}

sub _assign_mapping {
    my ( $self, $schema ) = @_;

    use Workflow::Persister::DBIx::Schema;

    my $time_zone            = $Workflow::Persister::DBIx::Schema::time_zone                  ;

    my $wf_table             = $Workflow::Persister::DBIx::Schema::workflow_table             ;
    my $wf_field_id          = $Workflow::Persister::DBIx::Schema::workflow_field_id          ;
    my $wf_field_type        = $Workflow::Persister::DBIx::Schema::workflow_field_type        ;
    my $wf_field_state       = $Workflow::Persister::DBIx::Schema::workflow_field_state       ;
    my $wf_field_last_update = $Workflow::Persister::DBIx::Schema::workflow_field_last_update ;
    my $wf_field_context     = $Workflow::Persister::DBIx::Schema::workflow_field_context     ;

    my $h_table              = $Workflow::Persister::DBIx::Schema::history_table             ;
    my $h_field_id           = $Workflow::Persister::DBIx::Schema::history_field_id          ;
    my $h_field_workflow_id  = $Workflow::Persister::DBIx::Schema::history_field_workflow_id ;
    my $h_field_action       = $Workflow::Persister::DBIx::Schema::history_field_action      ;
    my $h_field_description  = $Workflow::Persister::DBIx::Schema::history_field_description ;
    my $h_field_state        = $Workflow::Persister::DBIx::Schema::history_field_state       ;
    my $h_field_user         = $Workflow::Persister::DBIx::Schema::history_field_user        ;
    my $h_field_date         = $Workflow::Persister::DBIx::Schema::history_field_date        ;

    $self->time_zone                 ( $time_zone            ) unless $self->time_zone;

    $self->workflow_table            ( $wf_table             ) unless $self->workflow_table;
    $self->workflow_field_id         ( $wf_field_id          ) unless $self->workflow_field_id;
    $self->workflow_field_type       ( $wf_field_type        ) unless $self->workflow_field_type;
    $self->workflow_field_state      ( $wf_field_state       ) unless $self->workflow_field_state;
    $self->workflow_field_last_update( $wf_field_last_update ) unless $self->workflow_field_last_update;
    $self->workflow_field_context    ( $wf_field_context     ) unless $self->workflow_field_context;

    $self->history_table             ( $h_table              ) unless $self->history_table;
    $self->history_field_id          ( $h_field_id           ) unless $self->history_field_id;
    $self->history_field_workflow_id ( $h_field_workflow_id  ) unless $self->history_field_workflow_id;
    $self->history_field_action      ( $h_field_action       ) unless $self->history_field_action;
    $self->history_field_description ( $h_field_description  ) unless $self->history_field_description;
    $self->history_field_state       ( $h_field_state        ) unless $self->history_field_state;
    $self->history_field_user        ( $h_field_user         ) unless $self->history_field_user;
    $self->history_field_date        ( $h_field_date         ) unless $self->history_field_date;
}

sub _stringify_customization {
    my ( $self ) = @_;

    my $str = '';

    for( @CUSTOM_FIELDS ) {
        $str .= "$_ => '" . $self->$_ . "'," if $self->$_; 
    }

    chop($str);

    return $str;
}

sub create_workflow {
    my ( $self, $wf ) = @_;

    my $log    = get_logger();
    my $schema = $self->schema;

    my $values = $self->_values_for_workflow($wf);

    my $persisted_wf;

    eval {
        $persisted_wf = $schema->resultset('Workflow')->create($values);
    } or persist_error "Failed to create workflow: $@";

    my $field_id = $self->workflow_field_id;

    return $persisted_wf->$field_id;
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;

    my $log    = get_logger();
    my $schema = $self->schema;

    my $persisted_wf;

    eval {
        $persisted_wf = $schema->resultset('Workflow')->find({ $self->workflow_field_id => $wf_id });
    } or persist_error "Cannot fetch worfklow $@";

    return undef unless ($persisted_wf);

    return $self->_recover_workflow($persisted_wf);
}

sub update_workflow {
    my ( $self, $wf ) = @_;

    my $log    = get_logger();
    my $schema = $self->schema;

    my $values = $self->_values_for_workflow($wf);

    my $persisted_wf;

    eval {
        $persisted_wf = $schema->resultset('Workflow')
                        ->find({ $self->workflow_field_id => $wf->id })
                        ->update($values);

    } or persist_error "Cannot update worfklow: $@";
}

sub create_history {
    my ( $self, $wf, @history ) = @_;

    my $log    = get_logger();
    my $schema = $self->schema;


    foreach my $h (@history) {
        next if ( $h->is_saved );

        my $values = $self->_values_for_history($wf, $h);

        my $persisted_h;

        eval {
            $persisted_h = $schema->resultset('WorkflowHistory')->create($values);
        } or persist_error "Could not create history: $@";

        my $field_id = $self->history_field_id;

        $h->id($persisted_h->$field_id);
        $h->set_saved();
    }

    return @history;
}

sub fetch_history {
    my ( $self, $wf ) = @_;

    my $log    = get_logger();
    my $schema = $self->schema;

    my @persisted_history;

    eval {
        @persisted_history = $schema->resultset('Workflow')->find({ $self->workflow_field_id => $wf->id })->history->all;
    } or persist_error "Could not fetch history: $@";

    my @history = ();
    foreach(@persisted_history) {
        my $h = $self->_recover_history($_);

        push @history, $h;
    }

    return @history;
}

sub _values_for_workflow {
    my ( $self, $wf ) = @_;

    return {
          $self->workflow_field_type        => $wf->type
        , $self->workflow_field_state       => $wf->state
        , $self->workflow_field_last_update => DateTime->now( time_zone => $wf->time_zone )
        , $self->workflow_field_context     => $wf->context
    };
}

sub _recover_workflow {
    my ( $self, $row ) = @_;

    my $object;

    my $field_id          = $self->workflow_field_id;
    my $field_state       = $self->workflow_field_state;
    my $field_context     = $self->workflow_field_context;
    my $field_last_update = $self->workflow_field_last_update;

    eval {
        $object = {
              id          => $row->$field_id
            , state       => $row->$field_state
            , context     => $row->$field_context
            , last_update => $row->$field_last_update
        }
    } or persist_error "Could not constitute workflow object: $@";

    return $object;
}

sub _values_for_history {
    my ( $self, $wf, $history ) = @_;

    return {
          $self->history_field_workflow_id   => $wf->id
        , $self->history_field_action        => $history->action
        , $self->history_field_description   => $history->description
        , $self->history_field_state         => $history->state
        , $self->history_field_user          => $history->user
    };
}

sub _recover_history {
    my ( $self, $row ) = @_;

    my $object;

    my $field_id            = $self->history_field_id           ;
    my $field_workflow_id   = $self->history_field_workflow_id  ;
    my $field_action        = $self->history_field_action       ;
    my $field_description   = $self->history_field_description  ;
    my $field_state         = $self->history_field_state        ;
    my $field_user          = $self->history_field_user         ;

    eval {
        $object = Workflow::History->new({
                      id            => $row->$field_id
                    , workflow_id   => $row->$field_workflow_id
                    , action        => $row->$field_action
                    , description   => $row->$field_description
                    , state         => $row->$field_state
                    , user          => $row->$field_user
                });

    } or persist_error "Could not constitute workflow object: $@";

    return $object;
}


1;
