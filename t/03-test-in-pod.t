use strict;
use warnings;
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
                Scenario => "Add numbers in examples <1st> + <2nd>",
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
