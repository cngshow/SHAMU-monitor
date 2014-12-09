SET serveroutput on
SET ECHO OFF
set verify off

-- define local vars --
DECLARE
   v_start_date             VARCHAR2(8) := '&1'; -- a date passed in as yyyymmdd
   bdate                    DATE := to_date(v_start_date,'yyyymmdd');
   edate                    DATE := bdate + 1 - (1/86400); -- one second before midnight on the same day
   v_greenbar               NUMBER := 0;
   v_va_site                VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
   v_dod_site               VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';
   v_station                CHAR(3) := '&2';
   v_threshold_secs         NUMBER := &3;
   v_row_limit              NUMBER := &4;
   n_write_row              NUMBER := 0;
   n_total_count            NUMBER := 0;
   n_threshold_count        NUMBER := 0;

   CURSOR curZ03VistaElapsedSecsBySite IS
    select c.name, message_id, event_type, created_date, vista_date, elapsed_secs
    from (
        select
              A.MESSAGE_ID as message_id,
              a.event_type as event_type,
              A.MESSAGE_TS as vista_date,
              A.CREATED_DATE as created_date,
               round((to_date(to_char(A.CREATED_DATE, 'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS') -
                TO_DATE('19700101000000', 'YYYYMMDDHH24MISS')) * 86400,0) -
               round((to_date(to_char(A.Message_ts, 'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS') -
                TO_DATE('19700101000000', 'YYYYMMDDHH24MISS')) * 86400,0) as elapsed_secs,
              SUBSTR(to_char(REGEXP_substr(REGEXP_substr(A.MESSAGE_CONTENT, '<ORC\.3>.*?<EI\.2>(\d{3}).*?</EI\.2></ORC\.3>'), '<EI.2>.*?</EI.2>')), 7, 3) as station
        from  chdr2.audited_event a
        where
              a.created_date between bdate and edate
        and   a.event_type in ( 'PRES','FILL')
        and   A.SENDING_SITE = 'VHACHDR.MED.VA.GOV'
        and   a.receiving_site = 'DODCHDR.HA.OSD.GOV'
    ) b, CHDR2.STD_INSTITUTION c
    where b.station is not null
    and   b.station = c.stationnumber
    and   c.agency_id=1009121 --VA agency
    and   station = v_station
    order by elapsed_secs desc
    ;

BEGIN
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="rpt">');
    DBMS_OUTPUT.put_line ('<div class="section">Top ' || to_char(v_row_limit) || ' Slowest Time From VistA to CHDR on ' || to_char(bdate, 'Mon dd, yyyy') || '</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing=0>');
    DBMS_OUTPUT.put_line ('<tr><th width="25%"><br>VistA Station Name</th>');
    DBMS_OUTPUT.put_line ('<th width="15%"><br>Message ID</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Event<br>Type</th>');
    DBMS_OUTPUT.put_line ('<th width="15%"><br>VistA Date</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">CHDR<br>Audit Date</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Elapsed<br>Seconds</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curZ03VistaElapsedSecsBySite LOOP
        n_total_count := n_total_count + 1;

        if (recResults.elapsed_secs >= v_threshold_secs) then
            n_threshold_count := n_threshold_count + 1;
        end if;

        if (n_total_count <= v_row_limit) then
            if (MOD(v_greenbar, 2) > 0) then
                DBMS_OUTPUT.put_line ('<tr class="odd">');
            else
                DBMS_OUTPUT.put_line ('<tr class="even">');
            end if;

            v_greenbar := v_greenbar + 1;
            DBMS_OUTPUT.put_line ('<td>' || recResults.name ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || recResults.message_id ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || recResults.event_type ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || to_char(recResults.vista_date,'hh24:mi:ss') ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || to_char(recResults.created_date,'hh24:mi:ss') ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || recResults.elapsed_secs ||'</td>');
            DBMS_OUTPUT.put_line ('</tr>');
        end if;
    end loop;

    --summary statistics
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td><br>SUMMARY STATISTICS</td>');
    DBMS_OUTPUT.put_line ('<td><br>Count < ' || v_threshold_secs ||' Secs</td>');
    DBMS_OUTPUT.put_line ('<td><br>Count >= ' || v_threshold_secs ||' Secs</td>');
    DBMS_OUTPUT.put_line ('<td><br>Total Count</td>');
    DBMS_OUTPUT.put_line ('<td><br>Pct >= ' || v_threshold_secs ||' Secs</td>');
    DBMS_OUTPUT.put_line ('<td><br></td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td><br></td>');
    DBMS_OUTPUT.put_line ('<td>' || to_char(n_total_count - n_threshold_count) ||'<br></td>');
    DBMS_OUTPUT.put_line ('<td>' || n_threshold_count ||'<br></td>');
    DBMS_OUTPUT.put_line ('<td>' || n_total_count ||'<br></td>');
    DBMS_OUTPUT.put_line ('<td>' || round(((n_threshold_count/n_total_count)*100),1) ||'%<br></td>');
    DBMS_OUTPUT.put_line ('<td><br></td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td colspan=6><br></td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');
END;
/
disconnect;
exit;
