source shamu_env.bash
java -jar ./lib/jars/jruby-complete-1.6.7.2.jar ./script/rails r -e $1 "JobLogEntry.clean_up_log_for_user"
