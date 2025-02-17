package Workflow::Condition::Evaluate;

use warnings;
use strict;
use base qw( Workflow::Condition );
use Log::Log4perl qw( get_logger );
use Safe;
use Workflow::Exception qw( condition_error configuration_error );
use English qw( -no_match_vars );

$Workflow::Condition::Evaluate::VERSION = '1.48';

my @FIELDS = qw( test );
__PACKAGE__->mk_accessors(@FIELDS);

# These get put into the safe compartment...
$Workflow::Condition::Evaluate::context = undef;

my ($log);

sub _init {
    my ( $self, $params ) = @_;
    $log ||= get_logger();

    $self->test( $params->{test} );
    unless ( $self->test ) {
        configuration_error
            "The evaluate condition must be configured with 'test'";
    }
    $log->is_info
        && $log->info("Added evaluation condition with '$params->{test}'");
}

sub evaluate {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();

    my $to_eval = $self->test;
    $log->is_info
        && $log->info("Evaluating '$to_eval' to see if it returns true...");

    # Assign our local stuff to package variables...
    $Workflow::Condition::Evaluate::context = $wf->context->param;

    # Create the Safe compartment and safely eval the test...
    my $safe = Safe->new();

    ## no critic (RequireInterpolationOfMetachars)
    $safe->share('$context');
    my $rv = $safe->reval($to_eval);
    if ($EVAL_ERROR) {
        $log->error("Eval code '$to_eval' threw exception: $EVAL_ERROR");
        condition_error
            "Condition expressed in code threw exception: $EVAL_ERROR";
    }

    $log->is_debug
        && $log->debug( "Safe eval ran ok, returned: '"
            . ( defined $rv ? $rv : '<undef>' )
            . "'" );
    unless ($rv) {
        condition_error "Condition expressed by test '$to_eval' did not ",
            "return a true value.";
    }
    return $rv;
}

1;

__END__

=head1 NAME

Workflow::Condition::Evaluate - Inline condition that evaluates perl code for truth

=head1 VERSION

This documentation describes version 1.02 of this package

=head1 SYNOPSIS

 <state name="foo">
     <action name="foo action">
         <condition test="$context->{foo} =~ /^Pita chips$/" />

=head1 DESCRIPTION

If you've got a simple test you can use Perl code inline instead of
specifying a condition class. We differentiate by the 'test' attribute
-- if it's present we assume it's Perl code to be evaluated.

While it's easy to abuse something like this with:

 <condition>
   <test><![CDATA[
     if ( $context->{foo} =~ /^Pita (chips|snacks|bread)$/" ) {
          return $context->{bar} eq 'hummus';
     }
     else { ... }
     ]]>
   </test>
 </condition>

It should provide a good balance.

=head1 OBJECT METHODS

=head3 new( \%params )

One of the C<\%params> should be 'test', which contains the text to
evaluate for truth.

=head3 evaluate( $wf )

Evaluate the text passed into the constructor: if the evaluation
returns a true value then the condition passes; if it throws an
exception or returns a false value, the condition fails.

We use L<Safe> to provide a restricted compartment in which we
evaluate the text. This should prevent any sneaky bastards from doing
something like:

 <state...>
     <action...>
         <condition test="system( 'rm -rf /' )" />

The text has access to one variable, for the moment:

=over 4

=item B<$context>

A hashref of all the parameters in the L<Workflow::Context> object

=back

=head1 SEE ALSO

L<Safe> - From some quick research this module seems to have been
packaged with core Perl 5.004+, and that's sufficiently ancient
for me to not worry about people having it. If this is a problem for
you shoot me an email.

=head1 COPYRIGHT

Copyright (c) 2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
