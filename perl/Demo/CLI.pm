package Demo::CLI;

use strict;
use warnings;

use parent 'Demo::LineServer';

use Class::StateMachine::Declarative
    __any__ => { advance => 'on_done',
		 transitions => { on_closed => 'stopped' } },

    new     => { transitions => { on_run => 'auth' } },

    auth    => { transitions => { on_error => 'login' },
		 substates => [ login => { enter => 'ask_login' },
				pwd   => { enter => 'ask_pwd',
					   before => { on_done => 'check_pwd' } } ] },

    repl    => { transitions => { on_error => 'ask' },
		 substates => [ ask => { enter => 'ask_cmd' },
				run => { enter => 'run_cmd',
					 transitions => { on_done => 'ask',
							  on_exit => 'stopped' } } ] },

    stopped => { enter => 'tell_parent' };

sub ask_login {
    my $self = shift;
    print {$self->{conn}} "User: ";
    $self->_readline(save_as => 'login');
}

sub ask_pwd {
    my $self = shift;
    print {$self->{conn}} "Password: ";
    $self->_readline(save_as => 'pwd');
}

sub check_pwd {
    my $self = shift;
    unless ($self->{login} eq "demo\r\n" and
	    $self->{pwd} eq "pwd\r\n") {
	print {$self->{conn}} "bad user or password\n";
	return $self->on_error;
    }
}

sub ask_cmd {
    my $self = shift;
    print {$self->{conn}} "Cmd: ";
    $self->_readline(save_as => 'cmd');
}

sub run_cmd {
    my $self = shift;
    my $cmd = $self->{cmd};
    $cmd =~ s/\r?\n//;
    if ($cmd =~ /^(?:quit|exit)$/) {
	return $self->on_exit;
    }
    $self->_run_cmd($cmd);
}

sub tell_parent {
    my $self = shift;
    my $cb = $self->{tell_parent_cb};
    $cb->($self) if $cb;
}

sub new {
    my ($class, $conn, $cb) = @_;
    my $self = $class->SUPER::new($conn);
    $self->{tell_parent_cb} = $cb;
    $self;
}

1;
