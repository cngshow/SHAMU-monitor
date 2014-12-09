SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

v_input VARCHAR2(200) := '&1'; 
v_current DATE := sysdate;

BEGIN
    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('THE PARAMETER PASSED WAS: ' || v_input || '!!!');
    DBMS_OUTPUT.put_line ('the current time is ' || to_char(v_current,'yyyymmdd hh24:mi:ss'));
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');
END;
/
disconnect;
exit;