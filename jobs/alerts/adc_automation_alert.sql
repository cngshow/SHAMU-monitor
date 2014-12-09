SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

v_tz                    VARCHAR2(3):= '&1';
v_job_code              VARCHAR2(50) := '&2';
v_lookback              NUMBER       := &3;    --this is the look back in minutes
v_low_water_mark        NUMBER := &4;
v_high_water_mark       NUMBER := &5;
v_lwm_clearing_cnt      NUMBER := &6;
v_hwm_clearing_cnt      NUMBER := &7;
v_last_run_status	VARCHAR2(50) := '&8';

v_clearing_alert	BOOLEAN := false;
v_va_site               VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
v_run_status            VARCHAR2(50) := 'NO_DATA';
v_introscope_data	VARCHAR2(200) := 'NO_DATA';
v_dod_adc_success_cnt   NUMBER := 0;
v_dod_adc_failure_cnt   NUMBER := 0;
edate                   DATE := sysdate;
bdate                   DATE := edate - (v_lookback/1440);

BEGIN
	if (v_last_run_status = 'NO_DATA') then
		v_run_status := 'GREEN';
	end if;

    SELECT nvl(sum(case when A.OUTCOME = 1 then 1 else 0 end),0) as success,
           nvl(sum(case when A.OUTCOME = 0 then 1 else 0 end),0) as failure
    INTO   v_dod_adc_success_cnt,
           v_dod_adc_failure_cnt 
    FROM   chdr2.audited_event a
    WHERE  a.created_date between bdate and edate
    AND    a.event_type = 'ZCH_Z01' 
    AND    a.sending_site = v_dod_site
    and    a.receiving_site = v_va_site
    and   A.ADDITIONAL_ID not in ('0011223366', --DoD test patients
                                  '0011223322',
                                  '0011223399',
                                  '0011223388',
                                  '0011223377',
                                  '0011223333',
                                  '0011223311',
                                  '0011223300')
    ;

    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="output">');
    DBMS_OUTPUT.put_line ('<div class="output_display">');
    
   if (((v_high_water_mark > 0 and v_low_water_mark > 0) and (v_high_water_mark < v_low_water_mark)) or 
   		(v_high_water_mark < 0 and v_low_water_mark < 0) ) then
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');        
        DBMS_OUTPUT.put_line ('SUBJECT: DOD AUTOMATION ALERT - Configuration Error!');
        DBMS_OUTPUT.put_line ('<h4>The low water mark is greater than the high water mark<br/>or both watermarks are negative!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
        v_run_status := 'CONFIGURATION_ERROR';
 	else 	
	    if ( ((v_dod_adc_success_cnt + v_dod_adc_failure_cnt) < v_low_water_mark) and (v_low_water_mark > 0) ) then
	        DBMS_OUTPUT.put_line ('<span class="status">');
	        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
	        DBMS_OUTPUT.put_line ('</span>');        
	        DBMS_OUTPUT.put_line ('SUBJECT: DOD AUTOMATION ALERT - Below low water mark!');
	        DBMS_OUTPUT.put_line ('<h4>DoD Patient Sharing Requests (Z01) received<br/>are below the low water mark of ' || v_low_water_mark || '</h4><br/><br/>');
	        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
	        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
	        v_run_status := 'LWM_RED';
	    elsif ( (v_dod_adc_success_cnt  + v_dod_adc_failure_cnt > v_high_water_mark) and (v_high_water_mark > 0) ) then
	        DBMS_OUTPUT.put_line ('<span class="status">');
	        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
	        DBMS_OUTPUT.put_line ('</span>');        
	        DBMS_OUTPUT.put_line ('SUBJECT: DOD AUTOMATION ALERT - Above high water mark!');
	        DBMS_OUTPUT.put_line ('<h4>DoD Patient Sharing Requests (Z01) received are<br/>above the high water mark of ' || v_high_water_mark || '</h4><br/><br/>');
	        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
	        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
	        v_run_status := 'HWM_RED';
	    else
	    	if (instr(v_last_run_status,'RED') > 0) then
	    		if (instr(v_last_run_status, 'LWM_') > 0) then
					if ( ((v_dod_adc_success_cnt + v_dod_adc_failure_cnt) < v_lwm_clearing_cnt)) then
				        DBMS_OUTPUT.put_line ('<span class="status">');
				        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
				        DBMS_OUTPUT.put_line ('</span>');        
				        DBMS_OUTPUT.put_line ('SUBJECT: DOD AUTOMATION ALERT - Below low water mark clearing count!');
				        DBMS_OUTPUT.put_line ('<h4>DoD Patient Sharing Requests (Z01) received are<br/>below the low water mark  clearing count of ' || v_lwm_clearing_cnt || '</h4><br/><br/>');
				        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
				        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
				        v_clearing_alert := true;
				        v_run_status := 'LWM_RED_CLEARING';
					end if;
	    		else
					if ( ((v_dod_adc_success_cnt + v_dod_adc_failure_cnt) > v_hwm_clearing_cnt)) then
				        DBMS_OUTPUT.put_line ('<span class="status">');
				        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
				        DBMS_OUTPUT.put_line ('</span>');        
				        DBMS_OUTPUT.put_line ('SUBJECT: DOD AUTOMATION ALERT - Above high water mark clearing count!');
				        DBMS_OUTPUT.put_line ('<h4>DoD Patient Sharing Requests (Z01) received are<br/>above the high water mark clearing count of ' || v_hwm_clearing_cnt || '</h4><br/><br/>');
				        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
				        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
				        v_clearing_alert := true;
				        v_run_status := 'HWM_RED_CLEARING';
		    		end if;
		    	end if;
	    	end if;

			if (v_clearing_alert = false) then	    	
		        DBMS_OUTPUT.put_line ('<span class="status">');
		        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
		        DBMS_OUTPUT.put_line ('</span>');   
		        DBMS_OUTPUT.put_line ('SUBJECT: DOD AUTOMATION ALERT - SUCCESS!!');
		        DBMS_OUTPUT.put_line ('<h4>DOD PATIENT SHARING REQUESTS (Z01) RECEIVED SUCCESSFULLY!!</h4><br/><br/>');
		        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
		        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
		        DBMS_OUTPUT.put_line ('The count of Z01s received is within the expected parameters.<br/>');
		        v_run_status := 'GREEN';
			end if;
	    end if;
	
	    DBMS_OUTPUT.put_line ('The results of the query are (in the last ' || v_lookback || ' minutes):<br/><br/>');
	    DBMS_OUTPUT.put_line ('Z01 Successful ADC Count = ' || v_dod_adc_success_cnt || '<br/>');
	    DBMS_OUTPUT.put_line ('Z01 Failure ADC Count = ' || v_dod_adc_failure_cnt || '<br/><br/><br/>');
	    
	    if (v_low_water_mark > 0) then
   	    	DBMS_OUTPUT.put_line ('The low water mark is ' || v_low_water_mark || '.<br/>');
   	    end if;
   	    
	   	if (v_lwm_clearing_cnt > 0) then
	  	    DBMS_OUTPUT.put_line ('The low water mark clearing is ' || v_lwm_clearing_cnt || '.<br/>');
		end if;
		
	    if (v_high_water_mark > 0) then
	   	    DBMS_OUTPUT.put_line ('The high water mark is ' || v_high_water_mark || '.<br/>');
	   	end if;
	   	
	   	if (v_hwm_clearing_cnt > 0) then
   	    	DBMS_OUTPUT.put_line ('The high water mark clearing is ' || v_hwm_clearing_cnt || '.<br/>');
		end if;
	end if;
	
    v_introscope_data := 'Z01_received_success=' || to_char(v_dod_adc_success_cnt) || ';Z01_received_failure=' || to_char(v_dod_adc_failure_cnt);
    DBMS_OUTPUT.put_line ('<span class="status">');
    DBMS_OUTPUT.put_line ('RUN_DATA_BEGIN_' || v_run_status || '_RUN_DATA_END<br>');
    DBMS_OUTPUT.put_line ('</span>');   
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
