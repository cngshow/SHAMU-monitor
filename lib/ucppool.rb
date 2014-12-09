require 'java'
require './lib/jars/ojdbc6.jar'
require './lib/jars/ucp.jar'

java_import 'oracle.ucp.jdbc.PoolDataSource'
java_import 'oracle.ucp.jdbc.PoolDataSourceFactory'

API_VERSION = 1.0


######################## BEGIN IMPORTANT NOTE ########################
# The following link takes you to the oracle connection pool documentation
#   http://docs.oracle.com/cd/B28359_01/java.111/e11990/allclasses-noframe.html
######################## END IMPORTANT NOTE ########################
class MyOracleUcpPool

  #pool data source object
  @pds

  def initialize(user, passwd, url, minsize=0, maxsize=10, initialsize=2)
    $logger.debug("initializing UCP Pool")
    begin
      @user        = user
      @passwd      = passwd
      @url         = url
      @minsize     = minsize
      @maxsize     = maxsize
      @initialsize = initialsize

      #create pool for use here
      @pds         = PoolDataSourceFactory.getPoolDataSource()
      @pds.setUser(user)
      @pds.setPassword(passwd)
      @pds.setURL(url)
      @pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource")
      #@pds.setConnectionPoolName("SHAMU-ucppool" + @@instance_count.to_s) #if you use this you must change the pool name with each instance
      @pds.setInitialPoolSize(initialsize)
      @pds.setMinPoolSize(minsize)
      @pds.setMaxPoolSize(maxsize)
    rescue => ex
      $logger.error("The UCP Pool for  " + user + " failed create!")
      $logger.error(ex.backtrace.join("\n"))
      raise ex
    end
    $logger.debug("Created a new UCP Pool for user " + @user)
  end

  #add getters and setters for all attrributes
  attr_reader :user, :passwd, :url, :minsize, :maxsize, :initialsize

  def getConnection()
    conn = get_valid_connection
    $logger.debug("getConnection in ucp pool stats:")
    $logger.debug(displayPoolDetails)
    return conn
  end

  def returnConnection(conn)
    conn.close()
    $logger.debug("returnConnection in ucp pool stats:")
    $logger.debug(displayPoolDetails)
  end

  def displayPoolDetails()
    return "\n** UCP Pool Details **\n" +
        "NumberOfAvailableConnections: " + @pds.getAvailableConnectionsCount().to_s + "\n" +
        "BorrowedConnectionsCount: " + @pds.getBorrowedConnectionsCount().to_s + " \n";
  end

  def to_s
    "MyOracleUcpPool [user=#{@user}, passwd=*******, " +
        "url=#{@url}, minsize=#{@minsize}, maxsize=#{@maxsize}, " +
        "initialsize=#{@initialsize}]"
  end

  alias_method :to_string, :to_s
  alias_method :get_connection, :getConnection
  alias_method :return_connection, :returnConnection
  alias_method :display_pool_details, :displayPoolDetails

  private

  def get_valid_connection
    retry_count = 1
    conn = get_pool_data_source_connection

    while (! conn.is_valid(10) && retry_count < $application_properties["max_ucp_pool_size"].to_i)
      returnConnection(conn)
      conn = get_pool_data_source_connection
      retry_count += 1
    end
    conn
  end

  def get_pool_data_source_connection
    $logger.debug("Attempting to get a connection for user " + user)
    begin
      return @pds.getConnection()
    rescue => ex
      $logger.info("The UCP Pool for user " + user + " failed to get a connection!")
      $logger.info(ex.backtrace.join("\n"))
      raise ex
    end
  end
end
