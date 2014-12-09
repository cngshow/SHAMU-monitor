SET serveroutput on
SET ECHO OFF
set verify off

-- define local vars --

DECLARE

v_start_date     VARCHAR2(8) := '&1'; -- a date passed in as yyyymmdd
v_lookback_days  NUMBER := &2;    --this is the look back in days
v_tz_offset      NUMBER := &3;
v_tz             VARCHAR2(3):= '&4';
bdate            DATE := to_date(v_start_date,'yyyymmdd') - v_lookback_days;
edate            DATE := bdate + v_lookback_days;

v_greenbar    NUMBER := 0;
v_Z01_S_Total NUMBER := 0;
v_Z02_S_Total NUMBER := 0;
v_Z03_S_Total NUMBER := 0;
v_Z04_S_Total NUMBER := 0;
v_Z05_S_Total NUMBER := 0;
v_Z06_S_Total NUMBER := 0;
v_Z07_S_Total NUMBER := 0;
v_Z01_R_Total NUMBER := 0;
v_Z02_R_Total NUMBER := 0;
v_Z03_R_Total NUMBER := 0;
v_Z04_R_Total NUMBER := 0;
v_Z05_R_Total NUMBER := 0;
v_Z06_R_Total NUMBER := 0;
v_Z07_R_Total NUMBER := 0;
v_A24_S_total NUMBER := 0;
v_ACK_R_total NUMBER := 0;

v_va_site     VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
v_dod_site    VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';

-- messages received and sent by VA
CURSOR curRcvdSent IS
    select hr,
           sum(Z01) as Z01_r,
           sum(Z02) as Z02_s,
           sum(Z03) as Z03_r,
           sum(Z04) as Z04_s,
           sum(Z05) as Z05_r,
           sum(Z06) as Z06_s,
           sum(Z07) as Z07_r
    from (
        SELECT to_char(a.created_date,'YYYYMMDDHH24') as hr,
               sum(case a.event_type when 'ZCH_Z01' then 1 else 0 end) as Z01,
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
        group by to_char(a.created_date,'YYYYMMDDHH24')

        UNION

        SELECT to_char(a.created_date,'YYYYMMDDHH24') as hr,
               0 as Z01,
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
        group by to_char(a.created_date,'YYYYMMDDHH24')
        )
    group by hr
    order by hr
;

-- messages sent and received by VA
CURSOR curSentRcvd IS
    select hr,
           sum(Z01) as Z01_s,
           sum(Z02) as Z02_r,
           sum(Z03) as Z03_s,
           sum(Z04) as Z04_r,
           sum(Z05) as Z05_s,
           sum(Z06) as Z06_r,
           sum(Z07) as Z07_s,
           sum(A24) as A24_s,
           sum(ACK) as ACK_r
    from (
        SELECT to_char(a.created_date,'YYYYMMDDHH24') as hr,
               sum(case a.event_type when 'ZCH_Z01' then 1 else 0 end) as Z01,
               0 as Z02,
               sum(case when a.event_type in ('FILL','CHEM','PRES','ALGY') then 1 else 0 end) as Z03,
               0 as Z04,
               sum(case a.event_type when 'QBP_Z05' then 1 else 0 end) as Z05,
               0 as Z06,
               sum(case a.event_type when 'ZCH_Z07' then 1 else 0 end) as Z07,
               0 as A24,
               0 as ACK
        FROM   chdr2.audited_event a
        WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
        and    a.created_date BETWEEN bdate AND edate
        and    a.sending_site = v_va_site
        and    a.receiving_site = v_dod_site
        group by to_char(a.created_date,'YYYYMMDDHH24')

        UNION ALL

        SELECT to_char(a.created_date,'YYYYMMDDHH24') as hr,
               0 as Z01,
               sum(case a.event_type when 'ZCH_Z02' then 1 else 0 end) as Z02,
               0 as Z03,
               sum(case a.event_type when 'ZCH_Z04' then 1 else 0 end) as Z04,
               0 as Z05,
               sum(case a.event_type when 'RSP_Z06' then 1 else 0 end) as Z06,
               0 as Z07,
               0 as A24,
               0 as ACK
        FROM   chdr2.audited_event a
        WHERE  a.EVENT_TYPE in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
        and    a.created_date BETWEEN bdate AND edate
        and    a.sending_site = v_dod_site
        and    a.receiving_site = v_va_site
        group by to_char(a.created_date,'YYYYMMDDHH24')

        UNION ALL

        SELECT to_char(a.created_date,'YYYYMMDDHH24') as hr,
               0 as Z01,
               0 as Z02,
               0 as Z03,
               0 as Z04,
               0 as Z05,
               0 as Z06,
               0 as Z07,
               sum(case a.event_type when 'ADT_A24' then 1 else 0 end) as A24,
               sum(case a.event_type when 'ACK_A24' then 1 else 0 end) as ACK
         FROM  chdr2.audited_event a
        WHERE  a.EVENT_TYPE in ('ADT_A24','ACK_A24')
        and    a.created_date BETWEEN bdate AND edate
        group by to_char(a.created_date,'YYYYMMDDHH24')
        )
    group by hr
    order by hr
;

