package Test::Cucumber::Tiny;
{
  $Test::Cucumber::Tiny::VERSION = '0.4';
}
use Mo qw( default );
use Try::Tiny;
use Carp qw( confess );
use Readonly;
require Test::More;

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

If you need to shared the scenarios with the business analysts.

Use yml format to write the scenarios and then using YAML module
to decode it into arrayref for constructing a cucumber.

Here is an example using arrayref:

 use Test::More tests => 1;
 use Test::Cucumber::Tiny;

 subtest "Feature Test - Calculator" => sub {
    ## In order to avoid silly mistake
    ## As a math idiot
    ## I want to be told a sum of 2 numbers

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
            $c->{$1} = $c->{data};
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

=head2 Scenarios

A short hand method to do follow

 my $cuc = Test::Cucumber::Tiny->new( scenarios => [
    {
        ....
    }
 ] );

Same as

 my $cuc = Test::Cucumber::Tiny->Scenarios(
    {
        ....
    }
 );

That could also save one level of indents.

=cut

sub Scenarios {
    my $class = shift;
    die "This is a constructor not a object method"
      if ref $class;
    return $class->new( scenarios => \@_ );
}

=head2 Before

@param regexp

@code ref

=cut

sub Before {
    my $self      = shift;
    my $condition = shift
      or die "Missing regexp or coderef";
    my $definition = shift;

    if ( ref $condition eq "CODE" ) {
        $definition = $condition;
        $condition  = qr/.+/;
    }

    push @{ $self->_befores },
      {
        condition  => $condition,
        definition => $definition,
      };
}

has _befores => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 Given

@param regexp

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

=head2 Any

Use any to set all 3 like below

 $cuc->Any( qr/.+/ => sub { return 1 } );

Same as

 $cuc->Given( qr/.+/ => sub { return 1 } );
 $cuc->When( qr/.+/ => sub { return 1 } );
 $cuc->Then( qr/.+/ => sub { return 1 } );

=cut

sub Any {
    my $self = shift;
    $self->Before(@_);
    $self->Given(@_);
    $self->When(@_);
    $self->Then(@_);
    $self->After(@_);
}

=head2 After

@param regexp

@code ref

=cut

sub After {
    my $self      = shift;
    my $condition = shift
      or die "Missing regexp or coderef";
    my $definition = shift;

    if ( ref $condition eq "CODE" ) {
        $definition = $condition;
        $condition  = qr/.+/;
    }

    push @{ $self->_afters },
      {
        condition  => $condition,
        definition => $definition,
      };
}

has _afters => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 NextStep

When you are the functions of Given

Call NextStep will jump to When

When you are the functions of When

Call NextStep will jump to Then

When you are the functions of Then

Call NextStep will finish the current scenario.

=cut

Readonly my $NEXT_STEP => "Next Step";

sub NextStep {
    die { intercept => $NEXT_STEP };
}

=head2 NextExample

When you are the functions of Given, When or Then

Call NextExample will finish the current cycle and 
use the next example data in the current scenario.

=cut

Readonly my $NEXT_EXAMPLE => "Nex Example";

sub NextExample {
    die { intercept => $NEXT_EXAMPLE };
}

=hea2 NextScenario

Just jump to the next scenario.

=cut

Readonly my $NEXT_SCENARIO => "Next Scenario";

sub NextScenario {
    die { intercept => $NEXT_SCENARIO };
}

=head2 Test

Start Cucumber to run through the scenario.

=cut

Readonly my @STEPS => qw(
  Before
  Given
  When
  Then
  After
);

sub Test {
    my $self = shift;
    my @run_through = ( "Before", @STEPS, "After" );

    $self->Any(
        qr/^debugger$/ => sub {
            my $c            = shift;
            my $subject      = shift;
            my $Scenario     = $c->{Scenario};
            my $Step         = $c->{Step};
            my $Data         = $c->{data};
            my $Example      = $c->{Example};
            my $FEATURE_WIDE = $c->{FEATURE_WIDE};
            $self->_verbose("! DEBUG: $Scenario - $Step");
            print q{};
        }
    );

  SCENARIO:
    foreach my $scenario ( @{ $self->scenarios } ) {

        _check_scenario_setps($scenario);

        my @examples = @{ $scenario->{Examples} || [ {} ] };
        my $subject = $scenario->{Scenario}
          or die "Missing the name of Scenario";

        my %stash = ();
        Readonly $stash{FEATURE_WIDE} => $self->FEATURE_WIDE_VAR;
        Readonly $stash{Scenario} => $subject;

      EXAMPLE:
        foreach my $example (@examples) {
            $stash{Example} = $example;
            my $subject = _apply_example( $subject => %$example );

            $self->_verbose("\n--> Scenario: $subject\n");

            my %triggers = ();

            $triggers{Before} = sub {
                $self->_trigger_before_running_step(
                    Before => ( $subject, $scenario ) );
            };

            $triggers{After} = sub {
                $self->_trigger_before_running_step(
                    After => ( $subject, $scenario ) );
            };

          STEP:
            foreach my $step( @run_through ) {
                $stash{Step} = $step;
                my $intercept =
                  $self->_run_step( $step, $scenario, $example, \%stash,
                    $triggers{$step} )
                  or next STEP;
                next STEP     if $intercept eq $NEXT_STEP;
                next EXAMPLE  if $intercept eq $NEXT_EXAMPLE;
                next SCENARIO if $intercept eq $NEXT_SCENARIO;
            }
        }
    }
}

sub _trigger_before_running_step {
    my $self       = shift;
    my $big_name   = shift;
    my $subject    = shift;
    my $scenario   = shift;
    my $small_name = lcfirst $big_name;
    my $array_name = "_$small_name" . 's';
    if ( !@{ $self->$array_name } ) {
        $self->NextStep;
    }
    if ( !$scenario->{$big_name} ) {
        $scenario->{$big_name} = $subject;
    }
}

sub _run_step {
    my $self        = shift;
    my $step        = shift;
    my $scenario    = shift;
    my $example     = shift;
    my $stash_ref   = shift;
    my $before_step = shift || sub { };
    try {
        my $small_step = lc $step;
        my $big_step   = ucfirst $step;
        my $array_name = "_$small_step" . 's';
        $before_step->();
        _run_test(
            $big_step => $scenario->{$big_step},
            $example, $self->$array_name, $stash_ref
        );
    }
    catch {
        my $int = _intercept();
        return $int
          ? $int
          : confess($_);
    };
}

has FEATURE_WIDE_VAR => (
    is      => "ro",
    isa     => "HashRef",
    default => sub { {} },
);

sub _run_test {
    my $step          = shift;
    my $preconditions = shift
      or die "Missing '$step' in scenario";
    my $example_ref = shift;
    my $items_ref   = shift;
    my $stash_ref   = shift;

    my @preconditions =
      ref $preconditions eq "ARRAY"
      ? @$preconditions
      : ($preconditions);

    foreach my $precondition (@preconditions) {

        return if !$precondition;
        return if ref $precondition && !%$precondition;

        foreach my $item (@$items_ref) {
            my $condition = $item->{condition};
            $precondition = _apply_example( $precondition => %$example_ref );
            if ( ref $precondition ) {
                my %checks = _check_hash_has_the_only_keys(
                    [qw(condition data)] => %$precondition
                );
                if ( $checks{missing} ) {
                    die sprintf "\nFIXME: missing setting of %s $step\n\n",
                      join( ", ", map { qq{"$_"} } @{ $checks{missing} } );
                }
                $stash_ref->{data}            = $precondition->{data};
                $stash_ref->{"_${step}_data"} = $precondition->{data};
                $precondition                 = $precondition->{condition};
            }
            if ( $precondition =~ /$condition/ ) {
                $item->{definition}->( $stash_ref, "$step $precondition" );
            }
        }
    }
}

sub _apply_example {
    my $pre_cond = shift;
    my %example = @_
      or return $pre_cond;
    foreach my $key ( keys %example ) {
        if ( ref $pre_cond ) {
            $pre_cond->{condition} =~s/<\Q$key\E>/$example{$key}/g;
        }
        else {
            $pre_cond =~ s/<\Q$key\E>/$example{$key}/g;
        }
    }
    return $pre_cond;
}

sub _intercept {
    my $error = $_
      or return q{};
    return q{} if !ref $error;
    return q{} if ref $error ne "HASH";
    my $intercept = $error->{intercept}
      or return q{};
    return $intercept;
}

Readonly my @HEADS = qw(
  Scenario
  Examples
);

sub _check_scenario_setps {
    my $scenario      = shift;
    my %scenario_hash = ();
    if ( ref $scenario eq "ARRAY" ) {
        %scenario_hash = @$scenario;
    }
    if ( ref $scenario eq "HASH" ) {
        %scenario_hash = %$scenario;
    }

    my %known = map { $_ => 1 } ( @HEADS, @STEPS );

    my %result = _check_hash_has_the_only_keys(
        [@HEADS, @STEPS],
        %scenario_hash
    ) or return;

    return if !@{ $result{invalid} };

    my $subject =
      $scenario_hash{Scenario} ? " at '$scenario_hash{Scenario}'" : q{};

    die sprintf "\nFIXME: unrecognized steps %s$subject\n\n",
      join( ", ", map { qq{"$_"} } @{ $result{invalid} } );
}

sub _check_hash_has_the_only_keys {
    my $keys_ref = shift;
    my %hash     = @_;

    my %needed = map { $_ => 1 } @$keys_ref;
    my @invalid = grep { !$needed{$_} } keys %hash;
    my @missing = grep { !exists $hash{$_} } keys %needed;

    return if !@invalid && !@missing;

    return (
        invalid => \@invalid,
        missing => \@missing,
    );
}

## method name in Test::More
## e.g. diag, explain, note, etc...
has verbose => (
    is      => "ro",
    isa     => "Str",
    default => "explain",
);

sub _verbose {
    my $self = shift;
    my $message = shift
        or return;
    my $mode = $ENV{CUCUMBER_VERBOSE} || $self->verbose
        or return;
    my $code = Test::More->can($mode)
        or confess("FIXME: Invalid verbose mode $mode");
    $code->($message);
}

=head1 SEE ALSO

L<http://cukes.info/>

L<https://github.com/cucumber/cucumber/wiki/Scenario-outlines>

=cut

no Mo;
no Carp;
no Try::Tiny;

1;
