SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

--setup
v_tz                    VARCHAR2(3)  := '&1';
v_job_code              VARCHAR2(50) := '&2';
v_lookback              NUMBER       := &3;    --this is the look back in minutes
v_last_write_lookback   NUMBER       := &4;    --this is the look back for the last message written in minutes
v_low_water_mark        NUMBER       := &5;
v_clearing_cnt			NUMBER		 := &6;
v_last_known_status     VARCHAR2(10) := '&7';

v_status                VARCHAR2(5)  := '';
v_va_site               VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';

edate            DATE := sysdate;
bdate            DATE := edate - (v_lookback/1440);

--query result variables
n_vista_z03_cnt         NUMBER        := 0;
n_last_vista_write      DATE          := null;
v_introscope_data	VARCHAR2(200) := 'NO_DATA';

BEGIN
    --retrieve the count of audited records in CHDR for the period
    select count(*) 
    into   n_vista_z03_cnt
    from   chdr2.audited_event a
    WHERE  a.created_date  between bdate and edate
    and    a.sending_site = v_va_site
    and    a.receiving_site = v_dod_site
    and    a.event_type in ('ALGY','PRES','FILL','CHEM')
    ;
    
    --retrieve the last audited vista Z03 message sent to DoD
    select max(a.created_date) 
    into   n_last_vista_write
    from   chdr2.audited_event a
    WHERE  a.created_date between bdate - (v_last_write_lookback/1440) and edate -- due to performance issues we are looking back a certain number of minutes to ensure that we get a last write record
    and    a.sending_site = v_va_site
    and    a.receiving_site = v_dod_site
    and    a.event_type in ('ALGY','PRES','FILL','CHEM')
    ;

    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="output">');
    DBMS_OUTPUT.put_line ('<div class="output_display">');

    if (n_vista_z03_cnt < v_low_water_mark) then
        v_status := 'RED';
    else
    	if (n_vista_z03_cnt < v_clearing_cnt) then
    		v_status := v_last_known_status;
    	else
    	    v_status := 'GREEN';
    	end if;
    end if;
    
    if (v_status = 'RED') then
        --red light (no writes in x minutes)
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');        
        DBMS_OUTPUT.put_line ('SUBJECT: VA CHDR - Vista Messages Received Alert!');
        DBMS_OUTPUT.put_line ('<h4>VA CHDR - Vista Messages Received is<br/>below the low water mark of ' || v_low_water_mark || ' or below the clearing count of ' || v_clearing_cnt || '</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('The VA CHDR application has not received enough clinical messages from Vista (Z03s) in the past ' || v_lookback || ' Minutes.<br/><br/>');
    else
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');   
        DBMS_OUTPUT.put_line ('SUBJECT: VA CHDR - Vista Message Traffic Restored!');
        DBMS_OUTPUT.put_line ('<h4>VA CHDR - Vista Message Traffic Restored!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('Message traffic from Vista to VA CHDR has been restored.<br/><br/>');
    end if;

    DBMS_OUTPUT.put_line ('Message Counts in the Last ' || v_lookback || ' Minutes:<br/>');
    DBMS_OUTPUT.put_line ('Vista Clinical Data Received and Sent to DoD = ' || n_vista_z03_cnt || '<br/>');
    DBMS_OUTPUT.put_line ('Vista Clinical Data Low Water Mark = ' || v_low_water_mark || '<br/>');
    DBMS_OUTPUT.put_line ('Vista Clearing Count = ' || v_clearing_cnt || '<br/>');
    
    if (n_last_vista_write is null) then
        DBMS_OUTPUT.put_line ('No messages have been received from Vista in the last ' || v_last_write_lookback || ' minutes.<br/><br/>');
    else
        DBMS_OUTPUT.put_line ('Last Audited Vista Message Written (' || v_tz || ') = ' || to_char(n_last_vista_write, 'DD-MON-YY HH24:MI:SS') || '<br/><br/>');
    end if;
 
 	v_introscope_data := 'Z03_SENT=' || to_char(n_vista_z03_cnt);
    DBMS_OUTPUT.put_line ('<span class="status">');
    DBMS_OUTPUT.put_line ('INTROSCOPE_DATA_BEGIN_' || v_introscope_data || '_INTROSCOPE_DATA_END<br>');
    DBMS_OUTPUT.put_line ('</span>');   

    DBMS_OUTPUT.put_line ('<br/>--------<br/>');
    DBMS_OUTPUT.put_line ('Begin Date (' || v_tz || ') = ' || to_char(bdate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('End Date (' || v_tz || ') = ' || to_char(edate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('<span class="job_code">(' || v_job_code || ')</span>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('</div><br><br>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');
END;
/
disconnect;
exit;