BEGIN
    if (v_lookback_days = 0) then
        bdate := trunc(sysdate);
        edate := sysdate;
    end if;

    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="rpt">');
    -- end - html output template

    DBMS_OUTPUT.put_line ('<h4>VA CHDR Hourly Messages Received -> Sent<br>Activity for ' || to_char(bdate, 'Month dd, yyyy') || '</h4>');
    DBMS_OUTPUT.put_line ('<div class="section">Hourly Breakdown of Messages (Reported in Central Time)</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing=0>');
    DBMS_OUTPUT.put_line ('<tr><th width="16%"><br>Date/Hour</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z01<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z02<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z03<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z04<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z05<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z06<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z07<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curRcvdSent Loop
        if (MOD(v_greenbar, 2) > 0) then
            DBMS_OUTPUT.put_line ('<tr class="odd">');
        else
            DBMS_OUTPUT.put_line ('<tr class="even">');
        end if;

        v_greenbar := v_greenbar + 1;
        DBMS_OUTPUT.put_line ('<td>' || to_char(to_date(recResults.HR,'YYYYMMDDHH24'), 'MON-DD  HH24') ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z01_R ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z02_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z03_R ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z04_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z05_R ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z06_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z07_R ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');

        -- calculate totals
        v_Z01_R_Total := v_Z01_R_Total + recResults.Z01_R;
        v_Z02_S_Total := v_Z02_S_Total + recResults.Z02_S;
        v_Z03_R_Total := v_Z03_R_Total + recResults.Z03_R;
        v_Z04_S_Total := v_Z04_S_Total + recResults.Z04_S;
        v_Z05_R_Total := v_Z05_R_Total + recResults.Z05_R;
        v_Z06_S_Total := v_Z06_S_Total + recResults.Z06_S;
        v_Z07_R_Total := v_Z07_R_Total + recResults.Z07_R;

    END LOOP;

    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td class="totals">Totals</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_Z01_R_Total || '</td>');--see if we can just use tr.totals
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_Z02_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_Z03_R_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_Z04_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_Z05_R_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_Z06_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_Z07_R_Total || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');

    -- now get the messages sent and received
    DBMS_OUTPUT.put_line ('<h4>VA CHDR Hourly Messages Sent -> Received<br>Activity for ' || to_char(bdate, 'Month dd, yyyy') || '</h4>');
    DBMS_OUTPUT.put_line ('<div class="section">Hourly Breakdown of Messages (Reported in Central Time)</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing=0>');
    DBMS_OUTPUT.put_line ('<tr><th width="19%"><br>Date/Hour</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">Z01<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">Z02<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">Z03<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">Z04<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">Z05<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">Z06<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">Z07<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">A24<br>Sent</th>');
    DBMS_OUTPUT.put_line ('<th width="9%">ACK_A24<br>Rcvd</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curSentRcvd Loop
        if (MOD(v_greenbar, 2) > 0) then
            DBMS_OUTPUT.put_line ('<tr class="odd">');
        else
            DBMS_OUTPUT.put_line ('<tr class="even">');
        end if;

        v_greenbar := v_greenbar + 1;
        DBMS_OUTPUT.put_line ('<td>' || to_char(to_date(recResults.HR,'YYYYMMDDHH24'), 'MON-DD  HH24') ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z01_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z02_R ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z03_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z04_R ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z05_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z06_R ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.Z07_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.A24_S ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.ACK_R ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');

        -- calculate totals
        v_Z01_S_Total := v_Z01_S_Total + recResults.Z01_S;
        v_Z02_R_Total := v_Z02_R_Total + recResults.Z02_R;
        v_Z03_S_Total := v_Z03_S_Total + recResults.Z03_S;
        v_Z04_R_Total := v_Z04_R_Total + recResults.Z04_R;
        v_Z05_S_Total := v_Z05_S_Total + recResults.Z05_S;
        v_Z06_R_Total := v_Z06_R_Total + recResults.Z06_R;
        v_Z07_S_Total := v_Z07_S_Total + recResults.Z07_S;
        v_A24_S_Total := v_A24_S_Total + recResults.A24_S;
        v_ACK_R_Total := v_ACK_R_Total + recResults.ACK_R;

    END LOOP;

    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td>Totals</td>');--see about using tr.totals instead  class="totals"
    DBMS_OUTPUT.put_line ('<td>' || v_Z01_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_Z02_R_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_Z03_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_Z04_R_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_Z05_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_Z06_R_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_Z07_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_A24_S_Total || '</td>');
    DBMS_OUTPUT.put_line ('<td>' || v_ACK_R_Total || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('<br>');
    DBMS_OUTPUT.put_line ('<div class="note" style="width: 100%">Z01/Z02:  ADC Activations</div>');
    DBMS_OUTPUT.put_line ('<div class="note" style="width: 100%">Z03/Z04:  Allergy/Pharmacy Updates</div>');
    DBMS_OUTPUT.put_line ('<div class="note" style="width: 100%">Z05/Z06/Z07:  Batch Message Exchange</div>');
    DBMS_OUTPUT.put_line ('<div class="note" style="width: 100%">A24/ACK:  MPI Link Exchange</div>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');

END;
/
disconnect;
exit;