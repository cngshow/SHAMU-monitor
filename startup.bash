source shamu_env.bash
echo $1 > ./log/rails_port.txt
rm nohup.out
nohup java -server -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -XX:+HeapDumpOnOutOfMemoryError -Xmx512m -Xms256m  -jar ./lib/jars/jruby-complete-1.6.7.2.jar script/rails server mongrel -p $1 -e $2 &
