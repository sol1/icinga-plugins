#!/usr/bin/perl -l

use strict;
use XML::LibXML;

my $UNKNOWN  = 3;
my $CRITICAL = 2;
my $WARNING  = 1;
my $OK       = 0;

# Initialise return value as unknown by default
my $ret = $UNKNOWN;
my $errmsg = "Unexpected error";

my $CRITSIZ  = 5000;
my $WARNSIZ  = 1000;
my $HOST = $ARGV[1];

sub usage {
	print "usage: check_amqlength host\n";
}

if ( @ARGV < 1 ) {
	usage();
	exit $UNKNOWN
}

# Exit with unknown status if fetching the queue info XML fails
my $x = `wget -qO - http://$HOST:8161/admin/xml/queues.jsp` || exit $UNKNOWN;

my $p = XML::LibXML->new();
my $d = $p->parse_string($x);

my @q = grep {
    $_->[1]
} map {
    [
        $_->getAttribute("name"),
        ($_->getElementsByTagName("stats"))[0]->getAttribute("size"),
    ]
} $d->getElementsByTagName("queue");

my $comment = join ";", map {"$_->[0]: $_->[1]"} sort {$b->[1] <=> $a->[1]} @q;
my $sum = 0;
$sum += $_->[1] foreach @q;

# Check the length of the queue against defined thresholds.
# Exit with return code accordingly with a useful comment contents of the
# queue.
if ($sum >= $CRITSIZ) {
	$ret = $CRITICAL;
	$errmsg = "CRITICAL: message queue length is $sum\n" .
	    "Queue composition: $comment";
} elsif ($sum >= $WARNSIZ) {
	$ret = $WARNING;
	$errmsg = "WARNING: message queue length is $sum\n" .
	    "Queue composition: $comment";
} elsif ($sum < $WARNSIZ) {
	$ret = $OK;
	$errmsg = "message queue length is $sum\n"
} else {
	$errmsg = "Unexpected error determining queue size";
}
	
print $errmsg;
exit $ret;
