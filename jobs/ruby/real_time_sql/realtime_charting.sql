select to_number(to_char(sysdate,'ss')) as server_sec, 
    mi as mi,
    sending_app || '_' || message_type as agency_msg,
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
    SELECT to_char(a.created_date,'YYYYMMDDHH24MI') as mi,
        case when a.sending_site = 'DODCHDR.HA.OSD.GOV' then 'DOD' else 'VA' end as sending_app,
        case when a.event_type in ('FILL','ALGY','CHEM','PRES') then 'Z03' when a.event_type = 'ACK_A24' then 'ACK' else substr(a.event_type, 5) end as message_type,
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
     FROM chdr2.audited_event a
    WHERE a.sending_site in ('VHACHDR.MED.VA.GOV','DODCHDR.HA.OSD.GOV')
    and   a.outcome = 1
    and   a.created_date between 
            to_date( ((round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') and
            to_date( ((round(to_number(to_char(sysdate,'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss')
    and   a.event_type in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07','ADT_A24','ACK_A24')
union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','Z01',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','Z02',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','Z03',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','Z04',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','Z05',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','Z06',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','Z07',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','A24',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','ACK',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'DOD','TOTALS',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','Z01',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','Z02',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','Z03',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','Z04',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','Z05',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','Z06',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','Z07',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','A24',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','ACK',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char( (round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0))) as mi,
        'VA','TOTALS',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
    union all
    select to_char(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi'))) as mi,
        'HDR','HDR_WRITES',0,0,0,0,0,0,0,0,0,0,0,0
    FROM dual
union all
    SELECT to_char(a.created_date,'YYYYMMDDHH24MI') as mi,
        case when a.sending_site = 'DODCHDR.HA.OSD.GOV' then 'DOD' else 'VA' end as sending_app,
        'TOTALS' as message_type,
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
     FROM chdr2.audited_event a
    WHERE a.sending_site in ('VHACHDR.MED.VA.GOV','DODCHDR.HA.OSD.GOV')
    and   a.outcome = 1
    and   a.created_date between 
            to_date( ((round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') and
            to_date( ((round(to_number(to_char(sysdate,'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss')
    and   a.event_type in ('ZCH_Z01','ZCH_Z02','FILL','ALGY','CHEM','PRES','ZCH_Z04','QBP_Z05','RSP_Z06','ZCH_Z07','ADT_A24','ACK_A24')
union all
    SELECT to_char(a.created_date,'YYYYMMDDHH24MI') as mi,
        'VA' as sending_app,
        'HDR_TOTALS' as message_type,
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
     FROM chdr2.audited_event a
    WHERE a.sending_site = 'VHACHDR.MED.VA.GOV'
    and   a.receiving_site = 'HDR.MED.VA.GOV'
    and   a.outcome = 1
    and   a.created_date between 
            to_date( ((round(to_number(to_char(sysdate - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') and
            to_date( ((round(to_number(to_char(sysdate,'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss')
union all
SELECT to_char(SYSTIMESTAMP - (60/86400),'yyyymmddhh24mi') as mi,
    'HDR' as sending_app,
    'HDR_WRITES' as message_type,
    case when a.message_insertion_time between 
            round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000 and 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 4999   then 1 else 0 end as sec5,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 5000 and 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 9999   then 1 else 0 end as sec10,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 10000 and        
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 14999 then 1 else 0 end as sec15,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 15000 and
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 19999 then 1 else 0 end as sec20,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 20000 and
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 24999 then 1 else 0 end as sec25,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 25000 and
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 29999 then 1 else 0 end as sec30,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 30000 and
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 34999 then 1 else 0 end as sec35,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 35000 and
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 39999 then 1 else 0 end as sec40,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 40000 and 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 44999 then 1 else 0 end as sec45,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 45000 and 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 49999 then 1 else 0 end as sec50,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 50000 and 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 54999 then 1 else 0 end as sec55,
    case when a.message_insertion_time between 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 55000 and 
            (round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000) + 59999 then 1 else 0 end as sec60
FROM HL7_PLUS.HL7_REPOSITORY a
WHERE a.message_insertion_time between 
    round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP) - (60/86400),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000 and 
    round(to_number( (to_date( ((round(to_number(to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP),'yyyymmddhh24mi.ss')),0)) * 100),'yyyy-mm-dd hh24:mi:ss') -
        TO_DATE('01011970000000' , 'ddmmyyyyhh24miss')) * 86400),0) * 1000
AND   a.facility_id = 'VHACHDR.med.va.gov'
)
group by mi, sending_app || '_' || message_type
order by mi, sending_app || '_' || message_type
