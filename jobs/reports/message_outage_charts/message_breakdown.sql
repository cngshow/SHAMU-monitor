SET serveroutput on
SET ECHO OFF
set verify off 
set linesize 200

-- define local vars --
DECLARE
v_start_date            VARCHAR2(8) := '&1'; -- the start date as a string yyyymmdd
bdate                   DATE   := (to_date(v_start_date,'yyyymmdd') - 1); --Convert to the equivalent of midnight Central minus 1 day
edate                   DATE   := (bdate + 1) - 1/86400;
v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
v_vha_site              VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
v_mpi_site              VARCHAR2(50) := 'MPI-AUSTIN.MED.VA.GOV';
v_hdr_site              VARCHAR2(50) := 'HDR.MED.VA.GOV';
v_rowcount              NUMBER := 0;
v_tz_offset             NUMBER := &2;

CURSOR curMessageCounts IS
    select  hr, 
        message_type,
        sending_app,
        sum(min5) as min5, 
        sum(min10) as min10, 
        sum(min15) as min15, 
        sum(min20) as min20,
        sum(min25) as min25,
        sum(min30) as min30,
        sum(min35) as min35,
        sum(min40) as min40,
        sum(min45) as min45,
        sum(min50) as min50,
        sum(min55) as min55,
        sum(min60) as min60
    from 
    (
        SELECT to_char(a.created_date,'YYYYMMDD.HH24') as hr,
            case when a.sending_site = v_dod_site then 'DOD' else 'VA' end as sending_app,
            case when a.event_type in ('FILL','ALGY','CHEM','PRES') then 'Z03' else substr(a.event_type, 5) end as message_type,
            case when to_char(a.created_date,'MI.SS') between 0 and 4.59   then 1 else 0 end as min5,
            case when to_char(a.created_date,'MI.SS') between 5 and 9.59   then 1 else 0 end as min10,
            case when to_char(a.created_date,'MI.SS') between 10 and 14.59 then 1 else 0 end as min15,
            case when to_char(a.created_date,'MI.SS') between 15 and 19.59 then 1 else 0 end as min20,
            case when to_char(a.created_date,'MI.SS') between 20 and 24.59 then 1 else 0 end as min25,
            case when to_char(a.created_date,'MI.SS') between 25 and 29.59 then 1 else 0 end as min30,
            case when to_char(a.created_date,'MI.SS') between 30 and 34.59 then 1 else 0 end as min35,
            case when to_char(a.created_date,'MI.SS') between 35 and 39.59 then 1 else 0 end as min40,
            case when to_char(a.created_date,'MI.SS') between 40 and 44.59 then 1 else 0 end as min45,
            case when to_char(a.created_date,'MI.SS') between 45 and 49.59 then 1 else 0 end as min50,
            case when to_char(a.created_date,'MI.SS') between 50 and 54.59 then 1 else 0 end as min55,
            case when to_char(a.created_date,'MI.SS') between 55 and 60.00 then 1 else 0 end as min60
         FROM chdr2.audited_event a
        WHERE a.sending_site in (v_dod_site, v_vha_site)
        and   a.created_date between bdate and edate
        and   a.event_type in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
     union all
         SELECT to_char(a.created_date,'YYYYMMDD.HH24') as hr,
            case when a.sending_site = v_dod_site then 'DOD' else 'VA' end as sending_app,
            'TOTAL' as message_type,
            case when to_char(a.created_date,'MI.SS') between 0 and 4.59   then 1 else 0 end as min5,
            case when to_char(a.created_date,'MI.SS') between 5 and 9.59   then 1 else 0 end as min10,
            case when to_char(a.created_date,'MI.SS') between 10 and 14.59 then 1 else 0 end as min15,
            case when to_char(a.created_date,'MI.SS') between 15 and 19.59 then 1 else 0 end as min20,
            case when to_char(a.created_date,'MI.SS') between 20 and 24.59 then 1 else 0 end as min25,
            case when to_char(a.created_date,'MI.SS') between 25 and 29.59 then 1 else 0 end as min30,
            case when to_char(a.created_date,'MI.SS') between 30 and 34.59 then 1 else 0 end as min35,
            case when to_char(a.created_date,'MI.SS') between 35 and 39.59 then 1 else 0 end as min40,
            case when to_char(a.created_date,'MI.SS') between 40 and 44.59 then 1 else 0 end as min45,
            case when to_char(a.created_date,'MI.SS') between 45 and 49.59 then 1 else 0 end as min50,
            case when to_char(a.created_date,'MI.SS') between 50 and 54.59 then 1 else 0 end as min55,
            case when to_char(a.created_date,'MI.SS') between 55 and 60.00 then 1 else 0 end as min60
         FROM chdr2.audited_event a
        WHERE a.sending_site in (v_dod_site, v_vha_site)
        and   a.created_date between bdate and edate
        and   a.event_type in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
     union all
         SELECT to_char(a.created_date,'YYYYMMDD.HH24') as hr,
            case when a.sending_site = v_vha_site then 'VA' else 'MPI' end as sending_app,
            a.event_type as message_type,
            case when to_char(a.created_date,'MI.SS') between 0 and 4.59   then 1 else 0 end as min5,
            case when to_char(a.created_date,'MI.SS') between 5 and 9.59   then 1 else 0 end as min10,
            case when to_char(a.created_date,'MI.SS') between 10 and 14.59 then 1 else 0 end as min15,
            case when to_char(a.created_date,'MI.SS') between 15 and 19.59 then 1 else 0 end as min20,
            case when to_char(a.created_date,'MI.SS') between 20 and 24.59 then 1 else 0 end as min25,
            case when to_char(a.created_date,'MI.SS') between 25 and 29.59 then 1 else 0 end as min30,
            case when to_char(a.created_date,'MI.SS') between 30 and 34.59 then 1 else 0 end as min35,
            case when to_char(a.created_date,'MI.SS') between 35 and 39.59 then 1 else 0 end as min40,
            case when to_char(a.created_date,'MI.SS') between 40 and 44.59 then 1 else 0 end as min45,
            case when to_char(a.created_date,'MI.SS') between 45 and 49.59 then 1 else 0 end as min50,
            case when to_char(a.created_date,'MI.SS') between 50 and 54.59 then 1 else 0 end as min55,
            case when to_char(a.created_date,'MI.SS') between 55 and 60.00 then 1 else 0 end as min60
         FROM chdr2.audited_event a
         WHERE a.sending_site in (v_mpi_site, v_vha_site)
         and   a.created_date between bdate and edate
         and   a.event_type in ('ADT_A24','ACK_A24')
/*    union all
         SELECT to_char(a.created_date,'YYYYMMDD.HH24') as hr,
            'VA' as sending_app,
            'HDR_AUDIT' as message_type,
            case when to_char(a.created_date,'MI.SS') between 0 and 4.59   then 1 else 0 end as min5,
            case when to_char(a.created_date,'MI.SS') between 5 and 9.59   then 1 else 0 end as min10,
            case when to_char(a.created_date,'MI.SS') between 10 and 14.59 then 1 else 0 end as min15,
            case when to_char(a.created_date,'MI.SS') between 15 and 19.59 then 1 else 0 end as min20,
            case when to_char(a.created_date,'MI.SS') between 20 and 24.59 then 1 else 0 end as min25,
            case when to_char(a.created_date,'MI.SS') between 25 and 29.59 then 1 else 0 end as min30,
            case when to_char(a.created_date,'MI.SS') between 30 and 34.59 then 1 else 0 end as min35,
            case when to_char(a.created_date,'MI.SS') between 35 and 39.59 then 1 else 0 end as min40,
            case when to_char(a.created_date,'MI.SS') between 40 and 44.59 then 1 else 0 end as min45,
            case when to_char(a.created_date,'MI.SS') between 45 and 49.59 then 1 else 0 end as min50,
            case when to_char(a.created_date,'MI.SS') between 50 and 54.59 then 1 else 0 end as min55,
            case when to_char(a.created_date,'MI.SS') between 55 and 60.00 then 1 else 0 end as min60
         FROM chdr2.audited_event a
         WHERE a.sending_site = v_vha_site
         and   a.receiving_site = v_hdr_site
         and   a.created_date between bdate and edate
    union all
        SELECT to_char(a."DtTm",'YYYYMMDD.HH24') as hr,
               'HDR' as sending_app,
               'HDR_WRITES' as message_type,
               case when to_number(to_char(a."DtTm",'MI')) between 0 and 4 then a."Msg_Cnt" else 0 end as min5,
               case when to_number(to_char(a."DtTm",'MI')) between 5 and 9 then a."Msg_Cnt" else 0 end as min10,
               case when to_number(to_char(a."DtTm",'MI')) between 10 and 14 then a."Msg_Cnt" else 0 end as min15,
               case when to_number(to_char(a."DtTm",'MI')) between 15 and 19 then a."Msg_Cnt" else 0 end as min20,
               case when to_number(to_char(a."DtTm",'MI')) between 20 and 24 then a."Msg_Cnt" else 0 end as min25,
               case when to_number(to_char(a."DtTm",'MI')) between 25 and 29 then a."Msg_Cnt" else 0 end as min30,
               case when to_number(to_char(a."DtTm",'MI')) between 30 and 34 then a."Msg_Cnt" else 0 end as min35,
               case when to_number(to_char(a."DtTm",'MI')) between 35 and 39 then a."Msg_Cnt" else 0 end as min40,
               case when to_number(to_char(a."DtTm",'MI')) between 40 and 44 then a."Msg_Cnt" else 0 end as min45,
               case when to_number(to_char(a."DtTm",'MI')) between 45 and 49 then a."Msg_Cnt" else 0 end as min50,
               case when to_number(to_char(a."DtTm",'MI')) between 50 and 54 then a."Msg_Cnt" else 0 end as min55,
               case when to_number(to_char(a."DtTm",'MI')) between 55 and 59 then a."Msg_Cnt" else 0 end as min60            
        FROM CHDR2.SHAMU_HDR_COUNTS a
        WHERE a."DtTm" between bdate and edate
*/
    )
    group by message_type, hr, sending_app
    order by message_type, hr, sending_app asc
    ;

BEGIN
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line('DATA_BELOW');
    
    FOR recResults in curMessageCounts Loop
        DBMS_OUTPUT.put_line(recResults.hr || ',' || recResults.message_type || ',' || recResults.sending_app || ',' || recResults.min5 || ',' || recResults.min10 || ',' || recResults.min15 || ',' || recResults.min20 || ',' || recResults.min25 || ',' || recResults.min30 || ',' || recResults.min35 || ',' || recResults.min40 || ',' || recResults.min45 || ',' || recResults.min50 || ',' || recResults.min55 || ',' || recResults.min60);
        v_rowcount := v_rowcount + 1;
    END LOOP;
    
    if (v_rowcount = 0) then
        DBMS_OUTPUT.put_line(to_char(bdate,'YYYYMMDD') || '.00,' || 'NO_DATA');
    end if;

    DBMS_OUTPUT.put_line('DATA_ABOVE');
END;
/

disconnect;
exit;
