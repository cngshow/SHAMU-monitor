SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE
   v_start_date             VARCHAR2(8) := '&1'; -- a date passed in as yyyymmdd
   bdate                    DATE := to_date(v_start_date,'yyyymmdd');
   edate                    DATE := bdate + 1- (1/86400); -- one second before midnight on the same day
   v_va_site                VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
   v_dod_site               VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';

   CURSOR curZ03BySite IS
        select stationnumber || '|' || stationname || '|' || to_char(sum(z03s)) as rowdata
        from (
            select b.stationnumber, c.name as stationname, b.cnt as z03s
            from (
                select SUBSTR(to_char(REGEXP_substr(REGEXP_substr(A.MESSAGE_CONTENT, '<ORC\.3>.*?<EI\.2>(\d{3}).*?</EI\.2></ORC\.3>'), '<EI.2>.*?</EI.2>')), 7, 3) AS stationnumber, count(*) as cnt 
                from chdr2.audited_event a
                where A.CREATED_date between bdate and edate
                and   A.SENDING_SITE = v_va_site
                and   a.receiving_site = v_dod_site
                and   a.event_type in ('FILL','PRES')
                group by SUBSTR(to_char(REGEXP_substr(REGEXP_substr(A.MESSAGE_CONTENT, '<ORC\.3>.*?<EI\.2>(\d{3}).*?</EI\.2></ORC\.3>'), '<EI.2>.*?</EI.2>')), 7, 3)
            union all
                select SUBSTR(to_char(REGEXP_substr(REGEXP_substr(A.MESSAGE_CONTENT, '<OBR\.3>.*?<EI\.2>(\d{3}).*?</EI\.2></OBR\.3>'), '<EI.2>.*?</EI.2>')), 7, 3) AS stationnumber, count(*) as cnt 
                from chdr2.audited_event a
                where A.CREATED_date between bdate and edate
                and   A.SENDING_SITE = v_va_site
                and   a.receiving_site = v_dod_site
                and   a.event_type = 'ALGY'
                group by SUBSTR(to_char(REGEXP_substr(REGEXP_substr(A.MESSAGE_CONTENT, '<OBR\.3>.*?<EI\.2>(\d{3}).*?</EI\.2></OBR\.3>'), '<EI.2>.*?</EI.2>')), 7, 3)
            union all
                select e.stationnumber, 0
                from CHDR2.STD_INSTITUTION e, CHDR2.STD_FACILITYTYPE  f
                where e.FACILITYTYPE_ID = f.ID
                and   f.ISMEDICALTREATING = 1
                and   e.DEACTIVATIONDATE is null
                and   length(e.stationnumber) = 3
                and   e.agency_id=1009121 -- VA agency
            ) b, CHDR2.STD_INSTITUTION c
            where b.stationnumber is not null
            and   b.stationnumber = c.stationnumber
            and   c.agency_id=1009121 --VA agency)
        )    
        group by stationnumber, stationname
    ;   

BEGIN
   DBMS_OUTPUT.put_line ('RESULTS FOR: ' || v_start_date);
   DBMS_OUTPUT.put_line ('');

    FOR recResults in curZ03BySite LOOP
        DBMS_OUTPUT.put_line (recResults.rowdata);
    end loop;
END;
/
disconnect;
exit;
