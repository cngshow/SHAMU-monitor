require './lib/ucppool'

def oracle_credentials
  creds = nil
  File.open('./test/oracle_password.txt', 'r') do |file_handle|
    file_handle.read.each_line do |line|
      creds = line.chomp.split(',')
    end
  end
  return creds
end

print "Run at ", Time.now , "\n"

conn = nil
ucppool = nil
creds = oracle_credentials

begin

 #ucppool = MyOracleUcpPool.new(creds[0], creds[1], "jdbc:oracle:thin:@//hdr2db4v.aac.va.gov:1569/CHDRP01.AAC.VA.GOV ", 0, 5, 2) #PRODUCTION
 ucppool = MyOracleUcpPool.new(creds[0], creds[1], "jdbc:oracle:thin:@//hdrtcl03.aac.va.gov:1521/chrdeva", 0, 5, 2) #DEV
#  ucppool = MyOracleUcpPool.new("bob", creds[1], "jdbc:oracle:thin:@//hdrtcl03.aac.va.gov:1521/chrdeva", 0, 5, 2) #DEV
  print ucppool , "\n"

  #get connection from pool
  conn = ucppool.get_connection()

  #print pool details
  print ucppool.displayPoolDetails()
  puts

  #execute query
  # see http://download.oracle.com/javase/6/docs/api/java/sql/ResultSet.html   for result set methods
  stmt = conn.createStatement()
 # rset = stmt.executeQuery("select a.message_id, a.created_date from chdr2.audited_event a where a.created_date > sysdate - .01") #production
   rset = stmt.executeQuery("select sysdate as mytime from dual") #dev
  while rset.next()
    #print "MessageID=", rset.getString("message_id").to_s,
    #      ", Date=" + rset.getString("created_date").to_s, "\n"
    print "mytime=", rset.getString("mytime").to_s, "\n"

  end

  rset.close()
  stmt.close()

  #return connection
  ucppool.returnConnection(conn)
  print "\nConnection returned to pool\n"

  #print pool details
  print ucppool.displayPoolDetails()

rescue
  print "\n** Error occured **\n"
  print "Failed executing UCP Pool demo from JRuby ", $!, "\n"
  if (!conn.nil?)
    if (!ucppool.nil?)
      ucppool.returnConnection(conn)
      print "\nConnection returned to pool\n"
    end
  end

end

print "\nEnded at ", Time.now , "\n"  