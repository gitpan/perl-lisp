package Gnus::Newsrc_eld;

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use Lisp::Reader qw(lisp_read);
use Lisp::Symbol qw(symbol symbolp);


sub new
{
    my($class, $file) = @_;
    $file = "$ENV{HOME}/.newsrc.eld" unless defined $file;
    local($/) = undef;  #slurp;
    open(LISP, $file) || die "Can't open $file: $!";
    my $lisp = <LISP>;
    close(LISP);
    my $form = lisp_read($lisp);

    my $self = bless {}, $class;

    my $setq  = symbol("setq");
    my $quote = symbol("quote");

    for (@$form) {
	my($one,$two,$three) = @$_;
	#print join(" - ", map {$_->name} $one, $two), "\n";
	if ($one == $setq && symbolp($two)) {
	    if (ref($three) eq "ARRAY") {
		my $first = $three->[0];
		if (symbolp($first) && $first == $quote) {
		    $three = $three->[1];
		}
	    }
	    $self->{$two->name} = $three;
	} else {
	    warn "$_ does not start with (setq symbo ...)\n";
	}
    }

    my $nil = symbol("nil");
    # make the 'gnus-newsrc-alist' into a more perl suitable structure
    for (@{$self->{'gnus-newsrc-alist'}}) {
	my($group, $level, $read, $marks, $server, $para) = @$_;

	for ($read, $marks, $para) {
	    $_ = [] if !defined($_) || $_ == $nil;
	}
	$_->[2] = join(",", map {ref($_)?"$_->[0]-$_->[1]":$_} @$read);
	$_->[3] = @$marks ?
                     { map {shift(@$_)->name =>
		            join(",", map {ref($_)?"$_->[0]-$_->[1]":$_}@$_)}
                      @$marks
                     }
                  : undef;
        $_->[4] = undef if defined($server) && $server == $nil;
	$_->[5] = @$para ? { map { $_->[0]->name, $_->[1] } @$para } : undef;

	# trim trailing undef values
	pop(@$_) until defined($_->[-1]) || @$_ == 0;
    }

    $self;
}

sub file_version
{
    shift->{"gnus-newsrc-file-version"};
}

sub last_checked_date
{
    shift->{"gnus-newsrc-last-checked-date"};
}

sub alist
{
    shift->{"gnus-newsrc-alist"};
}

sub server_alist
{
    shift->{"gnus-server-alist"};

}

sub killed_list
{
    shift->{"gnus-killed-list"};
}

sub zombie_list
{
    shift->{"gnus-zombie-list"};
}

sub format_specs
{
    shift->{"gnus-format-specs"};
}

1;