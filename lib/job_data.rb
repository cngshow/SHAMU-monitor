require 'java'
require './lib/ucppool'


#a helper class to store transient job data
class JobData
  @@valid_credentials = false
  #@@ever_connected = false
  @@credentials_gone_bad = false;
  @@ora_pool = nil

  def self.ora_pool()
    @@ora_pool
  end

  def self.oracle_id() 
    @@oracle_id.clone
  end
  
  def self.oracle_password()
    @@oracle_password.clone
  end
  
  #  def self.oracle_password=(password)
  #    @@oracle_password = password
  #  end
  #  
  #  def self.oracle_id=(id)
  #   # puts "ID = " << id
  #    @@oracle_id=id
  #  end
  
  #returns an array, first element is a boolean telling
  #connection status (true for connected)
  #second element is the error string if connection failed
  #if the connection succeeds then the user name and password are updated!
  def self.connect_to_oracle(oracle_id,oracle_password, current_id_check = false)
    oracle_connect = $application_properties[$connect_string]
    connected = []
    id_change =  ! @@oracle_id.eql?(oracle_id)
    connection = nil
    begin
      #puts "instantiate a new pool -- #{id_change} -- #{@@oracle_id} -- #{oracle_id}"
      pool = MyOracleUcpPool.new(oracle_id, oracle_password, oracle_connect, 0, $application_properties["max_ucp_pool_size"].to_i, 2) if (@@ora_pool.nil? || id_change)
      pool = @@ora_pool if pool.nil?
      connection = pool.get_connection
      @@ora_pool = pool
      error = false #use debugger to test code below
      if (error)
        raise "Database broken!"
      end

      connected << true
      connected << "No Error!"
      @@oracle_id = oracle_id
      @@oracle_password = oracle_password

      #if (id_change)
      #	$logger.info("An ID change to #{oracle_id} is motivating a reset of the connection pool")
      #  Chdr::ConnectionPool.get_instance.reset_pool if @@ever_connected
      #end
      @@ever_connected = true


      if (!@@valid_connection.nil? && !@@valid_connection)
        @@connection_change = true
      else
        @@connection_change = false
      end
      @@valid_connection = true
    rescue => ex
      error_string = ex.to_s
      $logger.error("ERROR -- " + error_string)
      #error_string = "ORA-28002: the password will expire within 9 days"
      $logger.error("Could not connect to oracle with user #{oracle_id}  " << ex.to_s)
      connected << false
      error_string = "Could not connect to #{oracle_connect} with user #{oracle_id} -- " + $!.to_s
      connected << error_string
      if ((ex.to_s =~ /ORA-28002:/) && !@@credentials_gone_bad && current_id_check)
      	@@credentials_gone_bad = true
        JobMailer.database_credential_ceased_working(oracle_id, ex).deliver
      end
      @@valid_credentials = false
      if (!@@valid_connection.nil? && @@valid_connection)
        @@connection_change = true
      else
        @@connection_change = false
      end
      @@valid_connection = false
    ensure
      begin
        @@ora_pool.return_connection(connection) #best effort to return the connection
      rescue =>ex
      end
    end
    $logger.debug("connected = " + @@valid_connection.to_s + ":: connection change = " +@@connection_change.to_s)
    connected << @@connection_change
  end
  
  #returns an array, first element is a boolean telling
  #connection status (true for connected)
  #second element is the error string if connection failed
  #if the connection succeeds then the user name and password are updated!
  def self.connect_to_oracle_with_current_ID
    return self.connect_to_oracle(@@oracle_id,@@oracle_password, true)
  end
  
  private
  @@valid_connection = nil
  @@connection_change = nil
  @@oracle_id='unknown'
  @@oracle_password='unknown'
end