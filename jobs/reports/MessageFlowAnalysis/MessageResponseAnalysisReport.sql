SET serveroutput on
SET ECHO OFF
set verify off

-- define local vars --
DECLARE
   v_start_date             VARCHAR2(8) := '&1'; -- a date passed in as yyyymmdd
   v_lookback_days          NUMBER := &2;
   v_greenbar               NUMBER := 0;
   v_last_ddd               NUMBER := 0;
   v_ddd                    NUMBER := 0;
   bdate                    DATE := to_date(v_start_date,'yyyymmdd') - v_lookback_days;
   edate                    DATE := bdate + v_lookback_days;
   v_vha_site               VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
   v_dod_site               VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';
   v_site_name              VARCHAR2 (50) := '';

   CURSOR curMsgRsp IS
    select audited_date, sending_site,
        sum(case when elapsed_seconds between 0 and 60 then 1 else 0 end) as min1,
        sum(case when elapsed_seconds between 61 and 120 then 1 else 0 end) as min2,
        sum(case when elapsed_seconds between 121 and 180 then 1 else 0 end) as min3,
        sum(case when elapsed_seconds between 181 and 240 then 1 else 0 end) as min4,
        sum(case when elapsed_seconds between 241 and 300 then 1 else 0 end) as min5,
        sum(case when elapsed_seconds between 301 and 600 then 1 else 0 end) as min10,
        sum(case when elapsed_seconds between 601 and 900 then 1 else 0 end) as min15,
        sum(case when elapsed_seconds between 901 and 1200 then 1 else 0 end) as min20,
        sum(case when elapsed_seconds between 1201 and 1500 then 1 else 0 end) as min25,
        sum(case when elapsed_seconds between 1501 and 1800 then 1 else 0 end) as min30,
        sum(case when elapsed_seconds between 1801 and 2100 then 1 else 0 end) as min35,
        sum(case when elapsed_seconds between 2101 and 2400 then 1 else 0 end) as min40,
        sum(case when elapsed_seconds between 2401 and 2700 then 1 else 0 end) as min45,
        sum(case when elapsed_seconds between 2701 and 3000 then 1 else 0 end) as min50,
        sum(case when elapsed_seconds between 3001 and 3300 then 1 else 0 end) as min55,
        sum(case when elapsed_seconds between 3301 and 3600 then 1 else 0 end) as min60,
        sum(case when elapsed_seconds >= 3601 then 1 else 0 end) as gt60,
        round(min(elapsed_seconds),0) as minTime,
        round(avg(elapsed_seconds),0) as avgTime,
        round(max(elapsed_seconds),0) as maxTime
    from (
        select to_char(a.created_date,'yyyymmdd') as audited_date,
            a.sending_site,
            (to_date(to_char(b.CREATED_DATE, 'MM/DD/YYYY HH24:MI:SS'), 'MM-DD-YYYY HH24:MI:SS') - TO_DATE('01/01/1970 00:00:00', 'MM-DD-YYYY HH24:MI:SS')) * 24 * 60 * 60 -
            (to_date(to_char(A.CREATED_DATE, 'MM/DD/YYYY HH24:MI:SS'), 'MM-DD-YYYY HH24:MI:SS') - TO_DATE('01/01/1970 00:00:00', 'MM-DD-YYYY HH24:MI:SS')) * 24 * 60 * 60 as elapsed_seconds
        from chdr2.audited_event a, chdr2.audited_event b
        where b.CORRELATION_ID = a.message_id
        and   a.created_date between bdate and edate
        and   a.sending_site in (v_vha_site, v_dod_site)
        and   a.receiving_site in (v_vha_site, v_dod_site)
    )
    where elapsed_seconds >= 0
    group by audited_date, sending_site
    order by audited_date, sending_site
    ;

BEGIN
    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="rpt">');
    -- end - html output template

    --Display the heading with the date range that is being reported on
    if (v_lookback_days > 1) then
        DBMS_OUTPUT.put_line ('<H4>CHDR Message Response Time Analysis Report for<br>' || to_char(bdate, 'Month dd, yyyy') || ' Thru ' || to_char(edate - 1, 'Month dd, yyyy') || '</H4>');
    else
        if (v_lookback_days = 0) then
            edate := sysdate;
            DBMS_OUTPUT.put_line ('<H4>CHDR Message Response Time Analysis Report from midnight on<br>' || to_char(bdate, 'Month dd, yyyy') || ' until ' || to_char(edate, 'Month dd, yyyy hh24:mi:ss') || '</H4>');
        else
            DBMS_OUTPUT.put_line ('<H4>CHDR Message Response Time Analysis Report for<br>' || to_char(bdate, 'Month dd, yyyy') || '</H4>');
        end if;
    end if;

    --Average Response Time Table
    DBMS_OUTPUT.put_line ('<div class="section">Message Response Times Analysis</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing="0" cellpadding="1px">');
    DBMS_OUTPUT.put_line ('<tr><th width="10%" style="text-align: center">Created<br>Date</th>');
    DBMS_OUTPUT.put_line ('<th width="4%" style="text-align: center">Sending<br>Site</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>1</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>2</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>3</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>4</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>5</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>10</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>15</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>20</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>25</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>30</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>35</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>40</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>45</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>50</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>55</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">Min<br>60</th>');
    DBMS_OUTPUT.put_line ('<th width="4%">GT<br>60</th>');
    DBMS_OUTPUT.put_line ('<th width="6%">Min<br>Secs</th>');
    DBMS_OUTPUT.put_line ('<th width="6%">Avg<br>Secs</th>');
    DBMS_OUTPUT.put_line ('<th width="6%">Max<br>Secs</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curMsgRsp LOOP
        v_ddd := to_number(to_char(to_date(recResults.audited_date,'yyyymmdd'),'DDD'));

        if (v_lookback_days > 1) then
            if (MOD(v_ddd, 2) > 0) then
                DBMS_OUTPUT.put_line ('<tr class="odd">');
            else
                DBMS_OUTPUT.put_line ('<tr class="even">');
            end if;
        else
            if (MOD(v_greenbar, 2) > 0) then
                DBMS_OUTPUT.put_line ('<tr class="odd">');
            else
                DBMS_OUTPUT.put_line ('<tr class="even">');
            end if;
        end if;

        v_greenbar := v_greenbar + 1;

        --if the Z03 sending site is VA then the response on the report is DoD and vice versa
        if (recResults.sending_site = v_vha_site) then
            v_site_name := 'DoD';
        else
            v_site_name := 'VHA';
        end if;

        if (v_lookback_days > 1 and v_last_ddd = v_ddd) then
            DBMS_OUTPUT.put_line ('<td></td>');
        else
            DBMS_OUTPUT.put_line ('<td style="text-align: center">' || recResults.audited_date ||'</td>');
        end if;

        v_last_ddd := v_ddd;
        DBMS_OUTPUT.put_line ('<td style="text-align: center">' || v_site_name ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min1 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min2 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min3 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min4 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min5 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min10 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min15 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min20 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min25 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min30 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min35 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min40 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min45 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min50 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min55 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.min60 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.gt60 ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.minTime ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.avgTime ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.maxTime ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');
      END LOOP;

    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br></div><br><br>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');
END;
/
disconnect;
exit;