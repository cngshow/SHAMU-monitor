SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

v_lookback           NUMBER       := &1;    --this is the look back in minutes
v_tz                 VARCHAR2(3)  := '&2';
v_dup_pct            NUMBER       := &3;
v_clearing_pct       NUMBER       := &4; --only checked if the last known status is red
v_z04_min            NUMBER       := &5; --minimum Z04s on which to check duplication
v_last_known_status  VARCHAR2(10) := '&6';
v_status             VARCHAR2(5)  := 'GREEN';
v_msg                VARCHAR2(2000) := '';

edate            DATE := sysdate;
bdate            DATE := edate - (v_lookback/(60*24));

v_total_z04s     NUMBER := 0;
v_unique_z04s    NUMBER := 0;
v_dup_calc       NUMBER := 0;
v_va_site     VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
v_dod_site    VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';
v_introscope_data	VARCHAR2(200) := 'NO_DATA';

BEGIN
    select count(*) as total, 
        count(distinct a.correlation_id) as unique_z04s
    into v_total_z04s,
         v_unique_z04s
    from chdr2.audited_event a
    WHERE a.created_date between bdate and edate
    and   a.event_type = 'ZCH_Z04'
    and   a.sending_site = v_dod_site
    and   a.receiving_site = v_va_site
    ;

    -- begin - html output template
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="output">');
    DBMS_OUTPUT.put_line ('<div class="output_display">');
    -- end - html output template

    if (v_total_z04s >= v_z04_min) then
        v_dup_calc := (((v_total_z04s / v_unique_z04s) -1) * 100);
        v_msg := 'The current duplication rate is ' || v_dup_calc || '%.</br></br>';
        
        if (v_dup_calc >= v_dup_pct) then 
            v_status := 'RED';
            v_msg := v_msg || 'The duplication threshold of ' || v_dup_pct ||'% has been exceeded.<br/>';
        else
            v_status := v_last_known_status;

            if (v_last_known_status = 'RED' and v_dup_calc <= v_clearing_pct) then
                v_status := 'GREEN';
                v_msg := v_msg || 'The clearing threshold of ' || v_clearing_pct ||'% has been abated.<br/>';
            end if;
        end if;
    else
        v_status := v_last_known_status;
        v_msg := v_msg || 'Due to the minimum volume of Z04s being below ' || v_z04_min || ' clinical messages received, duplication was not computed. The last known status is being reported.<br/>';
    end if;

    if (v_status = 'RED') then
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');        
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Duplication Alert!');
        DBMS_OUTPUT.put_line ('<h4>CHDR Duplication Alert!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('The VA CHDR application is experiencing duplication of clinical messages received from DoD.<br/>');
    else
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');   
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Duplication Restored!');
        DBMS_OUTPUT.put_line ('<h4>CHDR Duplication Restored!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('The VA CHDR application is no longer experiencing duplication of clinical messages received from DoD.<br/>');
    end if;

    DBMS_OUTPUT.put_line ('<br/>Results in the past ' || v_lookback || ' minutes:<br/>');
    DBMS_OUTPUT.put_line ('Unique Z04s Received = ' || v_unique_z04s || '<br/>');
    DBMS_OUTPUT.put_line ('Total Z04s Received = ' || v_total_z04s || '<br/>');
    DBMS_OUTPUT.put_line (v_msg || '<br/>');
    DBMS_OUTPUT.put_line ('<span class="note">');
    DBMS_OUTPUT.put_line ('<br/>Rules:<br/>');
    DBMS_OUTPUT.put_line ('If the minimim number of Z04s received exceeds ' || v_z04_min|| ' and we are duplicating greater than or equal to ' || v_dup_pct || '% then we are RED.<br/>');
    DBMS_OUTPUT.put_line ('To clear to GREEN the duplication rate must fall to ' || v_clearing_pct || '% or below.<br/>');
    DBMS_OUTPUT.put_line ('</span>');

 	v_introscope_data := 'TOTAL_Z04_RCVD=' || to_char(v_total_z04s) || ';';
 	v_introscope_data := v_introscope_data || 'UNIQUE_Z04_RCVD=' || to_char(v_unique_z04s);
 	
    DBMS_OUTPUT.put_line ('<span class="status">');
    DBMS_OUTPUT.put_line ('INTROSCOPE_DATA_BEGIN_' || v_introscope_data || '_INTROSCOPE_DATA_END<br>');
    DBMS_OUTPUT.put_line ('</span>');   
    
    DBMS_OUTPUT.put_line ('<br/>--------<br/>');
    DBMS_OUTPUT.put_line ('Begin Date (' || v_tz || ') = ' || to_char(bdate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('End Date (' || v_tz || ') = ' || to_char(edate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('</div><br><br>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');    
END;
/
disconnect;
exit;
