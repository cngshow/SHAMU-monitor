SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

v_tz                    VARCHAR2(3):= '&1';
v_job_code              VARCHAR2(50) := '&2';
v_lookback              NUMBER := &3;    --this is the look back in minutes

edate                   DATE   := sysdate;--central in CHDR 2.0
bdate                   DATE   := edate - ((v_lookback/60)/24); --pass in the minutes and it is calculated to hours
v_Z03_S_Total           NUMBER := 0;
v_Z04_R_Total           NUMBER := 0;
v_dod_z03_cnt           NUMBER := 0;
v_Z03_R_From_HDR        NUMBER := 0;
v_pct                   NUMBER := 0;
v_Z03_Check_Count       NUMBER := 50;
v_Check_Pct             NUMBER := 80;
v_dod_adc_success_cnt   NUMBER := 0;
v_dod_adc_failure_cnt   NUMBER := 0;
v_status                VARCHAR2(20) := 'green_light';
v_bypass                VARCHAR2(5)  := 'true';
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
v_va_site               VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_hdr_site              VARCHAR2(50) := 'HDR.MED.VA.GOV';

BEGIN

    --retrieve the counts of Z03 and Z04 messages sent and received by VA
    select sum(z03Sent), sum(z04Rcvd)
    into v_Z03_S_Total, v_Z04_R_Total
    From (
        SELECT count(distinct a.message_id) as z03Sent, 0 as z04Rcvd
        FROM    chdr2.AUDITED_EVENT a
        WHERE   a.created_date between bdate and edate
        and     a.event_type in ('FILL','ALGY','CHEM','PRES')
        and     a.sending_site = v_va_site
        and     a.outcome = 1
        union
        SELECT 0 as z03Sent, count(distinct a.message_id) as z04Rcvd
        FROM    chdr2.AUDITED_EVENT a
        WHERE   a.created_date between bdate and edate
        and     a.event_type = 'ZCH_Z04'
        and     a.sending_site = v_dod_site
        and     a.receiving_site = v_va_site
        and     a.outcome = 1
    );
  
    DBMS_OUTPUT.put_line ('********* RUNNING JOB: ' || v_job_code || ' ********* START<br/>');
    DBMS_OUTPUT.put_line ('Z03 Count=' || v_Z03_S_Total || '<br/>');
    DBMS_OUTPUT.put_line ('Z04 Count=' || v_Z04_R_Total || '<br/>');

    if (v_Z03_S_TOTAL > 0) then
        --check the z03 against the z04 counts
        v_pct := ((v_Z04_R_Total - v_Z03_S_Total) / v_Z03_S_Total) * 100;
        DBMS_OUTPUT.put_line ('Ratio Pct=' || v_pct || '<br/>');
    else
        DBMS_OUTPUT.put_line ('Ratio Pct cannot be calculated as zero Z03s were sent.<br/>');
    end if;
    
    DBMS_OUTPUT.put_line ('EMAIL_RESULT_BELOW:');
    DBMS_OUTPUT.put_line ('<html>');
    DBMS_OUTPUT.put_line ('<head>');
    DBMS_OUTPUT.put_line ('<style type="text/css">');
    DBMS_OUTPUT.put_line ('html, body {color:navy; margin:2; padding:2; background:#fff;font-family: "Courier New" Courier monospace;}');
    DBMS_OUTPUT.put_line ('h4 {text-align: center;text-decoration: underline; font-size: 12pt}');
    DBMS_OUTPUT.put_line ('span.red_light{font-size: 10pt; color:red;}');
    DBMS_OUTPUT.put_line ('span.green_light{font-size: 10pt; color:green;}');
    DBMS_OUTPUT.put_line ('span.job_code {text-align: left; font-size: 8pt; color:gray;}');
    DBMS_OUTPUT.put_line ('span.status{display: none;}');
    DBMS_OUTPUT.put_line ('div.output{font-size: 10pt; color:navy; border: 1px gray solid}');
    DBMS_OUTPUT.put_line ('</style>');
    DBMS_OUTPUT.put_line ('</head>');
    DBMS_OUTPUT.put_line ('<body>');
    DBMS_OUTPUT.put_line ('<div class="output" width="650px">');

