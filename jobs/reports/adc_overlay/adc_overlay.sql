SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE
v_lookback              NUMBER       := &1;    --this is the look back in days
v_va_site               VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
v_z01                   VARCHAR2(7)  := 'ZCH_Z01';

edate                   DATE := trunc(sysdate)-(1/86400);
bdate                   DATE := edate - v_lookback;

CURSOR curAdcCountPctDaily IS
select to_char(created_date,'YYYYMMDD') || ',' || to_char(sum(dod_tot_count)) || ',' || to_char(sum(activated_count))|| ',' || case sum(dod_tot_count) when 0 then '0' else to_char(round((sum(activated_count) / sum(dod_tot_count)) * 100, 2)) end as rowdata
from (
    select trunc(a.created_date) as created_date,
        count(*) as dod_tot_count,
        0 as activated_count
    from chdr2.audited_event a
    where a.event_type = v_z01
    and   a.sending_site = v_dod_site
    and   A.RECEIVING_SITE = v_va_site    
    AND   a.created_date BETWEEN bdate and edate
/*
    and   a.outcome = 1
    and   A.ADDITIONAL_ID not in ('0011223366',
                                          '0011223322',
                                          '0011223399',
                                          '0011223388',
                                          '0011223377',
                                          '0011223333',
                                          '0011223311',
                                          '0011223300')
*/
    group by trunc(a.created_date)
    
    union all

    select trunc(a.created_date) as created_date,
        0 as dod_tot_count,
        count(*) as activated_count
    from chdr2.audited_event a
    where a.event_type = v_z01
    and   a.sending_site = v_dod_site
    and   A.RECEIVING_SITE = v_va_site    
    AND   a.created_date BETWEEN bdate and edate
/*
    and   a.outcome = 1
    and   A.ADDITIONAL_ID not in ('0011223366',
                                          '0011223322',
                                          '0011223399',
                                          '0011223388',
                                          '0011223377',
                                          '0011223333',
                                          '0011223311',
                                          '0011223300')
*/
    and exists (
        select * from chdr2.audited_event b
        where b.correlation_id = a.MESSAGE_ID
        and   B.ADDITIONAL_INFO_1 = 'ACTIVE'
        and   B.ADDITIONAL_INFO_2 = 'Single Match'
        and   b.outcome = 1
    )
    group by trunc(a.created_date)
    
    union all
    
    --this query insures that we have a row for everyday in the given period
    select (bdate) + rownum -1 as created_date, 0 as dod_tot_count, 0 as activated_count
    from all_objects a
    where rownum <= (edate - bdate) + 1

)
group by to_char(created_date,'YYYYMMDD')
order by to_char(created_date,'YYYYMMDD') desc
;
    
BEGIN
   DBMS_OUTPUT.ENABLE (1000000);

   --loop the cursor printing out a comma separated list of values to chart
   FOR recResults in curAdcCountPctDaily LOOP
      DBMS_OUTPUT.put_line (recResults.rowdata);
   END LOOP;
END;
/
disconnect;
exit;
