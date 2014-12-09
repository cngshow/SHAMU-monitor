SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off

-- define local vars --
DECLARE

--setup
v_tz                    VARCHAR2(3):= '&1';
v_job_code              VARCHAR2(50) := '&2';
v_last_known_status     VARCHAR2(5)  := '&3';
v_lookback              NUMBER := &4; -- lookback in minutes
edate                   DATE   := sysdate;
bdate                   DATE   := edate - (v_lookback/1440);
v_pct_ratio             NUMBER := &5;

--place holder variables for script
v_status                VARCHAR2(5)  := '';
v_subject               VARCHAR2(100)  := '';
v_msg                   VARCHAR2(2000)  := '';

v_va_site               VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
v_adt_a24               VARCHAR2(7) := 'ADT_A24';
v_ack_a24               VARCHAR2(7) := 'ACK_A24';

--query result variables
n_a24_cnt       NUMBER        := 0;
n_ack_cnt       NUMBER        := 0;
v_introscope_data    VARCHAR2(200) := 'NO_DATA';

BEGIN
  select sum(nvl(case when A.SENDING_SITE = v_va_site and A.EVENT_TYPE = v_adt_a24 then 1 else 0 end,0)) as vha_a24,
         sum(nvl(case when A.SENDING_SITE = v_dod_site and A.EVENT_TYPE = v_ack_a24 then 1 else 0 end,0)) as dod_ack
  into   n_a24_cnt, n_ack_cnt
  from   chdr2.audited_event a
  WHERE  a.created_date between bdate and edate
  and    a.event_type in (v_adt_a24,v_ack_a24)
  and    a.sending_site in (v_va_site,v_dod_site)
  and    a.receiving_site in (v_va_site,v_dod_site);

    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="output">');
    DBMS_OUTPUT.put_line ('<div class="output_display">');

--n_a24_cnt := 111;
--n_ack_cnt := 1;

    --if the there are no a24s then use the previous status
    if (n_a24_cnt = 0) then
       v_status := v_last_known_status;
       v_subject := 'DOD to VA A24_ACK Alert!';
       v_msg := 'DOD has not received any A24s from VA. The status reported is based on the last successful run.';
    else
       if (n_ack_cnt = 0) then
          v_status := 'RED';
          v_subject := 'DOD to VA A24_ACK Alert!';
          v_msg := 'While DOD has received A24 messages from VA, DOD CHDR has not sent any acknowledgements (A24_ACKs) back to VA.';
       else
          if (round((n_ack_cnt/n_a24_cnt)*100, 0) < v_pct_ratio) then
            v_status := 'RED';
            v_subject := 'DOD to VA A24_ACK Alert!';
            v_msg := 'While DOD has received A24 messages from VA, DOD CHDR has not sent enough acknowledgements (A24_ACKs) back to VA based on the alert configuration. This alert goes RED when the response ratio is less than ' || to_char(v_pct_ratio) || '%. The current response ratio is ' || round((n_ack_cnt/n_a24_cnt)*100, 0) || '%.';
          else
            v_status := 'GREEN';
            v_subject := 'DOD to VA A24_ACK Restored!';
            v_msg := 'DOD CHDR has successfully sent A24_ACK messages to VA.';
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
    DBMS_OUTPUT.put_line ('A24s Sent By VA To DOD = ' || n_a24_cnt || '<br/>');
    DBMS_OUTPUT.put_line ('A24 ACKs Sent By DOD to VA = ' || n_ack_cnt || '<br/>');

    v_introscope_data := 'VA_TO_DOD_A24=' || to_char(n_a24_cnt) || ';DOD_TO_VA_ACK=' || to_char(n_ack_cnt);
    DBMS_OUTPUT.put_line ('<span class="status">');
    DBMS_OUTPUT.put_line ('INTROSCOPE_DATA_BEGIN_' || v_introscope_data || '_INTROSCOPE_DATA_END<br>');
    DBMS_OUTPUT.put_line ('</span>');

    DBMS_OUTPUT.put_line ('<br/>--------<br/>');
    DBMS_OUTPUT.put_line ('Begin Date (' || v_tz || ') = ' || to_char(bdate, 'DD-MON-YYYY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('End Date (' || v_tz || ') = ' || to_char(edate, 'DD-MON-YYYY HH24:MI:SS') || '<br/>');
    DBMS_OUTPUT.put_line ('<span class="job_code">(' || v_job_code || ')</span>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('</div><br><br>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');

END;
/
disconnect;
exit;
