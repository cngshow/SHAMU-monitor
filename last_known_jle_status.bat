@ECHO OFF
%java_home%\bin\java -jar .\lib\jars\jruby-complete-1.6.7.2.jar ./script/rails r -e %1 "JobMetadata.get_last_known_status_for_jc(\"%2\",\"%3\")"