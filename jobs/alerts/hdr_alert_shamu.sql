SET serveroutput on
SET linesize 10000
SET ECHO OFF
set verify off
alter session set global_names=false;

-- define local vars --
DECLARE

--setup
v_tz                    VARCHAR2(3)  := '&1';
v_job_code              VARCHAR2(50) := '&2';
v_lookback              NUMBER       := &3;    --this is the look back in minutes
v_last_known_status     VARCHAR2(5)  := '&4';
v_percent_written       NUMBER       := &5; --this is a number from 1 to 100 that is the minimum acceptable percentage of records audited to messages written
v_clearing_pct          NUMBER       := &6; --this is a number from 1 to 100 that is the minimum acceptable clearing percentage when we are clearing to green
v_low_water_mark        NUMBER       := &7; -- this is the low water mark. We will report the last known status if we are below this number

v_calc_pct_written      NUMBER       := 0;
v_status                VARCHAR2(5)  := '';
v_vha_site              VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';

bdate                   DATE := to_date('&8','yyyymmddhh24mi');
edate                   DATE := to_date('&9','yyyymmddhh24mi');
v_hdr_write_check       VARCHAR2(10) := '&10';
n_hdr_writes_cnt        NUMBER        := &11;

--query result variables
n_last_audit_write      DATE := null;
n_hdr_audit_cnt         NUMBER        := 0;
v_introscope_data       VARCHAR2(200) := 'NO_DATA';
v_lookback_hours        NUMBER       := 3;

