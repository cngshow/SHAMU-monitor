SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

v_lookback         NUMBER := &1;       --this is the look back in minutes
v_tz               VARCHAR2(3):= '&2'; -- time zone
v_z01_lwm          NUMBER := &3;       -- z01 low water mark
v_z01_z06_pct      NUMBER := &4;       --acceptable percentage of z06s sent to z01s received
v_clear_pct        NUMBER := &5;       --clearing pct
v_last_status      VARCHAR2(5) := '&6';--the last known status

v_run_status       VARCHAR2(5) := '';  --the current run status
v_batch_calc_pct   NUMBER := 0;        --the calculated pct
v_Z01              NUMBER := 0;        --the count of Z01s received
v_Z02              NUMBER := 0;        --the count of Z02s sent
v_Z05              NUMBER := 0;        --the count of Z05s received
v_Z06              NUMBER := 0;        --the count of Z06s sent
v_Z07              NUMBER := 0;        --the count of Z07s received
v_va_site          VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
v_dod_site         VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';
edate              DATE := sysdate;
bdate              DATE := edate - (v_lookback/(60*24));
v_introscope_data  VARCHAR2(200) := 'NO_DATA';
v_result_list      VARCHAR2(500) :=  '';

BEGIN

    select sum(Z01), sum(Z02), sum(Z05), sum(Z06), sum(Z07) 
    into v_Z01,v_Z02,v_Z05,v_Z06,v_Z07
    from (
        SELECT sum(case a.event_type when 'ZCH_Z01' then 1 else 0 end) as Z01,
               0 as Z02,
               sum(case a.event_type when 'QBP_Z05' then 1 else 0 end) as Z05,
               0 as Z06,
               sum(case a.event_type when 'ZCH_Z07' then 1 else 0 end) as Z07
        FROM   chdr2.audited_event a
        WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','QBP_Z05','RSP_Z06','ZCH_Z07')
        and    a.created_date BETWEEN bdate AND edate
        and    a.sending_site = v_dod_site
        and    a.receiving_site = v_va_site
        and    a.outcome = 1

        UNION
            
        SELECT 0 as Z01,
               sum(case a.event_type when 'ZCH_Z02' then 1 else 0 end) as Z02,
               0 as Z05,
               sum(case a.event_type when 'RSP_Z06' then 1 else 0 end) as Z06,
               0 as Z07
        FROM   chdr2.audited_event a
        WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','QBP_Z05','RSP_Z06','ZCH_Z07')
        and    a.created_date BETWEEN bdate AND edate
        and    a.sending_site = v_va_site
        and    a.receiving_site = v_dod_site
        and    a.outcome = 1
        )
    ;
    
    -- begin - html output template
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="output">');
    DBMS_OUTPUT.put_line ('<div class="output_display">');
    -- end - html output template

    if (v_Z01 > v_z01_lwm) then
        v_batch_calc_pct := round(((v_Z06 / v_Z01) * 100),2);

        if (v_batch_calc_pct <= v_z01_z06_pct) then
            v_run_status := 'RED';
            v_result_list := 'Z01/Z06 - Batch Exchange / ADC percentage less than or equal to ' || v_z01_z06_pct || '%. The calculated batch exchange percentage is ' || v_batch_calc_pct || '%.</span>';
        else
            if (v_batch_calc_pct < v_clear_pct and v_last_status = 'RED') then
                v_run_status := 'RED';
                v_result_list := 'Z01/Z06 - The calculated batch exchange percentage is below the clearing percentage of ' || v_clear_pct  || '%. The calculated batch exchange percentage is ' || v_batch_calc_pct || '%.</span>';
            else
                v_run_status := 'GREEN';
                
                if (v_batch_calc_pct >= v_clear_pct) then
                	v_result_list := 'Z01/Z06 -  The calculated batch exchange percentage is greater than or equal to the clearing percentage of ' || v_clear_pct || '%. The calculated batch exchange percentage is ' || v_batch_calc_pct || '%.</span>';
                else
                	v_result_list := 'Z01/Z06 -  The calculated batch exchange percentage below the clearing percentage of ' || v_clear_pct || '%. However, the last known status was GREEN and we are above the alerting percentage of ' || v_z01_z06_pct || '%. The calculated batch exchange percentage is ' || v_batch_calc_pct || '%.</span>';
            	end if;
            end if;
        end if;
    else
    -- use last known status
        v_run_status := v_last_status;
        v_result_list := 'Z01/Z06 - Batch Exchange Z01 count is below the low water mark so we are reporting the last known status.';
    end if;

    if (v_run_status = 'RED') then
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');        
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Batch Exchange Alert!');
        DBMS_OUTPUT.put_line ('<h4>CHDR Batch Exchange Alert!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('DoD to VA Batch Exchange Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('The VA CHDR application is experiencing data flow issues based on audited messages written in the past ' || v_lookback || ' minutes.<br/><br/>');
        DBMS_OUTPUT.put_line (v_result_list || '</br>');
    else
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');   
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Batch Exchange Restored!');
        DBMS_OUTPUT.put_line ('<h4>CHDR Batch Exchange Restored!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('DoD to VA Batch Exchange is Restored!:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line (v_result_list || '</br>');
    end if;
    
    DBMS_OUTPUT.put_line ('<br><br><u>Message Counts in the Last ' || v_lookback || ' Minutes:</u><br/>');
    DBMS_OUTPUT.put_line ('Z01s Received = ' || v_z01 || '<br/>');
    DBMS_OUTPUT.put_line ('Z02s Sent = ' || v_z02 || '<br/>');
    DBMS_OUTPUT.put_line ('Z05s Received = ' ||  v_z05 || '<br/>');
    DBMS_OUTPUT.put_line ('Z06s Sent = ' ||  v_z06 || '<br/>');
    DBMS_OUTPUT.put_line ('Z07s Received = ' ||  v_z07 || '<br/>');

     v_introscope_data := 'Z01_Received=' || to_char(v_z01) || ';';
     v_introscope_data := v_introscope_data || 'Z02_Sent=' || to_char(v_z02) || ';';
     v_introscope_data := v_introscope_data || 'Z05_Received=' || to_char(v_z05) || ';';
     v_introscope_data := v_introscope_data || 'Z06_Sent=' || to_char(v_z06) || ';';
     v_introscope_data := v_introscope_data || 'Z07_Received=' || to_char(v_z07);

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
