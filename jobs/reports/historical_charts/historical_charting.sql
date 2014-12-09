SET serveroutput on
SET ECHO OFF
set verify off 
set linesize 60

-- define local vars --
DECLARE
    v_start_date            VARCHAR2(8) := '&1'; -- the start date as a string yyyymmdd
    bdate                   DATE   := (to_date(v_start_date,'yyyymmdd')); --Convert to the equivalent of midnight Central minus 1 day
    edate                   DATE   := (bdate + 1) - 1/86400;
    v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
    v_vha_site              VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';
    v_hdr_site              VARCHAR2(50) := 'HDR.MED.VA.GOV';
    v_mpi_site              VARCHAR2(50) := 'MPI-AUSTIN.MED.VA.GOV';
    
    --this SQL totals all message traffic in 5 minute buckets with all messages arriving between minute zero and
    --4 minute and 59 seconds to be written in the first 5 minute bucket identified as minute 05.
    
    CURSOR curMessageCounts IS
        select mi,
            sending_app || '_' || message_type || '_' || case outcome when 1 then 'SUCCESS' else 'FAILURE' end as msg_data,
            sum(cnt) as msg_count
        FROM (
            select to_char(to_date(mi,'yyyymmddhh24mi') + (5/1440) - (mod(to_number(to_char(to_date(mi,'yyyymmddhh24mi'),'hh24mi')),5)/1440),'yyyymmddhh24mi') as mi,
                sending_app as sending_app,
                message_type as message_type,
                outcome as outcome,
                sum(cnt) as cnt
            From (

                SELECT to_char(a.created_date,'yyyymmddhh24mi') as mi,
                    case when a.sending_site = v_dod_site then 'DOD' else 'VA' end as sending_app,
                    case when a.event_type in ('FILL','ALGY','CHEM','PRES') then 'Z03' when a.event_type = 'ADT_A24' then 'DOD_A24' when a.event_type = 'ACK_A24' then 'VA_ACK' else substr(a.event_type, 5) end as message_type,
                    a.outcome as outcome,
                    count(*) as cnt        
                FROM  chdr2.audited_event a
                WHERE a.sending_site in (v_dod_site,v_vha_site)
                and   a.receiving_site in (v_dod_site,v_vha_site)
                and   a.created_date between bdate and edate
                and   a.event_type in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07','ADT_A24','ACK_A24')
                group by to_char(a.created_date,'yyyymmddhh24mi'), 
                         a.sending_site, 
                         case when a.event_type in ('FILL','ALGY','CHEM','PRES') then 'Z03' when a.event_type = 'ADT_A24' then 'DOD_A24' when a.event_type = 'ACK_A24' then 'VA_ACK' else substr(a.event_type, 5) end, 
                         A.OUTCOME

                union all

                SELECT to_char(a.created_date,'yyyymmddhh24mi') as mi,
                    case when a.sending_site = v_vha_site then 'VA' else 'MPI' end as sending_app,
                    case when a.receiving_site = v_vha_site then 'VA' else 'MPI' end || '_' || case when a.event_type = 'ADT_A24' then 'A24' else 'ACK' end as message_type,
                    a.outcome as outcome,
                    count(*) as cnt        
                FROM  chdr2.audited_event a
                WHERE a.sending_site in (v_mpi_site, v_vha_site)
                AND   A.receiving_site in (v_mpi_site,v_vha_site)
                and   a.created_date between bdate and edate
                and   a.event_type in ('ADT_A24','ACK_A24')
                group by to_char(a.created_date,'yyyymmddhh24mi'), 
                         a.sending_site, 
                         case when a.receiving_site = v_vha_site then 'VA' else 'MPI' end || '_' || case when a.event_type = 'ADT_A24' then 'A24' else 'ACK' end, 
                         A.OUTCOME
 
                union all

              
                SELECT to_char(a.created_date,'yyyymmddhh24mi') as mi,
                    'HDR' as sending_app,
                    'AUDIT' as message_type,
                    1 as outcome,
                    count(*) as cnt        
                FROM  chdr2.audited_event a
                WHERE a.sending_site = v_vha_site
                and   a.receiving_site = v_hdr_site
                and   a.created_date between bdate and edate
                group by to_char(a.created_date,'yyyymmddhh24mi')
/*
                union all

                select to_char("A"."DtTm",'yyyymmddhh24mi') as mi,
                      'HDR' as sending_app,
                      'WRITE' as message_type,
                      1 as outcome,
                      nvl(sum("A"."Msg_Cnt"),0) as cnt        
                FROM  CHDR2.SHAMU_HDR_COUNTS a
                WHERE "A"."DtTm" between bdate and edate
                group by to_char("A"."DtTm",'yyyymmddhh24mi')
*/
            )
            group by to_date(mi,'yyyymmddhh24mi') + (5/1440) - (mod(to_number(to_char(to_date(mi,'yyyymmddhh24mi'),'hh24mi')),5)/1440), 
                     sending_app, 
                     message_type, 
                     OUTCOME
            -- the following SQL calls ensure that we have a 5 minute bucket for a total to be set into for all types and agencies

            --A24/ACK handshake between VA and DOD
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','DOD_A24',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','VA_ACK',1,0
                from all_objects a
                where rownum <= (1440/5)

            --A24/ACK handshake between VA and MPI
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','MPI_A24',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'MPI','VA_ACK',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'MPI','VA_A24',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','MPI_ACK',1,0
                from all_objects a
                where rownum <= (1440/5)

            --remaining Z message type pairs
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z01',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z01',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z02',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z02',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z03',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z03',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z04',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z04',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z05',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z05',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z06',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z06',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z07',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'DOD','Z07',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z01',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z01',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z02',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z02',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z03',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z03',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z04',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z04',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z05',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z05',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z06',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z06',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z07',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'VA','Z07',0,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'HDR','AUDIT',1,0
                from all_objects a
                where rownum <= (1440/5)
            union all
                select to_char(bdate + (5/1440) + ((rownum - 1) / (1440/5)),'yyyymmddhh24mi'),'HDR','WRITE',1,0
                from all_objects a
                where rownum <= (1440/5)
        )
        group by mi, sending_app, message_type, outcome
        order by mi, sending_app, message_type, outcome
        ;

BEGIN
    DBMS_OUTPUT.ENABLE (1000000);

    FOR recResults in curMessageCounts Loop    
        DBMS_OUTPUT.put_line(recResults.mi || ',' || recResults.msg_data || ',' || to_char(recResults.msg_count));
    END LOOP;
END;
/

disconnect;
exit;
