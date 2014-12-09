#!/u01/dev/perl/64bit/bin/perl
use strict;
use warnings;
use lib '/home/t192zcs/Aptana_Studio_Workspace/PSTDashboard/jobs/perl/perl_modules/.';
use lib './jobs/perl/perl_modules/.';
use job;

print "Executing job $ARGV[0]\n";
my $executor = new JobExecutor(JobExecutor->get_job_engine_port);
$executor->execute_job($ARGV[0]);
