SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

v_lookback       NUMBER := &1;    --this is the look back in minutes
v_direction      VARCHAR2(20):= '&2';--pass in dod_to_va or va_to_dod
v_tz             VARCHAR2(3):= '&3';
v_z01_z02_pct    NUMBER := &4;
v_z03_z04_pct    NUMBER := &5;
v_z05_z06_pct    NUMBER := &6;
v_z06_z07_pct    NUMBER := &7;
v_z01_lwm        NUMBER := &8; -- z01 low water mark
v_z03_lwm        NUMBER := &9;--z03 low water mark
v_z05_lwm        NUMBER := &10;--z05 low water mark
v_z06_lwm        NUMBER := &11;--z06 low water mark
v_z01_min        NUMBER := &12;--z01 minimum
v_z03_min        NUMBER := &13;--z03 minimum
v_z05_min        NUMBER := &14;--z05 minimum
v_z06_min        NUMBER := &15;--z06 minimum
v_z01_clear_pct  NUMBER := &16;--z01 clearing pct
v_z03_clear_pct  NUMBER := &17;--z03 clearing pct
v_z05_clear_pct  NUMBER := &18;--z05 clearing pct
v_z06_clear_pct  NUMBER := &19;--z06 clearing pct
v_run_status     VARCHAR2(100) := '&20';
v_z01_ignore_min_on_clear NUMBER := &21;--zero is false and anything else is true
v_z03_ignore_min_on_clear NUMBER := &22;
v_z05_ignore_min_on_clear NUMBER := &23;
v_z06_ignore_min_on_clear NUMBER := &24;

v_response_calc_pct  NUMBER := 0;
v_result_list        VARCHAR2(2000) :=  '';
v_request            VARCHAR2(10)   := 'Sent';--text used in output based on v_direction
v_response           VARCHAR2(10)   := 'Received';
v_z01_run_status     VARCHAR2(5)    := 'GREEN';
v_z03_run_status     VARCHAR2(5)    := 'GREEN';
v_z05_run_status     VARCHAR2(5)    := 'GREEN';
v_z06_run_status     VARCHAR2(5)    := 'GREEN';
v_z01_last_status    VARCHAR2(5)    := 'GREEN';
v_z03_last_status    VARCHAR2(5)    := 'GREEN';
v_z05_last_status    VARCHAR2(5)    := 'GREEN';
v_z06_last_status    VARCHAR2(5)    := 'GREEN';
v_Z01                NUMBER := 0;
v_Z02                NUMBER := 0;
v_Z03                NUMBER := 0;
v_Z04                NUMBER := 0;
v_Z05                NUMBER := 0;
v_Z06                NUMBER := 0;
v_Z07                NUMBER := 0;
v_va_site            VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
v_dod_site           VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';
edate                DATE := sysdate;
bdate                DATE := edate - (v_lookback/(60*24));
v_introscope_data	 VARCHAR2(200) := 'NO_DATA';

components owa_text.vc_arr ;

