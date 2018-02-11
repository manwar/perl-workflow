package Workflow::Persister::DBIx::Schema::Workflow;

use strict;
use warnings;
use base 'DBIx::Class::Core';
use Data::Dumper;


# Default values passed through import on Workflow::Persister::DBIx::Schema
my $TIME_ZONE          = $Workflow::Persister::DBIx::Schema::time_zone                    ;

my $TABLE              = $Workflow::Persister::DBIx::Schema::workflow_table               ;
my $FIELD_ID           = $Workflow::Persister::DBIx::Schema::workflow_field_id            ;
my $FIELD_TYPE         = $Workflow::Persister::DBIx::Schema::workflow_field_type          ;
my $FIELD_STATE        = $Workflow::Persister::DBIx::Schema::workflow_field_state         ;
my $FIELD_LAST_UPDATE  = $Workflow::Persister::DBIx::Schema::workflow_field_last_update   ;
my $FIELD_CONTEXT      = $Workflow::Persister::DBIx::Schema::workflow_field_context       ;

my $FK                 = $Workflow::Persister::DBIx::Schema::history_field_workflow_id    ;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/)   ;

__PACKAGE__->table($TABLE);

__PACKAGE__->add_columns($FIELD_ID, $FIELD_TYPE, $FIELD_STATE, $FIELD_CONTEXT);

__PACKAGE__->add_columns(
    $FIELD_LAST_UPDATE => { data_type => 'timestamp', timezone => $TIME_ZONE }
);

__PACKAGE__->set_primary_key($FIELD_ID);

__PACKAGE__->has_many( history => 'Workflow::Persister::DBIx::Schema::WorkflowHistory', $FK );

__PACKAGE__->inflate_column($FIELD_CONTEXT, {
    inflate => \&thaw_context,
    deflate => \&freeze_context
});

sub freeze_context {
    my $context = shift;

    local $Data::Dumper::Terse = 1;

    return Dumper($context);
}

sub thaw_context {
    my $frozen_context = shift;

    return eval $frozen_context;
}


1;
