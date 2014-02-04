package Test::Cucumber::Tiny;
{
  $Test::Cucumber::Tiny::VERSION = '0.1';
}
use Mouse;
require Test::Most;

=head1 NAME

Test::Cucumber::Tiny - Cucumber-style testing in perl

=head1 DESCRIPTION

This Testing module provides a simple and less dependancy
to run cucumber tests.

Cucumber is a tool that executes plain-text functional
descriptions as automated tests. The language that Cucumber
understands is called Gherkin.

We only need 2 things to build Cucumber test, a list a scenarios
and to define the functions for the scenarios. Example in synopsis.

While Cucumber can be thought of as a "testing" tool, 
the intent of the tool is to support BDD. This means that
the "tests" are typically written before anything else and
verified by business analysts, domain experts, etc. non technical
stakeholders. The production code is then written outside-in,
to make the stories pass.

=head1 SYNOPSIS

Here is an example:

 use Test::Most tests => 1;
 use Test::Cucumber::Tiny;

 subtest "Feature Test - Calculator" => sub {
    ## In order to avoid silly mistake
    ## As a math idiot
    ## I want to be told a sum of 2 numbers

    ## If we need to shared the scenario with business analysts.
    ## Use YAML format to write the scenarios.

    my $cucumber = Test::Cucumber::Tiny->new(
        scenarios => [
            {
                Scenario => "Add 2 numbers",
                Given    => [
                    "first, I entered 50 into the calculator",
                    "second, I entered 70 into the calculator",
                ],
                When => [ "I press add", ],
                Then => [ "The result should be 120 on the screen", ]
            },
            {
                Scenario => "Add numbers in examples",
                Given    => [
                    "first, I entered <1st> into the calculator",
                    "second, I entered <2nd> into the calculator",
                ],
                When     => [ "I press add", ],
                Then     => [ "The result should be <answer> on the screen", ],
                Examples => [
                    {
                        '1st'  => 5,
                        '2nd'  => 6,
                        answer => 11,
                    },
                    {
                        '1st'  => 100,
                        '2nd'  => 200,
                        answer => 300,
                    }
                ],
            },
            {
                Scenario => "Add numbers using data",
                Given    => [
                    {
                        condition => "first, I entered number of",
                        data      => 45,
                    },
                    {
                        condition => "second, I entered number of",
                        data      => 77,
                    }
                ],
                When => [ "I press add", ],
                Then => [
                    {
                        condition => "The result is",
                        data      => 122,
                    }
                ],
            }
        ]
    );
    $cucumber->Given(
        qr/^(.+),.+entered (\d+)/,
        sub {
            my $c = shift;
            diag shift;
            $c->{$1} = $2;
        }
    );
    $cucumber->Given(
        qr/^(.+),.+entered number of/,
        sub {
            my $c = shift;
            diag shift;
            $c->{$1} = $c->{data},;
        }
    );
    $cucumber->When(
        qr/press add/,
        sub {
            my $c = shift;
            diag shift;
            $c->{answer} = $c->{first} + $c->{second};
        }
    );
    $cucumber->When(
        qr/press subtract/,
        sub {
            my $c = shift;
            diag shift;
            $c->{answer} = $c->{first} - $c->{second};
        }
    );
    $cucumber->Then(
        qr/result.+should be (\d+)/,
        sub {
            my $c = shift;
            is $1, $c->{answer}, shift;
        }
    );
    $cucumber->Then(
        qr/result is/,
        sub {
            my $c = shift;
            is $c->{data}, $c->{answer}, shift;
        }
    );
    $cucumber->Test;
 };

=cut

has scenarios => (
    required => 1,
    is       => "ro",
    isa      => "ArrayRef[HashRef]",
);

=head1 METHODS

=head2 Given

@param regexp / hashref { regexp, data }
@param code ref

=cut

sub Given {
    my $self      = shift;
    my $condition = shift
      or die "Missing 'Given' condition";
    my $definition = shift
      or die "Missing 'Given' definition coderef";
    push @{ $self->_givens },
      {
        condition  => $condition,
        definition => $definition,
      };
}

has _givens => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 When

@param regexp / hashref { regexp, data }
@param code ref

=cut

sub When {
    my $self      = shift;
    my $condition = shift
      or die "Missing 'When' condition";
    my $definition = shift
      or die "Missing 'When' definition coderef";
    push @{ $self->_whens },
      {
        condition  => $condition,
        definition => $definition,
      };
}

has _whens => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 Then

@param regexp / hashref { regexp, data }
@param code ref

=cut

sub Then {
    my $self      = shift;
    my $condition = shift
      or die "Missing 'Then' condition";
    my $definition = shift
      or die "Missing 'Then' definition coderef";
    push @{ $self->_thens },
      {
        condition  => $condition,
        definition => $definition,
      };
}

has _thens => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 Test

Start Cucumber to run through the scenario.

=cut

sub Test {
    my $self  = shift;
    my @steps = qw(given when and then);
    foreach my $scenario ( @{ $self->scenarios } ) {
        my %stash = ();
        my @examples = @{ $scenario->{Examples} || [ {} ] };
        my $subject  = $scenario->{Scenario}
            or die "Missing the name of Scenario";

        Test::Most::diag("Scenario: $subject\n");

        foreach my $eg (@examples) {
            _run_test(
                given => $scenario->{Given},
                $eg, $self->_givens, \%stash
            );
            _run_test(
                when => $scenario->{When},
                $eg, $self->_whens, \%stash
            );
            _run_test(
                then => $scenario->{Then},
                $eg, $self->_thens, \%stash
            );
        }
    }
}

sub _run_test {
    my $step          = shift;
    my $preconditions = shift
      or die "Missing '$step' in scenario";
    my $example_ref = shift;
    my $items_ref   = shift;
    my $stash_ref   = shift;
    foreach my $item (@$items_ref) {
        my $condition = $item->{condition};
        my @preconditions =
          ref $preconditions eq "ARRAY"
          ? @$preconditions
          : ($preconditions);

        foreach my $precondition (@preconditions) {
            if ($example_ref) {
                foreach my $key ( keys %$example_ref ) {
                    $precondition =~ s/<$key>/$example_ref->{$key}/g;
                }
            }
            if ( ref $precondition ) {
                $stash_ref->{data} = $precondition->{data};
                $precondition = $precondition->{condition};
            }
            if ( $precondition =~ /$condition/ ) {
                $item->{definition}->( $stash_ref, "$step $precondition" );
            }
        }
    }
}

=head1 SEE ALSO

L<http://cukes.info/>

L<https://github.com/cucumber/cucumber/wiki/Scenario-outlines>

=cut

no Mouse;

1;