/*
TO CHECK FOR DUPLICATION...
    select message_id, count(*)
    from chdr.audited_event a
    WHERE   a.created_date between bdate and edate
    and  z04 from dod to va
    group by message_id
    having count(*) > 1;
*/
    --check that we have messages flowing
    if (v_Z03_S_Total > 0 and v_Z04_R_Total > 0) then
        --check that we are NOT duplicating messages
        if ( (v_Z03_S_Total < v_Z03_Check_Count and v_Z04_R_Total >= 100) or --check this logic
             (v_pct > v_Check_Pct and v_Z03_S_Total > v_Z03_Check_Count) ) then
            v_status := 'red_light';
        end if;
    else
        --we are not sending and/or receiving clinical messages
        v_status := 'red_light';
    end if;

    if (v_status = 'green_light') then
        v_bypass := 'false';
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');   
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Message Traffic Restored!');
        DBMS_OUTPUT.put_line ('<h4>CHDR Message Traffic Restored!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
        DBMS_OUTPUT.put_line ('Message traffic has been restored with clinical messages being sent and received successfully.<br/><br/>');
        DBMS_OUTPUT.put_line ('The results of the query are:<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Counts in the Last ' || v_lookback || ' Minutes:<br/>');
        DBMS_OUTPUT.put_line ('Z03 Sent By VA = ' || v_Z03_S_Total || '<br/>');
        DBMS_OUTPUT.put_line ('Z04 Rcvd By VA = ' || v_Z04_R_Total || '<br/>');
        DBMS_OUTPUT.put_line ('Ratio Pct = ' || v_pct || '<br/>');
    else
        if (v_job_code = 'DUPLICATION_CHECK') then
            if (v_Z03_S_Total > 0 and
               ((v_Z03_S_Total < v_Z03_Check_Count and v_Z04_R_Total >= 100) or
                (v_pct > v_Check_Pct and v_Z03_S_Total > v_Z03_Check_Count))) then
                v_bypass := 'false';
                DBMS_OUTPUT.put_line ('<span class="status">');
                DBMS_OUTPUT.put_line ('__RED_LIGHT__');
                DBMS_OUTPUT.put_line ('</span>');        
                DBMS_OUTPUT.put_line ('SUBJECT: CHDR Message Duplication Alert!');
                DBMS_OUTPUT.put_line ('<h4>CHDR Message Duplication Alert!</h4><br/><br/>');
                DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
                DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
                DBMS_OUTPUT.put_line ('The VIE may be sending duplicate messages to VA CHDR. If the CHDR application has recently been recycled then this duplication may be an expected event.<br/><br/>');
                DBMS_OUTPUT.put_line ('The usual corrective action is to restart the VIE.<br/><br/>');
                DBMS_OUTPUT.put_line ('The results of the query are:<br/><br/>');
                DBMS_OUTPUT.put_line ('Message Count Showing Duplication in the Last ' || v_lookback || ' Minutes:<br/>');
                DBMS_OUTPUT.put_line ('Z03 Sent By VA = ' || v_Z03_S_Total || '<br/>');
                DBMS_OUTPUT.put_line ('Z04 Rcvd By VA = ' || v_Z04_R_Total || '<br/>');
                DBMS_OUTPUT.put_line ('Ratio Pct = ' || v_pct || '<br/>');
            end if;
        elsif (v_job_code in ('NO_DOD_TRAFFIC', 'NO_Z04_MESSAGES_RECEIVED')) then
           if (v_Z03_S_Total > 0 and v_Z04_R_Total = 0) then
                --check to see if we have received any Z03 messages from DoD
                SELECT count(*) as z03
                INTO   v_dod_z03_cnt
                FROM    chdr2.AUDITED_EVENT a
                WHERE   a.created_date between bdate and edate
                and     a.event_type in ('FILL','ALGY','CHEM','PRES')
                and     a.sending_site = v_dod_site
                and     a.outcome = 1
                ;

                --check DoD Z03 counts - if zero then we have not received any traffic
                if (v_dod_z03_cnt = 0) then
                    if (v_job_code = 'NO_DOD_TRAFFIC') then
                        v_bypass := 'false';
                        DBMS_OUTPUT.put_line ('<span class="status">');
                        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
                        DBMS_OUTPUT.put_line ('</span>');        
                        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Message Traffic Alert! - No Traffic from DoD (Z03/Z04)');
                        DBMS_OUTPUT.put_line ('<h4>CHDR Message Traffic Alert! - No Traffic from DoD (Z03/Z04)</h4><br/><br/>');
                        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
                        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
                        DBMS_OUTPUT.put_line ('VA CHDR has not received any Z03 or Z04 messages in the last ' || v_lookback || ' minutes from DOD.<br/>');
                        DBMS_OUTPUT.put_line ('This may indicate an issue on the DoD side or issues with the VIE handling messages from DOD to VA.<br/><br/>');
                        DBMS_OUTPUT.put_line ('Please notify the DoD team if it appears that the VA VIE is processing messages correctly.<br/><br/>');
                        DBMS_OUTPUT.put_line ('The results of the query are:<br/><br/>');
                        DBMS_OUTPUT.put_line ('Z03 Sent by VA = ' || v_Z03_S_Total || '<br/>');
                        DBMS_OUTPUT.put_line ('Z04 Rcvd By VA = 0<br/>');
                        DBMS_OUTPUT.put_line ('Z03 Sent by DoD = 0<br/>');
                    end if;
                else
                    if (v_job_code = 'NO_Z04_MESSAGES_RECEIVED') then
                        v_bypass := 'false';
                        DBMS_OUTPUT.put_line ('<span class="status">');
                        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
                        DBMS_OUTPUT.put_line ('</span>');        
                        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Message Traffic Alert! - No Z04s Sent by DoD');
                        DBMS_OUTPUT.put_line ('<h4>CHDR Message Traffic Alert! - No Z04s Sent by DoD</h4><br/><br/>');
                        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
                        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
                        DBMS_OUTPUT.put_line ('VA CHDR has been receiving ZO3 messages from DoD but not ZO4 messages over the last ' || v_lookback || ' minutes.<br/><br/>');
                        DBMS_OUTPUT.put_line ('This may indicate issues on the DoD side or issues with DoD to VA messages with the VA VIE.<br/><br/>');
                        DBMS_OUTPUT.put_line ('Please notify the DoD team if it appears that the VA VIE is processing messages correctly.<br/><br/>');
                        DBMS_OUTPUT.put_line ('The results of the query are:<br/><br/>');
                        DBMS_OUTPUT.put_line ('Z03 Sent By VA = ' || v_Z03_S_Total || '<br/>');
                        DBMS_OUTPUT.put_line ('Z04 Rcvd By VA = ' || v_Z04_R_Total || '<br/>');
                    end if;
                end if;
           end if;
        elsif (v_job_code in ('NO_Z03_VISTA_MESSAGES_SENT_TO_DOD','NO_TRAFFIC_ALERT')) then -- modify this section
            if (v_Z03_S_Total = 0) then
                select count(*) 
                into   v_Z03_R_From_HDR
                FROM    chdr2.AUDITED_EVENT a
                WHERE   a.created_date between bdate and edate
                and     a.event_type in ('HDRALGY', 'HDRPRES', 'HDRPPAR', 'LA7LAB', 'HDRPREF')
                and     a.sending_site = v_hdr_site -- what is the code for the HDR as the sending site?
                and     a.outcome = 1
                
                -- HDRALGY, HDRPRES, HDRPPAR, LA7LAB, HDRPREF - CATEGORY Application Types previously - why do we only have 4 types?
                ;

                if (v_Z03_R_From_HDR > 0) then
                    if (v_job_code = 'NO_Z03_VISTA_MESSAGES_SENT_TO_DOD') then
                        v_bypass := 'false';
                        DBMS_OUTPUT.put_line ('<span class="status">');
                        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
                        DBMS_OUTPUT.put_line ('</span>');        
                        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Message Traffic Alert! - VA CHDR cannot forward Z03s to DoD!');
                        DBMS_OUTPUT.put_line ('<h4>CHDR Message Traffic Alert! - VA CHDR has been unable to forward Z03s to DoD!</h4><br/><br/>');
                        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
                        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
                        DBMS_OUTPUT.put_line ('VA CHDR has received Z03 messages from VistA in the last ' || v_lookback || ' minutes. However, CHDR has not sent any Z03s to DoD during the same time period.<br/><br/>');
                        DBMS_OUTPUT.put_line ('In the past this has indicated that the app2 interface engine server needs to be recycled in order to resume traffic to DoD.<br/><br/>');
                        DBMS_OUTPUT.put_line ('The results of the query are:<br/><br/>');
                        DBMS_OUTPUT.put_line ('Z03 Sent By VA = ' || v_Z03_S_Total || '<br/>');
                        DBMS_OUTPUT.put_line ('Z04 Rcvd By VA = ' || v_Z04_R_Total || '<br/>');
                    end if;
                else
                	if (v_job_code = 'NO_TRAFFIC_ALERT') then
	                    --There has been NO traffic at all
	                    v_bypass := 'false';
	                    DBMS_OUTPUT.put_line ('<span class="status">');
	                    DBMS_OUTPUT.put_line ('__RED_LIGHT__');
	                    DBMS_OUTPUT.put_line ('</span>');        
	                    DBMS_OUTPUT.put_line ('SUBJECT: CHDR Message Traffic Alert! - There has been no CHDR Traffic!');
	                    DBMS_OUTPUT.put_line ('<h4>CHDR Message Traffic Alert! - There has been No CHDR Traffic!</h4><br/><br/>');
	                    DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
	                    DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
	                    DBMS_OUTPUT.put_line ('VA CHDR has not received any clinical messages from VistA or DoD in the last ' || v_lookback || ' minutes.<br/><br/>');
	                    DBMS_OUTPUT.put_line ('The results of the query are:<br/><br/>');
	                    DBMS_OUTPUT.put_line ('Z03 Sent By VA = ' || v_Z03_S_Total ||'<br/>');
	                    DBMS_OUTPUT.put_line ('Z04 Rcvd By VA = ' || v_Z04_R_Total || '<br/>');
	                    DBMS_OUTPUT.put_line ('Z03 Rcvd From HDR = ' || v_Z03_R_From_HDR || '<br/>');
	                end if;
	            end if;
            end if;
        end if;
    end if;

    if (v_bypass = 'true') then
        -- if v_bypass is true then we are in RED status but the job being run is not sending the alert so we are
        --writing a green light for this job as the job result
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');   
        DBMS_OUTPUT.put_line ('SUBJECT: CHDR Bypass Alert!');
        DBMS_OUTPUT.put_line ('<h4>CHDR Bypass Alert!</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('An alert is being sent for a disruption of message flow. However the <b>(' || v_job_code || ')</b> job did not cause the alert to fire. Therefore, this check is being marked as a <span class="green_light">green light</span>.<br/><br/>');
        DBMS_OUTPUT.put_line ('The results of the query are:<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Counts in the Last ' || v_lookback || ' Minutes:<br/>');
        DBMS_OUTPUT.put_line ('Z03 Sent By VA = ' || v_Z03_S_Total || '<br/>');
        DBMS_OUTPUT.put_line ('Z04 Rcvd By VA = ' || v_Z04_R_Total || '<br/>');
    end if;

    DBMS_OUTPUT.put_line ('<br/>--------<br/>');
    DBMS_OUTPUT.put_line ('Begin Date (' || v_tz || ') = ' || to_char(bdate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('End Date (' || v_tz || ') = ' || to_char(edate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('<span class="job_code">(' || v_job_code || ')</span><br/><br/>');
    DBMS_OUTPUT.put_line ('</div></body></html>');
    DBMS_OUTPUT.put_line ('EMAIL_RESULT_ABOVE:');
    DBMS_OUTPUT.put_line ('<br/>********* RUNNING JOB: ' || v_job_code || ' ********* END<br/>');
END;
/
disconnect;
exit;
