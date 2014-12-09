SET serveroutput on
SET linesize 2000
SET ECHO OFF
set verify off

-- define local vars --
DECLARE
   v_start_date             VARCHAR2(8) := '&1'; -- a date passed in as yyyymmdd
   v_end_date               VARCHAR2(8) := '&2'; -- a date passed in as yyyymmdd
   bdate                    DATE := to_date(v_start_date,'yyyymmdd');
   edate                    DATE := to_date(v_end_date,'yyyymmdd') + 1- (1/86400); -- one second before midnight on the same day
   v_va_site                VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
   v_dod_site               VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';
   v_greenbar               NUMBER := 0;

  /*
  This cursor counts the number of distinct orders followed by the actual order count sent and the  total number of
  orders on a given date
   */
   CURSOR curCMOP IS
    select dt,
      count(distinct order_num) as orders,
      sum(order_count) as total_messages,
      sum(order_count) - count(distinct order_num) as order_dups
    from (
        select dt, substr(order_number, 7, length(order_number) - 13) as order_num, count(*) as order_count
        from (
            select trunc(A.CREATED_date) as dt, to_char(regexp_substr(regexp_substr(message_content, '<ORC.2><EI.1>.*?</EI.1>.*?</ORC.2>'),'<EI.1>.*?</EI.1>')) as order_number
            from chdr2.audited_event a
            where A.CREATED_date between bdate and edate
            and   A.SENDING_SITE = v_va_site
            and   a.receiving_site = v_dod_site
            and   a.event_type in ('FILL','PRES')
            and regexp_like(a.message_content,'<LA1.6>MAIL</LA1.6>')
        )
        group by dt, substr(order_number, 7, length(order_number) - 13)
    )
    group by dt
    ;

BEGIN
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="rpt">');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing=0>');
    DBMS_OUTPUT.put_line ('<tr><th width="25%">Date (yyyymmdd)</th>');
    DBMS_OUTPUT.put_line ('<th width="25%">Order Count</th>');
    DBMS_OUTPUT.put_line ('<th width="25%">Total Count</th>');
    DBMS_OUTPUT.put_line ('<th width="25%">Order Dups</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curCMOP Loop
        if (MOD(v_greenbar, 2) > 0) then
            DBMS_OUTPUT.put_line ('<tr class="odd">');
        else
            DBMS_OUTPUT.put_line ('<tr class="even">');
        end if;

        v_greenbar := v_greenbar + 1;
        DBMS_OUTPUT.put_line ('<td>' || to_char(recResults.dt, 'yyyymmdd') ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || to_char(recResults.orders) ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || to_char(recResults.total_messages) ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || to_char(recResults.order_dups) ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');
     END LOOP;

    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');
END;
/
disconnect;
exit;

