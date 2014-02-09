requires "Mo";
requires "Carp";
requires "Readonly";
requires "Test::More";
requires "Try::Tiny";
on test => sub {
    requires "Digest";
};
