SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

--setup
v_tz                    VARCHAR2(3):= '&1';
v_job_code              VARCHAR2(50) := '&2';
v_lookback              NUMBER := &3;    --this is the look back in minutes
v_last_known_status     VARCHAR2(5)  := '&4';
v_min_z01_cnt			NUMBER := &5;
v_min_z01_clearing_cnt  NUMBER := &6;

v_status                VARCHAR2(5)  := '';
v_subject               VARCHAR2(100)  := '';
v_msg                   VARCHAR2(200)  := '';

v_va_site               VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
v_mpi_site              VARCHAR2(50) := 'MPI-AUSTIN.MED.VA.GOV';
v_bypass				BOOLEAN := false;

edate                   DATE   := SYSTIMESTAMP;--central in CHDR 2.0
bdate                   DATE   := edate - (v_lookback/1440); --pass in the lookback in minutes

--query result variables
n_z01_cnt       NUMBER        := 0;
n_z02_cnt       NUMBER        := 0;
n_a24_cnt       NUMBER        := 0;
n_ack_cnt       NUMBER        := 0;
v_introscope_data	VARCHAR2(200) := 'NO_DATA';

BEGIN

    --retrieve the count of Z01s and ACK_A24 records received by VA for the period
    select nvl(sum(case when a.event_type = 'ZCH_Z01' then 1 else 0 end),0),
           nvl(sum(case when a.event_type = 'ACK_A24' then 1 else 0 end),0)
    into   n_z01_cnt, n_ack_cnt
    from   chdr2.audited_event a
    WHERE  a.created_date between bdate and edate
    and    a.receiving_site = v_va_site
    and    a.event_type in ('ZCH_Z01','ACK_A24')
    ;

    --retrieve the count of Z02s sent by VA to DoD
    --note: for some reason doing a select count(*) or adding in arguments to the received site and event type parameters in the where clause
    --caused these queries to run poorly and this change results in retrieval in seconds instead of minutes.
    select count(*) -- sum(case when a.event_type = 'ZCH_Z02' then 1 else 0 end)
    into   n_z02_cnt
    from   chdr2.audited_event a
    WHERE  a.created_date between bdate and edate
	and    a.sending_site = v_va_site    
    and    a.receiving_site = v_dod_site
    and    a.event_type = 'ZCH_Z02'
    ;
    
    --retrieve the count of A24s sent by VA to MPI
    --note: for some reason doing a select count(*) or adding in arguments to the received site and event type parameters in the where clause
    --caused these queries to run poorly and this change results in retrieval in seconds instead of minutes.
    select count(*) --sum(case when a.event_type = 'ADT_A24' then 1 else 0 end)
    into   n_a24_cnt
    from   chdr2.audited_event a
    WHERE  a.created_date between bdate and edate
--	and    a.sending_site = v_va_site    
--  and    a.receiving_site = v_mpi_site
    and    a.event_type = 'ADT_A24'
    ;

    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="output">');
    DBMS_OUTPUT.put_line ('<div class="output_display">');
	v_bypass := (n_z01_cnt >= v_min_z01_clearing_cnt and v_last_known_status = 'RED');

    if ((n_z01_cnt < v_min_z01_cnt) and v_bypass = false) then
       v_status := v_last_known_status;
       v_subject := 'MPI Bypass Alert! - Using Previous Status';
       v_msg := 'VA has not received enough Z01s from DoD (minimum Z01 count is ' || v_min_z01_cnt || ') and therefore, cannot determine the status of communications with MPI. The status reported is based on the last successful run.';
    else
        if (n_a24_cnt = 0) then
           v_status := 'RED';
           v_subject := 'MPI No A24 Alert!';
           v_msg := 'VA CHDR has received Z01s from DoD but has not requested any information from MPI (ADT_A24s) in the past ' || v_lookback || ' minutes.';
        else
           if (n_ack_cnt = 0) then
               v_status := 'RED';
               v_subject := 'MPI A24 Ack Alert!';
               v_msg := 'While VA CHDR has sent A24 messages to MPI, VA CHDR has not received any acknowledgements (A24_ACKs) in the past ' || v_lookback || ' minutes.';
            else
               v_status := 'GREEN';
               v_subject := 'VA CHDR to MPI Communication Restored';
               v_msg := 'VA CHDR has successfully sent A24 messages to MPI and has received acknowledgements in the past ' || v_lookback || ' minutes.';
            end if;
        end if;
    end if;

    if (v_status = 'RED') then
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__RED_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');        
        DBMS_OUTPUT.put_line ('SUBJECT: ' || v_subject);
        DBMS_OUTPUT.put_line ('<h4>' || v_subject || '</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');
    else
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
        DBMS_OUTPUT.put_line ('</span>');   
        DBMS_OUTPUT.put_line ('SUBJECT: ' || v_subject);
        DBMS_OUTPUT.put_line ('<h4>' || v_subject || '</h4><br/><br/>');
        DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
        DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
    end if;

    DBMS_OUTPUT.put_line (v_msg || '<br/><br/>');
    DBMS_OUTPUT.put_line ('Message Counts in the Last ' || v_lookback || ' Minutes:<br/>');
    DBMS_OUTPUT.put_line ('Z01s Received By VA = ' || n_z01_cnt || '<br/>');
    DBMS_OUTPUT.put_line ('Z02s Sent To DoD = ' || n_z02_cnt || '<br/>');
    DBMS_OUTPUT.put_line ('A24s Sent To MPI = ' || n_a24_cnt || '<br/>');
    DBMS_OUTPUT.put_line ('A24 Acks Received By VA = ' || n_ack_cnt || '<br/>');

	v_introscope_data := 'Z01_RCVD=' || to_char(n_z01_cnt) || ';A24_SENT=' || to_char(n_a24_cnt) || ';ACK_RCVD=' || to_char(n_ack_cnt)|| ';Z02_SENT=' || to_char(n_z02_cnt);
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