BEGIN

    --retrieve the count of audited records in CHDR for the period
    select count(*)
    into   n_hdr_audit_cnt
    from   chdr2.audited_event a
    WHERE  a.created_date  between bdate and edate
    and    a.event_type in ('FILL','ALGY')
    and    a.sending_site = v_dod_site
    and    a.receiving_site = v_vha_site
    ;

    --retrieve the last audited record sent to HDR
    select max(a.created_date)
    into   n_last_audit_write
    from   chdr2.audited_event a
    WHERE  a.created_date between bdate - (v_lookback_hours/24) and edate -- due to performance issues we are looking back 3 hours to ensure that we get a last write record
    and    a.event_type in ('FILL','ALGY')
    and    a.sending_site = v_dod_site
    and    a.receiving_site = v_vha_site
    ;

    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');

    if (v_hdr_write_check = 'SUCCESS') then
        DBMS_OUTPUT.put_line ('<div class="output">');
        DBMS_OUTPUT.put_line ('<div class="output_display">');

        if (n_hdr_audit_cnt <= v_low_water_mark) then
           v_status := v_last_known_status;
        else
            if (n_hdr_writes_cnt = 0) then
                v_status := 'RED';
            else
                v_calc_pct_written := (n_hdr_writes_cnt/n_hdr_audit_cnt) * 100;

                if (v_calc_pct_written < v_percent_written) then
                    v_status := 'RATIO';
                else
                    if (v_calc_pct_written < v_clearing_pct and v_last_known_status = 'RED') then
                        v_status := 'CLEARING';
                    else
                        v_status := 'GREEN';
                    end if;
                   end if;
            end if;
        end if;

        if (v_status != 'GREEN') then
            --red light (no writes in x minutes)
            DBMS_OUTPUT.put_line ('<span class="status">');
            DBMS_OUTPUT.put_line ('__RED_LIGHT__');
            DBMS_OUTPUT.put_line ('</span>');
            DBMS_OUTPUT.put_line ('SUBJECT: CHDR Writes to HDR Alert!');
            DBMS_OUTPUT.put_line ('<h4>CHDR Writes to HDR Alert!</h4><br/><br/>');
            DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
            DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="red_light">RED LIGHT</span><br/><br/>');

            if (v_status = 'RED') then
                DBMS_OUTPUT.put_line ('The VA CHDR application has not written any clinical messages to the HDR in the past ' || v_lookback || ' Minutes.<br/><br/>');
            elsif (v_status = 'RATIO') then
                DBMS_OUTPUT.put_line ('In the past ' || v_lookback || ' minutes VA CHDR has audited ' || n_hdr_audit_cnt || ' Z03s from DoD but have only written ' || n_hdr_writes_cnt || ' into the HDR. We require that at least ' || v_percent_written || '% of audited messages be written into the HDR within the reporting period. The percentage of audited messages to HDR writes is ' || round(v_calc_pct_written,2) || '%.<br/><br/>');
            elsif (v_status = 'CLEARING') then
                DBMS_OUTPUT.put_line ('In the past ' || v_lookback || ' minutes VA CHDR has audited ' || n_hdr_audit_cnt || ' Z03s from DoD but and has written ' || n_hdr_writes_cnt || ' into the HDR. We require that at least ' || v_clearing_pct || '% of audited messages be written into the HDR within the reporting period in order to clear this alert. The percentage of audited messages to HDR writes is ' || round(v_calc_pct_written,2) || '%.<br/><br/>');
            end if;
        else
            DBMS_OUTPUT.put_line ('<span class="status">');
            DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
            DBMS_OUTPUT.put_line ('</span>');
            DBMS_OUTPUT.put_line ('SUBJECT: CHDR Message Traffic with HDR Restored!');
            DBMS_OUTPUT.put_line ('<h4>CHDR Message Traffic with HDR Restored!</h4><br/><br/>');
            DBMS_OUTPUT.put_line ('This is an automated e-mail message.<br/><br/>');
            DBMS_OUTPUT.put_line ('Message Traffic Alert:  <span class="green_light">GREEN LIGHT</span><br/><br/>');
            DBMS_OUTPUT.put_line ('Message traffic with HDR has been restored.<br/><br/>');
        end if;

        DBMS_OUTPUT.put_line ('Message Counts in the Last ' || v_lookback || ' Minutes:<br/>');
        DBMS_OUTPUT.put_line ('Z03 Messages Received from DoD = ' || n_hdr_audit_cnt || '<br/>');
        DBMS_OUTPUT.put_line ('Messages Written to HDR = ' || n_hdr_writes_cnt || '<br/>');
        DBMS_OUTPUT.put_line ('Percent Written to HDR = ' || round(v_calc_pct_written,0) || '%<br/>');
        DBMS_OUTPUT.put_line ('Alerting Percentage = ' || v_percent_written || '%<br/>');
        DBMS_OUTPUT.put_line ('Clearing Percentage = ' || v_clearing_pct || '%<br/>');
        DBMS_OUTPUT.put_line ('Low Water Mark Count = ' || v_low_water_mark || '<br/>');

        if (n_last_audit_write is not null) then
            DBMS_OUTPUT.put_line ('Last Audited Z03 Message Written (' || v_tz || ') = ' || to_char(n_last_audit_write, 'DD-MON-YY HH24:MI:SS') || '<br/>');
        end if;

        v_introscope_data := 'hdr_audit=' || to_char(n_hdr_audit_cnt) || ';hdr_write=' || to_char(n_hdr_writes_cnt);
        DBMS_OUTPUT.put_line ('<span class="status">');
        DBMS_OUTPUT.put_line ('INTROSCOPE_DATA_BEGIN_' || v_introscope_data || '_INTROSCOPE_DATA_END<br>');
        DBMS_OUTPUT.put_line ('</span>');
        DBMS_OUTPUT.put_line ('<br/>--------<br/>');
        DBMS_OUTPUT.put_line ('Begin Date (' || v_tz || ') = ' || to_char(bdate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
        DBMS_OUTPUT.put_line ('End Date (' || v_tz || ') = ' || to_char(edate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
        DBMS_OUTPUT.put_line ('<span class="job_code">(' || v_job_code || ')</span>');
        DBMS_OUTPUT.put_line ('</div>');
        DBMS_OUTPUT.put_line ('</div><br><br>');
    else
        DBMS_OUTPUT.put_line ('HDR writes check failed.  Could not get data from Introscope.');
    end if;

    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');

END;
/
disconnect;
exit;