BEGIN

    -- messages received and sent by VA
    if (v_direction = 'dod_to_va') then
        v_request  := 'Received';
        v_response := 'Sent';

        select sum(Z01), sum(Z02), sum(Z03), sum(Z04), sum(Z05), sum(Z06), sum(Z07) 
        into v_Z01,v_Z02,v_Z03,v_Z04,v_Z05,v_Z06,v_Z07
        from (
            SELECT sum(case a.event_type when 'ZCH_Z01' then 1 else 0 end) as Z01,
                   0 as Z02,
                   sum(case when a.event_type in ('FILL','CHEM','PRES','ALGY') then 1 else 0 end) as Z03,
                   0 as Z04,
                   sum(case a.event_type when 'QBP_Z05' then 1 else 0 end) as Z05,
                   0 as Z06,
                   sum(case a.event_type when 'ZCH_Z07' then 1 else 0 end) as Z07
            FROM   chdr2.audited_event a
            WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
            and    a.created_date BETWEEN bdate AND edate
            and    a.sending_site = v_dod_site
            and    a.receiving_site = v_va_site
            and	   a.outcome = 1

            UNION
            
            SELECT 0 as Z01,
                   sum(case a.event_type when 'ZCH_Z02' then 1 else 0 end) as Z02,
                   0 as Z03,
                   sum(case a.event_type when 'ZCH_Z04' then 1 else 0 end) as Z04,
                   0 as Z05,
                   sum(case a.event_type when 'RSP_Z06' then 1 else 0 end) as Z06,
                   0 as Z07
            FROM   chdr2.audited_event a
            WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
            and    a.created_date BETWEEN bdate AND edate
            and    a.sending_site = v_va_site
            and    a.receiving_site = v_dod_site
            and	   a.outcome = 1
            )
        ;
    else
        select sum(Z01), sum(Z02), sum(Z03), sum(Z04), sum(Z05), sum(Z06), sum(Z07) 
        into v_Z01,v_Z02,v_Z03,v_Z04,v_Z05,v_Z06,v_Z07
        from (
            SELECT sum(case a.event_type when 'ZCH_Z01' then 1 else 0 end) as Z01,
                   0 as Z02,
                   sum(case when a.event_type in ('FILL','CHEM','PRES','ALGY') then 1 else 0 end) as Z03,
                   0 as Z04,
                   sum(case a.event_type when 'QBP_Z05' then 1 else 0 end) as Z05,
                   0 as Z06,
                   sum(case a.event_type when 'ZCH_Z07' then 1 else 0 end) as Z07
            FROM   chdr2.audited_event a
            WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
            and    a.created_date BETWEEN bdate AND edate
            and    a.sending_site = v_va_site
            and    a.receiving_site = v_dod_site
            and	   a.outcome = 1

            UNION
            
            SELECT 0 as Z01,
                   sum(case a.event_type when 'ZCH_Z02' then 1 else 0 end) as Z02,
                   0 as Z03,
                   sum(case a.event_type when 'ZCH_Z04' then 1 else 0 end) as Z04,
                   0 as Z05,
                   sum(case a.event_type when 'RSP_Z06' then 1 else 0 end) as Z06,
                   0 as Z07
            FROM   chdr2.audited_event a
            WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
            and    a.created_date BETWEEN bdate AND edate
            and    a.sending_site = v_dod_site
            and    a.receiving_site = v_va_site
            and	   a.outcome = 1
            )
        ;
    end if;

    --
    if (owa_pattern.match(v_run_status, '(\w*):(\w*):(\w*):(\w*)', components)) then
        v_z01_last_status := components(1);
        v_z03_last_status := components(2);
        v_z05_last_status := components(3);
        v_z06_last_status := components(4);
    end if;

    -- begin - html output template
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="output">');
    DBMS_OUTPUT.put_line ('<div class="output_display">');
    -- end - html output template
    
