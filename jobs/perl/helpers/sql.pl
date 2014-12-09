#!/u01/dev/perl/64bit/bin/perl

$script = shift;
$user = shift;
for $arg (@ARGV) {
	$all_args .= $arg.' ';
}

#warn "SQLPLUS:: sqlplus -s ${user}\@CHDRP01.AAC.VA.GOV \@$script $all_args\n";
print "Enter Oracle Password:\n";
system ("sqlplus -s ${user}\@CHDRP01.AAC.VA.GOV \@$script $all_args");
#system ("sqlplus -s ${user}\@CHDRSQA \@$script $all_args");
