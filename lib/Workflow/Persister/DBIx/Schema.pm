package Workflow::Persister::DBIx::Schema;

use strict;
use warnings;
use base 'DBIx::Class::Schema';


# Shared variables
our $time_zone                   = 'local'            ; # Default time zone for inflates/deflates

our $workflow_table              = 'workflow'         ; # Default workflow table name
our $workflow_field_id           = 'id'               ; # Default worfklow id name
our $workflow_field_type         = 'type'             ; # Default workflow type name
our $workflow_field_state        = 'state'            ; # Default workflow state name
our $workflow_field_last_update  = 'last_update'      ; # Default workflow last update
our $workflow_field_context      = 'context'          ; # Default workflow context

our $history_table               = 'workflow_history' ; # Default history table name
our $history_field_id            = 'id'               ; # Default history id name
our $history_field_workflow_id   = 'workflow_id'      ; # Default history workflow id name
our $history_field_action        = 'action'           ; # Default history action name
our $history_field_description   = 'description'      ; # Default history description name
our $history_field_state         = 'state'            ; # Default history state name
our $history_field_user          = 'user'             ; # Default history user name
our $history_field_date          = 'date'             ; # Default history date

sub import {
    my ( $self, %args ) = @_;

    for (
        qw(
            time_zone workflow_table workflow_field_id
            workflow_field_type workflow_field_state
            workflow_field_last_update workflow_field_context
            history_table history_field_id history_field_workflow_id
            history_field_action history_field_description
            history_field_state history_field_user history_field_date
        )
    ) {
        $$_ = $args{$_} if defined $args{$_} && $args{$_};
    }
}


1;
