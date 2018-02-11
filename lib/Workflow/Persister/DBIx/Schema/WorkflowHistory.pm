package Workflow::Persister::DBIx::Schema::WorkflowHistory;

use strict;
use warnings;
use base 'DBIx::Class::Core';

# Default values passed through import on Workflow::Persister::DBIx::Schema
my $TIME_ZONE          = $Workflow::Persister::DBIx::Schema::time_zone                 ;

my $TABLE              = $Workflow::Persister::DBIx::Schema::history_table             ;
my $FIELD_ID           = $Workflow::Persister::DBIx::Schema::history_field_id          ;
my $FIELD_WORKFLOW_ID  = $Workflow::Persister::DBIx::Schema::history_field_workflow_id ;
my $FIELD_ACTION       = $Workflow::Persister::DBIx::Schema::history_field_action      ;
my $FIELD_DESCRIPTION  = $Workflow::Persister::DBIx::Schema::history_field_description ;
my $FIELD_STATE        = $Workflow::Persister::DBIx::Schema::history_field_state       ;
my $FIELD_USER         = $Workflow::Persister::DBIx::Schema::history_field_user        ;
my $FIELD_DATE         = $Workflow::Persister::DBIx::Schema::history_field_date        ;


__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

__PACKAGE__->table($TABLE);

__PACKAGE__->add_columns(
      $FIELD_ID
    , $FIELD_WORKFLOW_ID
    , $FIELD_ACTION
    , $FIELD_DESCRIPTION
    , $FIELD_STATE
    , $FIELD_USER
);

__PACKAGE__->add_columns(
    $FIELD_DATE => { data_type => 'timestamp', timezone => $TIME_ZONE }
);

__PACKAGE__->set_primary_key($FIELD_ID);


__PACKAGE__->belongs_to(
    workflow => 'Workflow::Persister::DBIx::Schema::Workflow', $FIELD_WORKFLOW_ID
);


1;
