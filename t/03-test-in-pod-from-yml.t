use strict;
use warnings;
use Test::More tests => 1;
use Test::Cucumber::Tiny;

subtest "Feature Test - Calculator" => sub {
    ## In order to avoid silly mistake
    ## As a math idiot
    ## I want to be told a sum of 2 numbers

    my $cucumber = eval { Test::Cucumber::Tiny->ScenariosFromYML };

    like $@, qr/Missing YAML file/, "Detect missing file argument";

    $cucumber = eval { Test::Cucumber::Tiny->ScenariosFromYML( "t/example_yml/foobar.yml" ) };

    like $@, qr/YAML file is not found/, "Detect invalid file path";

    $cucumber = eval { Test::Cucumber::Tiny->ScenariosFromYML( "t/example_yml/empty.yml" ) };

    like $@, qr/YAML file has no scenarios/, "Detect missing scenarios in yml file";

    $cucumber = eval { Test::Cucumber::Tiny->ScenariosFromYML( "t/example_yml/hashref.yml") };

    like $@, qr/expecting array/, "Detect invalid data format in the yml file";

    $cucumber = Test::Cucumber::Tiny->ScenariosFromYML( "t/example_yml/test-in-pod.yml" );

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
