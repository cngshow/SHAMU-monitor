#!/u01/dev/perl/64bit/bin/perl
use strict;
use warnings;
use DateTime;
use Getopt::Long;

my $time_zone = 0;
my $offset    = 0;
my $epoch = 0;

sub do_work() {
	$epoch = time unless $epoch;
	my @tz_parts = split (/\|/,$time_zone);
	die "timezone not properly specified!" if ($#tz_parts != 2);
	my $tz = shift @tz_parts;
	my $tz_dst = shift @tz_parts;
	my $tz_not_dst = shift @tz_parts;
	my $offset_dst;
	my $offset_not_dst;
	if ($offset) {
		my @offset_parts = split (/\|/,$offset);
		die "offset not properly specified!" if ($#offset_parts != 1);
		$offset_dst =  shift @offset_parts;
		$offset_not_dst = shift @offset_parts;		
	} 
	my $dt     = DateTime->from_epoch( epoch => $epoch );
	$dt->set_time_zone($tz);
	if ( $dt->is_dst() ) {
		print "$tz_dst" unless $offset;
		print "$offset_dst" if $offset;
	}
	else {
		print "$tz_not_dst" unless $offset;
		print "$offset_not_dst" if $offset;
	}
}

sub gather_user_args() {
	GetOptions(
		"timezone=s" => \$time_zone,
		"offset=s"    => \$offset,
		"epoch=i"    => \$epoch
	);
	usage()
	  unless ( ($time_zone || $offset) || (!$time_zone));
}

sub usage() {
	print <<END;
The required flags are as follows:
timezone -- This REQUIRED flag is a string value representing the expected timezone and the output strings.  
			 run 'perldoc DateTime::TimeZone' for details on the timezone string.
			 An example might be "EST5EDT|CDT|CST".  So if we are in daylight savings time the script will output
			 CDT, otherwise it ouputs CST.
offset     --  This flag is a string value.  It is two digits seperated by a comma.
			   For example if it is "5|6" if it is currently daylight savings the offset will be 5,
			   if not it will be 6. 
			   
epoch	   --  An integer representing Unix time. (also called time since epoch). If not specified the
			   current time is used.		   
			   
It is only valid to define one flag or another.
The above flags may be shortened as long as no ambiguity occurs.

Sample invocation:
timezone.pl -timezone EST5EDT|CDT|CST -epoch 123456
timezone.pl -timezone EST5EDT|CDT|CST -offset 5|6 -epoch 123456
timezone.pl -timezone EST5EDT|CDT|CST -offset 5|6

This script will return either CDT or CST (as our production database is in centeral time)
if invoked with only the tim_zone flag.  It will return 5 or 6 if the offset flag is specified
END
	exit 1;
}
gather_user_args();
do_work();
