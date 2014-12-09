@ECHO OFF
java -jar .\lib\jars\jruby-complete-1.6.7.2.jar ./script/rails r -e %1 "JobLogEntry.introscope_alerts"
