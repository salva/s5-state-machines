package Demo::LineServer;

use strict;
use warnings;

use AnyEvent::Util ();

use Method::WeakCallback qw(weak_method_callback);
use parent 'Class::StateMachine';

sub new {
    my ($class, $conn) = @_;

    my $self = { conn => $conn,
		 bin => '' };
    Class::StateMachine::bless($self, $class, 'new');
}

sub run { shift->on_run }

sub _readline {
    my ($self, %opts) = @_;
    $self->{line} = '';
    $self->{readline_watcher} = AE::io($self->{conn}, 0,
				       weak_method_callback($self, '_readline_cb', \%opts));
}

sub _readline_cb {
    my ($self, $opts) = @_;
    my $read = sysread($self->{conn}, my($char), 1);
    if ($read) {
	$self->{line} .= $char;
	if ($char eq "\n") {
	    delete $self->{readline_watcher};
	    if (defined (my $save_as = $opts->{save_as})) {
		$self->{$save_as} = $self->{line};
	    }
	    return $self->on_done;
	}
    }
    else {
	# check for non-fatal errors here!
	$self->on_closed;
    }
}

sub _run_cmd {
    my ($self, $cmd) = @_;
    my $conn = $self->{conn};
    my $pid;
    my $w = AnyEvent::Util::run_cmd($cmd,
				    '<'  => $conn,
				    '>'  => $conn,
				    '2>' => $conn);
    $w->cb(weak_method_callback($self, '_run_cmd_cb'));
    $self->{cmd_watcher} = $w;
}

sub _run_cmd_cb {
    my $self = shift;
    $self->on_done;
}

1;
