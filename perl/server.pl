#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use AnyEvent;

use Demo::CLI;

#$Class::StateMachine::debug = -1;
#$Class::StateMachine::Declarative::debug = -1;

my $port = 8888;
my $listener = IO::Socket::INET->new(LocalPort => $port,
				     ReuseAddr => 1,
				     Listen => 10)
    or die "unable to create listener: $!";

my %server;
my $w = AE::io $listener, 0, sub {
    my $conn = $listener->accept;
    $listener->autoflush(1);
    my $server = Demo::CLI->new($conn, sub { delete $server{$_[0]{conn}} });
    $server{$conn} = $server;
    $server->run;
};

AnyEvent->condvar->recv;
