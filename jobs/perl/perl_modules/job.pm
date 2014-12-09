package JobExecutor;
#note:  Job.pm is NOT threadsafe!  Specifically execute_sql!
#Cris Shupp
use strict;
use warnings;
use Carp;
use IO::Socket;
use Expect;

#$Expect::Debug = 1;
#$Expect::Log_Stdout=1;
my $expect_output;
my $current_passwd;

sub new($$$) {
	my $this  = shift;
	my $class = ref($this) || $this;
	my $self  = {};
	bless $self, $class;
	$self->{port} = shift;
	return $self;
}

sub get_job_engine_port {

	my $rval = get_property('job_engine_port');
	return $rval unless ($rval eq 'PROPERTY_NOT_DEFINED');
	return '2001'
}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+// unless !defined $string;
	$string =~ s/\s+$// unless !defined $string;
	return $string;
}

sub execute_sql($$) {
	my $self   = shift;
	my $sql    = shift;
	my @creds = $self->get_credentials;
	$expect_output = '';
	my $process = Expect->spawn($sql) || croak ("Could not execute $sql, reason: $!\n");
	$current_passwd = $creds[1];
	$process->log_file(\&output);
	$process->log_stdout(0);
	$process->debug(0);
	$process->expect(15,'Enter Oracle Password:');
	$process->send ("$creds[1]\n");
	my $wait_time = get_property('max_time_sqlplus_hours');
	$process->expect($wait_time*60*60);#support a query that takes up to $wait_time hours to run
	$process->soft_close();	
	$expect_output;
}

sub execute_job($$) {
	my $self   = shift;
	my $job    = shift;
	my $socket = $self->get_socket();
	print $socket "$job\n";
	# and terminate the connection when we're done
	close($socket);
}

sub get_email_list($$) {
	my $self   = shift;
	my $job    = shift;
	my $socket = $self->get_socket();
	local $|;
	$|++;
	print $socket "__email_list:$job\n";
	my $list_string = <$socket>;
	close($socket);
	chomp $list_string;
	my ($to,$cc) = split ('\|',$list_string);
	my @to_array = split (',',$to);
	my @cc_array = split (',',$cc);
	{'email_to' => \@to_array, 'email_cc' => \@cc_array}
}

sub are_credentials_valid($) {
	my $self   = shift;
	my $socket = $self->get_socket();
	local $|;
	$|++;
	print $socket "__are_credentials_valid\n";
	my $seeded = <$socket>;
	close $socket;
	chomp $seeded;
	$seeded eq 'true'
}

sub get_credentials($) {
	my $self   = shift;
	my $socket = $self->get_socket();
	my @creds;
	local $|;
	$|++;
	print $socket "__credentials\n";

	#$socket->flush;
	my $creds = <$socket>;
	@creds = split( /,/, $creds );
	close $socket;
	chomp @creds;
	@creds;
}

sub execute_job_and_get_credentials($$) {
	my $self   = shift;
	my $job    = shift;
	my $socket = $self->get_socket();
	local $|;
	$|++;
	print $socket "__credentials\n";
	#$socket->flush;
	my $creds = <$socket>;
	my @creds = split( /,/, $creds );
	print $socket "$job\n";
	close $socket;
	@creds;
}

#private methods

sub get_socket($) {
	my $self   = shift;
	my $socket = IO::Socket::INET->new(
		PeerAddr => 'localhost',
		PeerPort => $self->{port},
		Proto    => "tcp",
		Type     => SOCK_STREAM
	  )
	  or croak "Couldn't connect to localhost:$self->{port} : $@\n";
	$socket;
}

#static private method
sub output() {
	my $line = shift;
	$expect_output .= $line unless ($line =~ /^${current_passwd}/);
}

sub get_property($) {
	my $prop_key = shift;
	open (PROPS, './pst_dashboard.properties')  || warn "Cannot open pst_dashboard.properties : $!, using 2001";
	my @props=<PROPS>;
	close PROPS;
	foreach my $prop (@props) {
		my ($key,$value) = split('=',$prop);
		$key = trim($key);
		$value = trim($value);
		if ($key eq $prop_key) {
			#print "returning $value\n";
			return $value;
		}
	}
	return 'PROPERTY_NOT_DEFINED'
  }
1;
