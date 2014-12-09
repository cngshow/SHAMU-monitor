select to_number(to_char(sysdate,'ss')) as server_sec, 
    mi as mi,
    sending_app || '_' || message_type || '_' || case outcome when 1 then 'Success' else 'Failure' end as agency_msg,
    sum(sec5) as sec05,
    sum(sec10) as sec10,
    sum(sec15) as sec15,
    sum(sec20) as sec20,
    sum(sec25) as sec25,
    sum(sec30) as sec30,
    sum(sec35) as sec35,
    sum(sec40) as sec40,
    sum(sec45) as sec45,
    sum(sec50) as sec50,
    sum(sec55) as sec55,
    sum(sec60) as sec60
from (    
    SELECT 'BDATE' as mi,
        case when a.sending_site = 'DODCHDR.HA.OSD.GOV' then 'DOD' else 'VA' end as sending_app,
        case when a.event_type in ('FILL','ALGY','CHEM','PRES') then 'Z03' else substr(a.event_type, 5) end as message_type,
        a.outcome as outcome,        
        case when to_number(to_char(a.created_date,'SS.FF')) between 0 and 4.99   then 1 else 0 end as sec5,
        case when to_number(to_char(a.created_date,'SS.FF')) between 5 and 9.99   then 1 else 0 end as sec10,
        case when to_number(to_char(a.created_date,'SS.FF')) between 10 and 14.99 then 1 else 0 end as sec15,
        case when to_number(to_char(a.created_date,'SS.FF')) between 15 and 19.99 then 1 else 0 end as sec20,
        case when to_number(to_char(a.created_date,'SS.FF')) between 20 and 24.99 then 1 else 0 end as sec25,
        case when to_number(to_char(a.created_date,'SS.FF')) between 25 and 29.99 then 1 else 0 end as sec30,
        case when to_number(to_char(a.created_date,'SS.FF')) between 30 and 34.99 then 1 else 0 end as sec35,
        case when to_number(to_char(a.created_date,'SS.FF')) between 35 and 39.99 then 1 else 0 end as sec40,
        case when to_number(to_char(a.created_date,'SS.FF')) between 40 and 44.99 then 1 else 0 end as sec45,
        case when to_number(to_char(a.created_date,'SS.FF')) between 45 and 49.99 then 1 else 0 end as sec50,
        case when to_number(to_char(a.created_date,'SS.FF')) between 50 and 54.99 then 1 else 0 end as sec55,
        case when to_number(to_char(a.created_date,'SS.FF')) between 55 and 60.00 then 1 else 0 end as sec60
    FROM  chdr2.audited_event a
    WHERE a.sending_site in ('VHACHDR.MED.VA.GOV','DODCHDR.HA.OSD.GOV')
    and   a.created_date between to_date('BDATE','yyyymmddhh24mi') and to_date('BDATE','yyyymmddhh24mi') + 1/1440
    and   a.event_type in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
union all
    SELECT 'BDATE' as mi,
        case when a.sending_site = 'DODCHDR.HA.OSD.GOV' then 'DOD' else 'VA' end as sending_app,
        'TOTALS' as message_type,
        a.outcome as outcome,        
        case when to_number(to_char(a.created_date,'SS.FF')) between 0 and 4.99   then 1 else 0 end as sec5,
        case when to_number(to_char(a.created_date,'SS.FF')) between 5 and 9.99   then 1 else 0 end as sec10,
        case when to_number(to_char(a.created_date,'SS.FF')) between 10 and 14.99 then 1 else 0 end as sec15,
        case when to_number(to_char(a.created_date,'SS.FF')) between 15 and 19.99 then 1 else 0 end as sec20,
        case when to_number(to_char(a.created_date,'SS.FF')) between 20 and 24.99 then 1 else 0 end as sec25,
        case when to_number(to_char(a.created_date,'SS.FF')) between 25 and 29.99 then 1 else 0 end as sec30,
        case when to_number(to_char(a.created_date,'SS.FF')) between 30 and 34.99 then 1 else 0 end as sec35,
        case when to_number(to_char(a.created_date,'SS.FF')) between 35 and 39.99 then 1 else 0 end as sec40,
        case when to_number(to_char(a.created_date,'SS.FF')) between 40 and 44.99 then 1 else 0 end as sec45,
        case when to_number(to_char(a.created_date,'SS.FF')) between 45 and 49.99 then 1 else 0 end as sec50,
        case when to_number(to_char(a.created_date,'SS.FF')) between 50 and 54.99 then 1 else 0 end as sec55,
        case when to_number(to_char(a.created_date,'SS.FF')) between 55 and 60.00 then 1 else 0 end as sec60
    FROM  chdr2.audited_event a
    WHERE a.sending_site in ('VHACHDR.MED.VA.GOV','DODCHDR.HA.OSD.GOV')
    and   a.created_date between to_date('BDATE','yyyymmddhh24mi') and to_date('BDATE','yyyymmddhh24mi') + 1/1440
    and   a.event_type in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07')
union all
    SELECT 'BDATE' as mi,
        case when a.sending_site = 'VHACHDR.MED.VA.GOV' then 'VA' else 'MPI' end as sending_app,
        case a.event_type when 'ADT_A24' then 'A24' else 'ACK' end as message_type,
        a.outcome as outcome,        
        case when to_number(to_char(a.created_date,'SS.FF')) between 0 and 4.99   then 1 else 0 end as sec5,
        case when to_number(to_char(a.created_date,'SS.FF')) between 5 and 9.99   then 1 else 0 end as sec10,
        case when to_number(to_char(a.created_date,'SS.FF')) between 10 and 14.99 then 1 else 0 end as sec15,
        case when to_number(to_char(a.created_date,'SS.FF')) between 15 and 19.99 then 1 else 0 end as sec20,
        case when to_number(to_char(a.created_date,'SS.FF')) between 20 and 24.99 then 1 else 0 end as sec25,
        case when to_number(to_char(a.created_date,'SS.FF')) between 25 and 29.99 then 1 else 0 end as sec30,
        case when to_number(to_char(a.created_date,'SS.FF')) between 30 and 34.99 then 1 else 0 end as sec35,
        case when to_number(to_char(a.created_date,'SS.FF')) between 35 and 39.99 then 1 else 0 end as sec40,
        case when to_number(to_char(a.created_date,'SS.FF')) between 40 and 44.99 then 1 else 0 end as sec45,
        case when to_number(to_char(a.created_date,'SS.FF')) between 45 and 49.99 then 1 else 0 end as sec50,
        case when to_number(to_char(a.created_date,'SS.FF')) between 50 and 54.99 then 1 else 0 end as sec55,
        case when to_number(to_char(a.created_date,'SS.FF')) between 55 and 60.00 then 1 else 0 end as sec60
    FROM  chdr2.audited_event a
    WHERE a.sending_site in ('VHACHDR.MED.VA.GOV','MPI-AUSTIN.MED.VA.GOV')
    and   a.created_date between to_date('BDATE','yyyymmddhh24mi') and to_date('BDATE','yyyymmddhh24mi') + 1/1440
    and   a.event_type in ('ADT_A24','ACK_A24')
union all
    SELECT 'BDATE' as mi,
        'VA' as sending_app,
        'HDR_TOTALS' as message_type,
        a.outcome as outcome,        
        case when to_number(to_char(a.created_date,'SS.FF')) between 0 and 4.99   then 1 else 0 end as sec5,
        case when to_number(to_char(a.created_date,'SS.FF')) between 5 and 9.99   then 1 else 0 end as sec10,
        case when to_number(to_char(a.created_date,'SS.FF')) between 10 and 14.99 then 1 else 0 end as sec15,
        case when to_number(to_char(a.created_date,'SS.FF')) between 15 and 19.99 then 1 else 0 end as sec20,
        case when to_number(to_char(a.created_date,'SS.FF')) between 20 and 24.99 then 1 else 0 end as sec25,
        case when to_number(to_char(a.created_date,'SS.FF')) between 25 and 29.99 then 1 else 0 end as sec30,
        case when to_number(to_char(a.created_date,'SS.FF')) between 30 and 34.99 then 1 else 0 end as sec35,
        case when to_number(to_char(a.created_date,'SS.FF')) between 35 and 39.99 then 1 else 0 end as sec40,
        case when to_number(to_char(a.created_date,'SS.FF')) between 40 and 44.99 then 1 else 0 end as sec45,
        case when to_number(to_char(a.created_date,'SS.FF')) between 45 and 49.99 then 1 else 0 end as sec50,
        case when to_number(to_char(a.created_date,'SS.FF')) between 50 and 54.99 then 1 else 0 end as sec55,
        case when to_number(to_char(a.created_date,'SS.FF')) between 55 and 60.00 then 1 else 0 end as sec60
    FROM  chdr2.audited_event a
    WHERE a.sending_site = 'VHACHDR.MED.VA.GOV'
    and   a.receiving_site = 'HDR.MED.VA.GOV'
    and   a.created_date between to_date('BDATE','yyyymmddhh24mi') and to_date('BDATE','yyyymmddhh24mi') + 1/1440
union all
    select 'BDATE' as mi,'DOD','Z01',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z01',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z02',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z02',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z03',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z03',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z04',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z04',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z05',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z05',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z06',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z06',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z07',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','Z07',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','TOTALS',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'DOD','TOTALS',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z01',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z01',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z02',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z02',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z03',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z03',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z04',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z04',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z05',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z05',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z06',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z06',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z07',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','Z07',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','TOTALS',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','TOTALS',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','A24',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','A24',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'MPI','ACK',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'MPI','ACK',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','HDR_TOTALS',1,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
    union all
    select 'BDATE' as mi,'VA','HDR_TOTALS',0,0,0,0,0,0,0,0,0,0,0,0,0 FROM dual
)
group by mi, sending_app, message_type, outcome
order by mi, sending_app, message_type, outcome