/*
    if (v_z01_min <= 0 or v_z03_min <= 0 or v_z05_min <= 0 or v_z06_min <= 0) then
    --see about raising a configuration exception!
    end if;
*/
    
    --check adc activation traffic
    if (v_Z01 > 0) then
        v_response_calc_pct := ((v_Z02 / v_Z01) * 100);
    else
        v_response_calc_pct := 100;
    end if;
    
    if (v_Z01 < v_z01_lwm) then
        v_z01_run_status := 'RED';
        v_result_list := v_result_list || '<li><span style="color: ' || v_z01_run_status ||'">Z01 Requests are below the low water mark of ' || v_z01_lwm || '.</span></li>';
    else
        if (v_Z01 >= v_z01_min) then
            if (v_response_calc_pct <= v_z01_z02_pct) then
                v_z01_run_status := 'RED';
                v_result_list := v_result_list || '<li><span style="color: ' || lower(v_z01_run_status) ||'">Z02/Z01 - Response percentage below ' || v_z01_z02_pct || '%.</span></li>';
            else
                if (v_response_calc_pct < v_z01_clear_pct and v_z01_last_status = 'RED') then
                    v_z01_run_status := 'RED';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z01_run_status ||'">Z02/Z01 - Response percentage is below the clearing percentage of ' || v_z01_clear_pct || '%.</span></li>';
                else
                    v_z01_run_status := 'GREEN';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z01_run_status ||'">Z02/Z01 - Response percentage is above the clearing percentage of ' || v_z01_clear_pct || '%.</span></li>';
                end if;
            end if;
        else
        	if (v_z01_ignore_min_on_clear > 0 and v_response_calc_pct >= v_z01_clear_pct) then
	            v_z01_run_status := 'GREEN';
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z01_run_status ||'">Z02/Z01 - Z01 count did not reach the minimum threshold of ' || v_z01_min || ' which must be eclipsed in order to check response percentages. However, we are currently ignoring the minimum threshold for clearing events. Because the calculated response percentage is above the clearing percentage we are going green.</span></li>';
        	else
	            v_z01_run_status := v_z01_last_status;
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z01_run_status ||'">Z02/Z01 - Z01 count did not reach the minimum threshold of ' || v_z01_min || ' which must be eclipsed in order to check response percentages. Therefore, the last known status will be used provided another Z-message handshake is not alerting with this run.</span></li>';
        	end if; 
        end if;
    end if;
    
    --check clinical updates
    if (v_Z03 > 0) then
        v_response_calc_pct := ((v_Z04 / v_Z03) * 100);
    else
        v_response_calc_pct := 100;
    end if;
    
    if (v_Z03 < v_z03_lwm) then
        v_z03_run_status := 'RED';
        v_result_list := v_result_list || '<li><span style="color: ' || v_z03_run_status ||'">Z03 Requests are below the low water mark of ' || v_z03_lwm || '.</span></li>';
    else
        if (v_Z03 >= v_z03_min) then
            if (v_response_calc_pct <= v_z03_z04_pct) then
                v_z03_run_status := 'RED';
                v_result_list := v_result_list || '<li><span style="color: ' || lower(v_z03_run_status) ||'">Z04/Z03 - Response percentage below ' || v_z03_z04_pct || '%.</span></li>';
            else
                if (v_response_calc_pct < v_z03_clear_pct and v_z03_last_status = 'RED') then
                    v_z03_run_status := 'RED';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z03_run_status ||'">Z04/Z03 - Response percentage is below the clearing percentage of ' || v_z03_clear_pct || '%.</span></li>';
                else
                    v_z03_run_status := 'GREEN';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z03_run_status ||'">Z04/Z03 - Response percentage is above the clearing percentage of ' || v_z03_clear_pct || '%.</span></li>';
                end if;
            end if;
        else
        	if (v_z03_ignore_min_on_clear > 0 and v_response_calc_pct >= v_z03_clear_pct) then
	            v_z03_run_status := 'GREEN';
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z03_run_status ||'">Z04/Z03 - Z03 count did not reach the minimum threshold of ' || v_z03_min || ' which must be eclipsed in order to check response percentages. However, we are currently ignoring the minimum threshold for clearing events. Because the calculated response percentage is above the clearing percentage we are going green.</span></li>';
        	else
	            v_z03_run_status := v_z03_last_status;
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z03_run_status ||'">Z04/Z03 - Z03 count did not reach the minimum threshold of ' || v_z03_min || ' which must be eclipsed in order to check response percentages. Therefore, the last known status will be used provided another Z-message handshake is not alerting with this run.</span></li>';
	        end if;
        end if;
    end if;

    --check batch exchange traffic
    if (v_Z05 > 0) then
        v_response_calc_pct := ((v_Z06 / v_Z05) * 100);
    else
        v_response_calc_pct := 100;
    end if;
    
    if (v_Z05 < v_z05_lwm) then
        v_z05_run_status := 'RED';
        v_result_list := v_result_list || '<li><span style="color: ' || v_z05_run_status ||'">Z05 Requests are below the low water mark of ' || v_z05_lwm || '.</span></li>';
    else
        if (v_Z05 >= v_z05_min) then
            if (v_response_calc_pct <= v_z05_z06_pct) then
                v_z05_run_status := 'RED';
                v_result_list := v_result_list || '<li><span style="color: ' || lower(v_z05_run_status) ||'">Z06/Z05 - Response percentage below ' || v_z05_z06_pct || '%.</span></li>';
            else
                if (v_response_calc_pct < v_z05_clear_pct and v_z05_last_status = 'RED') then
                    v_z05_run_status := 'RED';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z05_run_status ||'">Z06/Z05 - Response percentage is below the clearing percentage of ' || v_z05_clear_pct || '%.</span></li>';
                else
                    v_z05_run_status := 'GREEN';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z05_run_status ||'">Z06/Z05 - Response percentage is above the clearing percentage of ' || v_z05_clear_pct || '%.</span></li>';
                end if;
            end if;
        else
        	if (v_z05_ignore_min_on_clear > 0 and v_response_calc_pct >= v_z05_clear_pct) then
	            v_z05_run_status := 'GREEN';
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z05_run_status ||'">Z06/Z05 - Z05 count did not reach the minimum threshold of ' || v_z05_min || ' which must be eclipsed in order to check response percentages. However, we are currently ignoring the minimum threshold for clearing events. Because the calculated response percentage is above the clearing percentage we are going green.</span></li>';
        	else
	            v_z05_run_status := v_z05_last_status;
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z05_run_status ||'">Z06/Z05 - Z05 count did not reach the minimum threshold of ' || v_z05_min || ' which must be eclipsed in order to check response percentages. Therefore, the last known status will be used provided another Z-message handshake is not alerting with this run.</span></li>';
	        end if;
        end if;
    end if;

    --check 3-phase batch response
    if (v_Z06 > 0) then
        v_response_calc_pct := ((v_Z07 / v_Z06) * 100);
    else
        v_response_calc_pct := 100;
    end if;
    
    if (v_Z06 < v_z06_lwm) then
        v_z06_run_status := 'RED';
        v_result_list := v_result_list || '<li><span style="color: ' || v_z06_run_status ||'">Z06 Requests are below the low water mark of ' || v_z06_lwm || '.</span></li>';
    else
        if (v_Z06 >= v_z06_min) then
            if (v_response_calc_pct <= v_z06_z07_pct) then
                v_z06_run_status := 'RED';
                v_result_list := v_result_list || '<li><span style="color: ' || lower(v_z06_run_status) ||'">Z07/Z06 - Response percentage below ' || v_z06_z07_pct || '%.</span></li>';
            else
                if (v_response_calc_pct < v_z06_clear_pct and v_z06_last_status = 'RED') then
                    v_z06_run_status := 'RED';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z06_run_status ||'">Z07/Z06 - Response percentage is below the clearing percentage of ' || v_z06_clear_pct || '%.</span></li>';
                else
                    v_z06_run_status := 'GREEN';
                    v_result_list := v_result_list || '<li><span style="color: ' || v_z06_run_status ||'">Z07/Z06 - Response percentage is above the clearing percentage of ' || v_z06_clear_pct || '%.</span></li>';
                end if;
            end if;
        else
        	if (v_z06_ignore_min_on_clear > 0 and v_response_calc_pct >= v_z06_clear_pct) then
	            v_z06_run_status := 'GREEN';
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z06_run_status ||'">Z07/Z06 - Z06 count did not reach the minimum threshold of ' || v_z06_min || ' which must be eclipsed in order to check response percentages. However, we are currently ignoring the minimum threshold for clearing events. Because the calculated response percentage is above the clearing percentage we are going green.</span></li>';
        	else
	            v_z06_run_status := v_z06_last_status;
	            v_result_list := v_result_list || '<li><span style="color: ' || v_z06_run_status ||'">Z07/Z06 - Z06 count did not reach the minimum threshold of ' || v_z06_min || ' which must be eclipsed in order to check response percentages. Therefore, the last known status will be used provided another Z-message handshake is not alerting with this run.</span></li>';
	        end if;
        end if;
    end if;

    --pull out the individual run statuses for each handshake
    v_run_status := v_z01_run_status || ':' || v_z03_run_status || ':' || v_z05_run_status || ':' || v_z06_run_status;
    DBMS_OUTPUT.put_line ('<span class="status">');
    DBMS_OUTPUT.put_line ('RUN_DATA_BEGIN_' || v_run_status || '_RUN_DATA_END');
    DBMS_OUTPUT.put_line ('</span><br>');        

    if (instr(v_run_status,'RED') > 0) then
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');        
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Data Flow Alert! - ' || v_direction);
        DBMS_OUTPUT.put_line ('<h4>CHDR Data Flow Alert!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('The VA CHDR application is experiencing data flow issues based on audited messages written in the past ' || v_lookback || ' minutes as follows:<br/>');
        DBMS_OUTPUT.put_line ('<ul>' || v_result_list || '</ul></br>');
    else
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');   
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Data Flow Restored! - ' || v_direction);
        DBMS_OUTPUT.put_line ('<h4>CHDR Data Flow Restored!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('Message traffic with DoD has been restored.<br/><br/>');
        DBMS_OUTPUT.put_line ('The VA CHDR message flow has resumed with messages written in the past ' || v_lookback || ' minutes as follows:<br/>');
        DBMS_OUTPUT.put_line ('<ul>' || v_result_list || '</ul></br>');
    end if;
    
    DBMS_OUTPUT.put_line ('<u>Message Counts in the Last ' || v_lookback || ' Minutes:</u><br/>');
    DBMS_OUTPUT.put_line ('Z01s ' || v_request || ' = ' || v_z01 || '<br/>');
    DBMS_OUTPUT.put_line ('Z02s ' || v_response || ' = ' || v_z02 || '<br/>');
    DBMS_OUTPUT.put_line ('Z03s ' || v_request || ' = ' ||  v_z03 || '<br/>');
    DBMS_OUTPUT.put_line ('Z04s ' || v_response || ' = ' ||  v_z04 || '<br/>');
    DBMS_OUTPUT.put_line ('Z05s ' || v_request || ' = ' ||  v_z05 || '<br/>');
    DBMS_OUTPUT.put_line ('Z06s ' || v_response || ' = ' ||  v_z06 || '<br/>');
    DBMS_OUTPUT.put_line ('Z07s ' || v_request || ' = ' ||  v_z07 || '<br/>');

 	v_introscope_data := 'Z01_' || v_request || '=' || to_char(v_z01) || ';';
 	v_introscope_data := v_introscope_data || 'Z02_' || v_response || '=' || to_char(v_z02) || ';';
 	v_introscope_data := v_introscope_data || 'Z03_' || v_request || '=' || to_char(v_z03) || ';';
 	v_introscope_data := v_introscope_data || 'Z04_' || v_response || '=' || to_char(v_z04) || ';';
 	v_introscope_data := v_introscope_data || 'Z05_' || v_request || '=' || to_char(v_z05) || ';';
 	v_introscope_data := v_introscope_data || 'Z06_' || v_response || '=' || to_char(v_z06) || ';';
 	v_introscope_data := v_introscope_data || 'Z07_' || v_request || '=' || to_char(v_z07);

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