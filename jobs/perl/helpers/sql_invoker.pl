#!/u01/dev/perl/64bit/bin/perl
use strict;
use warnings;
use lib '/home/t192zcs/Aptana_Studio_Workspace/PSTDashboard/jobs/perl/perl_modules/.';
use lib './jobs/perl/perl_modules/.';


use job;

my $executor = new JobExecutor(JobExecutor->get_job_engine_port);
die "The credentials are not valid!.  Bye!\n"
  unless ( $executor->are_credentials_valid );
my @creds       = $executor->get_credentials;
my $script      = shift;
#my $sql_invoker = "/home/t192zcs/Aptana_Studio_Workspace/PSTDashboard/jobs/perl/helpers/sql.pl";
my $sql_invoker = "./jobs/perl/helpers/sql.pl";

my $arguments;
foreach my $arg (@ARGV) {
	$arguments .= $arg.' ';
}

warn "WARNING:  $sql_invoker $script $creds[0] $arguments";
#sample execution below
#./jobs/perl/helpers/sql.pl ./jobs/perl/MessageTrafficCheck/app2_alert_2.0 vhaispbowmag CDT APP2_ALERT 60
my $result = $executor->execute_sql("$sql_invoker $script $creds[0] $arguments");

if ($result =~ /.*OUTPUT_BELOW:(.*)OUTPUT_ABOVE:.*/m) {
	$result = $1;
	print $result;
	exit 0;
}

if ($result =~ /.*(EMAIL_RESULT_BELOW:.*EMAIL_RESULT_ABOVE:).*/s) {
	$result = $1;
	print $result;
	exit 0;
}

if ($result =~ /.*(<html>.*<\/html>).*/s) {
	$result = $1;
	print $result;
	exit 0;
}

print $result;
