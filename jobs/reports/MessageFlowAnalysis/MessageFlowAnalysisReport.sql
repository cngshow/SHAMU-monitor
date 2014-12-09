SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE
   v_start_date				VARCHAR2(8) := '&1'; -- a date passed in as yyyymmdd
   v_lookback_days          NUMBER := &2;
   v_greenbar               NUMBER := 0;
   v_last_ddd               NUMBER := 0;
   v_ddd                    NUMBER := 0;
   bdate                    DATE := to_date(v_start_date,'yyyymmdd') - v_lookback_days;
   edate                    DATE := bdate + v_lookback_days;
   v_date_range_days        NUMBER := 0;
   v_va_site                VARCHAR2 (50) := 'VHACHDR.MED.VA.GOV';
   v_dod_site               VARCHAR2 (50) := 'DODCHDR.HA.OSD.GOV';
   v_mpi_site               VARCHAR2 (50) := 'MPI-AUSTIN.MED.VA.GOV';
   v_dod_site_id            VARCHAR2 (50) := '[Department of Defense]';
   v_site_name              VARCHAR2 (200) := '';

   --curADCSummary variables
   v_tot_adc_act_attempts   NUMBER := 0;
   v_tot_adc_inact_attempts NUMBER := 0;
   v_tot_distinct_attempts  NUMBER := 0;
   
   --curADCBreakdown variables
   v_tot_active_attempts    NUMBER := 0;
   v_tot_inactive_attempts  NUMBER := 0;
   v_tot_activations        NUMBER := 0;
--   v_tot_inactivations      NUMBER := 0;
   v_tot_single_match       NUMBER := 0;
   v_tot_no_match           NUMBER := 0;

   --curADCBySite variables
   v_tot_dod_act_attempts    NUMBER := 0;
   v_tot_dod_inact_attempts  NUMBER := 0;
   v_tot_dod_single_match    NUMBER := 0;
   v_tot_dod_no_match        NUMBER := 0;
   v_tot_dod_failed_response NUMBER := 0;
   v_dod_adc_success_pct     NUMBER := 0;
   v_dod_adc_attempt_pct     NUMBER := 0;
   v_tot_va_act_attempts     NUMBER := 0;
   v_tot_va_inact_attempts   NUMBER := 0;
   v_tot_va_single_match     NUMBER := 0;
   v_tot_va_no_match         NUMBER := 0;
   v_tot_va_failed_response  NUMBER := 0;
   v_vha_adc_success_pct     NUMBER := 0;
   v_vha_adc_attempt_pct     NUMBER := 0;

-- Z03_Z04 message variables
   v_tot_algy_vha            NUMBER := 0;
   v_tot_chem_vha            NUMBER := 0;
   v_tot_fill_vha            NUMBER := 0;
   v_tot_pres_vha            NUMBER := 0;
   v_tot_algy_dod            NUMBER := 0;
   v_tot_chem_dod            NUMBER := 0;
   v_tot_fill_dod            NUMBER := 0;
   v_tot_pres_dod            NUMBER := 0;
/*
   v_tot_z03_s               NUMBER := 0;
   v_tot_z03_r               NUMBER := 0;
   v_tot_z04_s               NUMBER := 0;
   v_tot_z04_r               NUMBER := 0;
*/
   --pct successful variables
   v_vha_success_pct         NUMBER := 0;
   v_vha_failure_pct         NUMBER := 0;
   v_tot_vha_z03             NUMBER := 0;
   v_tot_Z04success_vha      NUMBER := 0;
   v_tot_Z04failure_vha      NUMBER := 0;
   v_dod_success_pct         NUMBER := 0;
   v_dod_failure_pct         NUMBER := 0;
   v_tot_dod_z03             NUMBER := 0;
   v_tot_Z04success_dod      NUMBER := 0;
   v_tot_Z04failure_dod      NUMBER := 0;

--Z04 correlated clinical data Z04
  v_tot_vha_z04              NUMBER := 0;
  v_tot_dod_z04              NUMBER := 0;

--Z05,Z06,Z07 message variables
   v_tot_z05s_vha               NUMBER := 0;
   v_tot_z05f_vha               NUMBER := 0;
   v_tot_z06s_vha               NUMBER := 0;
   v_tot_z06f_vha               NUMBER := 0;
   v_tot_z07s_vha               NUMBER := 0;
   v_tot_z07f_vha               NUMBER := 0;
   v_tot_z05s_dod               NUMBER := 0;
   v_tot_z05f_dod               NUMBER := 0;
   v_tot_z06s_dod               NUMBER := 0;
   v_tot_z06f_dod               NUMBER := 0;
   v_tot_z07s_dod               NUMBER := 0;
   v_tot_z07f_dod               NUMBER := 0;

--a24 and a43 /ack message totals
   v_tot_a24s                   NUMBER := 0;
   v_tot_ack_a24s               NUMBER := 0;
   v_tot_a43s                   NUMBER := 0;
   v_tot_ack_a43s               NUMBER := 0;
   
--message totals
   v_totmsgsent              NUMBER := 0;
   v_totmsgrcvd              NUMBER := 0;
   v_totmsgproc              NUMBER := 0;
   v_wkly_adc_count          NUMBER := 0;
      
   CURSOR curADCSummary IS
       select created_date,
           sending_site,
           sum(adc_act_attempt) as adc_act_attempts,
           sum(adc_inact_attempt) as adc_inact_attempts,
           count(distinct message_id) as distinct_attempts
       from (
           select to_char(a.created_date, 'yyyymmdd') as created_date,
               a.sending_site as sending_site,
               case when A.ADDITIONAL_INFO_1 = 'ACTIVE' then 1 else 0 end as adc_act_attempt,
               case when A.ADDITIONAL_INFO_1 = 'INACTIVE' then 1 else 0 end as adc_inact_attempt,
               a.message_id as message_id
           from   chdr2.audited_event a
           where  A.CREATED_DATE between bdate and edate
           and    A.OUTCOME = 1
           and    A.EVENT_TYPE = 'ZCH_Z01'
           and    A.SENDING_SITE = v_va_site 
           and    A.VPID not in ('1013294092V222341',
                                 '1013315517V028320',
                                 '1013021125V518154',
                                 '1013294025V219497',
                                 '1013315140V913383',
                                 '1013315516V299401',
                                 '1013315518V151249',
                                 '1013315550V776742',
                                 '1013315553V589439')
           and    A.RECEIVING_SITE = v_dod_site
          
           union all

           select to_char(a.created_date, 'yyyymmdd') as created_date,
               a.sending_site as sending_site,
               case when A.ADDITIONAL_INFO_1 = 'ACTIVE' then 1 else 0 end as adc_act_attempt,
               case when A.ADDITIONAL_INFO_1 = 'INACTIVE' then 1 else 0 end as adc_inact_attempt,
               a.message_id as message_id
           from   chdr2.audited_event a
           where  A.CREATED_DATE between bdate and edate
           and    A.OUTCOME = 1
           and    A.EVENT_TYPE = 'ZCH_Z01'
           and    A.SENDING_SITE = v_dod_site 
           and    A.ADDITIONAL_ID not in ('0011223366',
                                          '0011223322',
                                          '0011223399',
                                          '0011223388',
                                          '0011223377',
                                          '0011223333',
                                          '0011223311',
                                          '0011223300')
           and    A.RECEIVING_SITE = v_va_site
       )
       group by created_date, sending_site
       order by created_date, sending_site desc
   ;

   CURSOR curADCBreakdown IS
       select msg_date,
           sum(active_attempts) as active_attempts,
           sum(inactive_attempts) as inactive_attempts,
           sum(activations) as activations,
--           sum(inactivations) as inactivations,
           sum(single_match) as single_match,
           sum(no_match) as no_match
       From (
           select to_char(a.created_date,'yyyymmdd') as msg_date,
               case a.additional_info_1 when 'ACTIVE' then 1 else 0 end as active_attempts,
               case a.additional_info_1 when 'INACTIVE' then 1 else 0 end as inactive_attempts,
               case b.additional_info_1 when 'ACTIVE' then 1 else 0 end as activations,
 --              case b.additional_info_1 when 'INACTIVE' then 1 else 0 end as inactivations,
               case b.additional_info_2 when 'Single Match' then 1 else 0 end as single_match,
               case b.additional_info_2 when 'Single Match' then 0 else 1 end as no_match
           from  chdr2.audited_event a, 
                 chdr2.audited_event b
           where A.message_id = B.CORRELATION_ID
           and   a.event_type = 'ZCH_Z01' 
           and   a.sending_site = v_va_site
           and   a.receiving_site = v_dod_site
           and   A.VPID not in ('1013294092V222341',
                                '1013315517V028320',
                                '1013021125V518154',
                                '1013294025V219497',
                                '1013315140V913383',
                                '1013315516V299401',
                                '1013315518V151249',
                                '1013315550V776742',
                                '1013315553V589439')
           and   a.outcome = 1 
           and   b.event_type = 'ZCH_Z02'
           and   b.outcome = 1 -- seitz - do we want all of only successful messages?
           and   a.created_date between bdate and edate
           
           union all
           
           select to_char(a.created_date,'yyyymmdd') as msg_date,
               case a.additional_info_1 when 'ACTIVE' then 1 else 0 end as active_attempts,
               case a.additional_info_1 when 'INACTIVE' then 1 else 0 end as inactive_attempts,
               case b.additional_info_1 when 'ACTIVE' then 1 else 0 end as activations,
--               case b.additional_info_1 when 'INACTIVE' then 1 else 0 end as inactivations,
               case b.additional_info_2 when 'Single Match' then 1 else 0 end as single_match,
               case b.additional_info_2 when 'Single Match' then 0 else 1 end as no_match
           from  chdr2.audited_event a, 
                 chdr2.audited_event b
           where A.message_id = B.CORRELATION_ID
           and   a.event_type = 'ZCH_Z01' 
           and   a.sending_site = v_dod_site
           and   a.receiving_site = v_va_site
           and    A.ADDITIONAL_ID not in ('0011223366',
                                          '0011223322',
                                          '0011223399',
                                          '0011223388',
                                          '0011223377',
                                          '0011223333',
                                          '0011223311',
                                          '0011223300')
           and   a.outcome = 1 
           and   b.event_type = 'ZCH_Z02'
           and   b.outcome = 1
           and   a.created_date between bdate and edate
       )
       group by msg_date
       order by msg_date
   ;


   CURSOR curADCBySite IS
        select created_date, 
            site_id, 
            sum(activation_attempts) as activation_attempts,
            sum(inactivation_attempts) as inactivation_attempts,
            sum(single_match) as single_match,
            sum(no_match) as no_match,
            sum(failed_response) as failed_response
        from (
        SELECT to_char(a.created_date,'yyyymmdd') as created_date, 
            b.name as site_id,
            case a.additional_info_1 when 'ACTIVE' then 1 else 0 end as activation_attempts,
            case a.additional_info_1 when 'INACTIVE' then 1 else 0 end as inactivation_attempts,
            0 as single_match,
            0 as no_match,
            0 as failed_response
        FROM  chdr2.audited_event a, 
              chdr2.STD_INSTITUTION b
        where A.SITE_ID = B.STATIONNUMBER
        and   a.EVENT_TYPE = 'ZCH_Z01'
        and   a.outcome = 1
        and   a.sending_site = v_va_site
        and   a.created_date BETWEEN bdate and edate
        and   A.VPID not in ('1013294092V222341',
                             '1013315517V028320',
                             '1013021125V518154',
                             '1013294025V219497',
                             '1013315140V913383',
                             '1013315516V299401',
                             '1013315518V151249',
                             '1013315550V776742',
                             '1013315553V589439')
        
        union all

        SELECT to_char(b.created_date,'yyyymmdd') as created_date, 
            c.name as site_id,
            0 as activation_attempts, 
            0 as inactivation_attempts,
            case when A.outcome = 1 and A.ADDITIONAL_INFO_1 = 'ACTIVE' and a.additional_info_2 = 'Single Match' then 1 else 0 end as single_match,
            case when A.outcome = 1 and A.ADDITIONAL_INFO_1 = 'INACTIVE' then 1 else 0 end as no_match,
            case when A.outcome = 0 then 1 else 0 end as failed_response
        FROM  chdr2.audited_event a, 
              chdr2.audited_event b,
              chdr2.STD_INSTITUTION c
        WHERE B.SITE_ID = C.STATIONNUMBER
        and   A.CORRELATION_ID = B.MESSAGE_ID 
        and   b.created_date BETWEEN bdate AND edate
        and   b.site_id is not null
        AND   A.EVENT_TYPE = 'ZCH_Z02' and a.sending_site = v_dod_site 
        and   b.EVENT_TYPE = 'ZCH_Z01' and b.outcome = 1 and b.sending_site = v_va_site and b.additional_info_1 = 'ACTIVE' 
        and   b.VPID not in ('1013294092V222341',
                             '1013315517V028320',
                             '1013021125V518154',
                             '1013294025V219497',
                             '1013315140V913383',
                             '1013315516V299401',
                             '1013315518V151249',
                             '1013315550V776742',
                             '1013315553V589439')

        union all

        SELECT to_char(a.created_date,'yyyymmdd') as created_date,  
            v_dod_site_id as site_id,
            case a.additional_info_1 when 'ACTIVE' then 1 else 0 end as activation_attempts,
            case a.additional_info_1 when 'INACTIVE' then 1 else 0 end as inactivation_attempts,
            0 as single_match,
            0 as no_match,
            0 as failed_response
        FROM  chdr2.audited_event a
        WHERE a.EVENT_TYPE = 'ZCH_Z01'
        and  a.outcome = 1
        and  a.created_date BETWEEN bdate AND edate
        and  a.sending_site = v_dod_site
        and  a.ADDITIONAL_ID not in ('0011223366',
                                     '0011223322',
                                     '0011223399',
                                     '0011223388',
                                     '0011223377',
                                     '0011223333',
                                     '0011223311',
                                     '0011223300')

        UNION ALL

        SELECT to_char(b.created_date,'yyyymmdd') as created_date,  
            v_dod_site_id as site_id,
            0 as activation_attempts, 
            0 as inactivation_attempts,
            case when A.outcome = 1 and A.ADDITIONAL_INFO_1 = 'ACTIVE' and a.additional_info_2 = 'Single Match' then 1 else 0 end as single_match,
            case when A.outcome = 1 and A.ADDITIONAL_INFO_1 = 'INACTIVE' then 1 else 0 end as no_match,
            case when A.outcome = 0 then 1 else 0 end as failed_response             
        FROM  chdr2.audited_event a, 
              chdr2.audited_event b 
        WHERE A.CORRELATION_ID = B.MESSAGE_ID 
        and   b.created_date BETWEEN bdate AND edate
        AND   A.EVENT_TYPE = 'ZCH_Z02' and a.sending_site = v_va_site
        and   b.EVENT_TYPE = 'ZCH_Z01' and b.outcome = 1 and b.sending_site = v_dod_site and b.additional_info_1 = 'ACTIVE'
        and   b.ADDITIONAL_ID not in ('0011223366',
                                      '0011223322',
                                      '0011223399',
                                      '0011223388',
                                      '0011223377',
                                      '0011223333',
                                      '0011223311',
                                      '0011223300')
        )
        group by created_date, site_id
        order by created_date asc, site_id asc
    ;

    --cursor retrieving counts by message type sent by VA
    CURSOR curZ03_Z04 IS
        select created_date as created_date,
            site_id as site_id,
            sum(algy) as algy,
            sum(chem) as chem,
            sum(fill) as fill,
            sum(pres) as pres,
            sum(z04_success) as z04_success,
            sum(z04_failure) as z04_failure
        From (
            SELECT to_char(a.created_date,'yyyymmdd') as created_date,  
                   sending_site as site_id,
                   case when a.EVENT_TYPE = 'ALGY' then 1 else 0 end as algy, 
                   case when a.EVENT_TYPE = 'CHEM' then 1 else 0 end as chem, 
                   case when a.EVENT_TYPE = 'FILL' then 1 else 0 end as fill, 
                   case when a.EVENT_TYPE = 'PRES' then 1 else 0 end as pres,
                   0 as z04_success,
                   0 as z04_failure
            FROM   chdr2.audited_event a
            WHERE  a.EVENT_TYPE in ('ALGY','CHEM','FILL','PRES')
            and    a.created_date BETWEEN bdate AND edate
            and    a.outcome = 1
            and    a.sending_site in (v_va_site, v_dod_site)
            and    a.receiving_site in (v_va_site, v_dod_site)

            
            union all

            SELECT to_char(a.created_date,'yyyymmdd') as created_date,  
                   a.receiving_site as site_id,
                   0 as algy, 
                   0 as chem, 
                   0 as fill, 
                   0 as pres,
                   sum(case when a.outcome = 1 then 1 else 0 end) as z04_success,
                   sum(case when a.outcome = 0 then 1 else 0 end) as z04_failure
            FROM   chdr2.audited_event a
            WHERE  a.EVENT_TYPE = 'ZCH_Z04'
            and    a.created_date BETWEEN bdate AND edate
            and    a.sending_site = v_dod_site
            and    a.receiving_site = v_va_site
            group by created_date, a.receiving_site
        
            union all

            SELECT to_char(a.created_date,'yyyymmdd') as created_date,  
                   a.receiving_site as site_id,
                   0 as algy, 
                   0 as chem, 
                   0 as fill, 
                   0 as pres,
                   sum(case when a.outcome = 1 then 1 else 0 end) as z04_success,
                   sum(case when a.outcome = 0 then 1 else 0 end) as z04_failure
            FROM   chdr2.audited_event a
            WHERE  a.EVENT_TYPE = 'ZCH_Z04'
            and    a.created_date BETWEEN bdate AND edate
            and    a.sending_site = v_va_site
            and    a.receiving_site = v_dod_site
            group by created_date, a.receiving_site
    )
    group by created_date, site_id
    order by created_date, site_id desc
    ;

   CURSOR curCorrelated_Z04 IS
      select created_date as created_date,
             sending_site as sending_site,
             sum(algy) as algy,
             sum(fill) as fill,
             sum(pres) as pres,
             sum(z04_success) as z04_success,
             sum(z04_failure) as z04_failure
      From (
        select to_char(z4.created_date,'yyyymmdd') as created_date,
               z4.sending_site as sending_site,
               CASE z3.event_type when 'ALGY' then 1 else 0 end as algy,
               CASE z3.event_type when 'FILL' then 1 else 0 end as fill,
               CASE z3.event_type when 'PRES' then 1 else 0 end as pres,
               z4.outcome as z04_success,
               CASE z4.outcome when 0 then 1 else 0 end as z04_failure
        from chdr2.audited_event z3, chdr2.audited_event z4
        where z3.message_id = z4.correlation_id
              and   z4.CREATED_DATE BETWEEN bdate AND edate
              and   z3.event_type in ('FILL','PRES','PREF','ALGY')
      )
      group by created_date, sending_site
      order by created_date, sending_site desc
  ;

--cursor for batch message exchange. Note we are NOT excluding test patients because the vpid and additional_id columns
--are not populated with Z07s, is populated in the opposite order with Z05s (DoD->VA has the vpis populated) and is in line
--with the sending site with Z06s
    CURSOR curZ05_Z06_Z07 IS
       select created_date,
           sending_site,
           sum(z05_success) as z05_success,
           sum(z05_failure) as z05_failure,
           sum(z06_success) as z06_success,
           sum(z06_failure) as z06_failure,
           sum(z07_success) as z07_success,
           sum(z07_failure) as z07_failure
       from (
           select to_char(a.created_date, 'yyyymmdd') as created_date,
               a.sending_site as sending_site,
               case when A.outcome = 1 and a.event_type = 'QBP_Z05' then 1 else 0 end as z05_success,
               case when A.outcome = 0 and a.event_type = 'QBP_Z05' then 1 else 0 end as z05_failure,
               case when A.outcome = 1 and a.event_type = 'RSP_Z06' then 1 else 0 end as z06_success,
               case when A.outcome = 0 and a.event_type = 'RSP_Z06' then 1 else 0 end as z06_failure,
               case when A.outcome = 1 and a.event_type = 'ZCH_Z07' then 1 else 0 end as z07_success,
               case when A.outcome = 0 and a.event_type = 'ZCH_Z07' then 1 else 0 end as z07_failure
           from   chdr2.audited_event a
           where  A.CREATED_DATE between bdate and edate
           and    A.EVENT_TYPE in ('QBP_Z05','RSP_Z06','ZCH_Z07')
           and    A.SENDING_SITE = v_va_site 
           and    A.RECEIVING_SITE = v_dod_site
          
           union all

           select to_char(a.created_date, 'yyyymmdd') as created_date,
               a.sending_site as sending_site,
               case when A.outcome = 1 and a.event_type = 'QBP_Z05' then 1 else 0 end as z05_success,
               case when A.outcome = 0 and a.event_type = 'QBP_Z05' then 1 else 0 end as z05_failure,
               case when A.outcome = 1 and a.event_type = 'RSP_Z06' then 1 else 0 end as z06_success,
               case when A.outcome = 0 and a.event_type = 'RSP_Z06' then 1 else 0 end as z06_failure,
               case when A.outcome = 1 and a.event_type = 'ZCH_Z07' then 1 else 0 end as z07_success,
               case when A.outcome = 0 and a.event_type = 'ZCH_Z07' then 1 else 0 end as z07_failure
           from   chdr2.audited_event a
           where  A.CREATED_DATE between bdate and edate
           and    A.EVENT_TYPE in ('QBP_Z05','RSP_Z06','ZCH_Z07')
           and    A.SENDING_SITE = v_dod_site 
           and    A.RECEIVING_SITE = v_va_site
       )
       group by created_date, sending_site
       order by created_date, sending_site desc
   ;

   CURSOR curA24_A43_ACKS IS
       select created_date as created_date,
        sending_site as sending_site,
        receiving_site as receiving_site,
        sum(a24s) as a24s,
        sum(ack_a24s) as ack_a24s,
        sum(a43s) as a43s,
        sum(ack_a43s) as ack_a43s
    from (
       select a.message_id, to_char(trunc(a.created_date), 'yyyymmdd') as created_date,
            trim(A.SENDING_SITE) as sending_site, 
            trim(A.RECEIVING_SITE) as receiving_site,
            case when a.event_type = 'ADT_A24' then 1 else 0 end as a24s,
            case when a.event_type = 'ADT_A24' then 1 else 0 end as ack_a24s,
            case when a.event_type = 'ADT_A43' then 1 else 0 end as a43s,
            case when a.event_type = 'ADT_A43' then 1 else 0 end as ack_a43s
        from  chdr2.audited_event a
        where trim(a.sending_site)  in (v_va_site, v_mpi_site)
        and   trim(a.receiving_site)  in (v_va_site, v_dod_site)
        and   A.event_type in ('ADT_A24','ADT_A43')
        and   A.CREATED_DATE between bdate and edate
        and exists (
            select * from chdr2.audited_event b
            where  a.message_id = b.message_id
            and    rtrim(b.sending_site)  in (v_va_site, v_dod_site)
            and    b.event_type like 'ACK%'
        )
        
        union all
        
       select a.message_id, to_char(trunc(a.created_date), 'yyyymmdd') as created_date,
            trim(A.SENDING_SITE) as sending_site, 
            trim(A.RECEIVING_SITE) as receiving_site,
            case when a.event_type = 'ADT_A24' then 1 else 0 end as a24s,
            case when a.event_type = 'ADT_A24' then 1 else 0 end as ack_a24s,
            case when a.event_type = 'ADT_A43' then 1 else 0 end as a43s,
            case when a.event_type = 'ADT_A43' then 1 else 0 end as ack_a43s
        from  chdr2.audited_event a
        where trim(a.sending_site)  in (v_va_site, v_mpi_site)
        and   trim(a.receiving_site)  in (v_va_site, v_dod_site)
        and   A.event_type in ('ADT_A24','ADT_A43')
        and   A.CREATED_DATE between bdate and edate
        and not exists (
            select * from chdr2.audited_event b
            where  a.message_id = b.message_id
            and    rtrim(b.sending_site)  in (v_va_site, v_dod_site)
            and    b.event_type like 'ACK%'
        )
    )
    group by created_date, sending_site, receiving_site
    order by created_date, sending_site
    ;
  
  CURSOR curADCWeeklyBreakdown IS
  select to_char(A.EFFECTIVE_DATE,'YYYY - WW') as week_number, 
      to_char(min(trunc(A.EFFECTIVE_DATE)),'MON dd') as week_start_date, 
      count(*) as weekly_count
  from chdr2.patient_identity_xref a
  where a.status = 1
  group by to_char(A.EFFECTIVE_DATE,'YYYY - WW') 
  order by to_char(A.EFFECTIVE_DATE,'YYYY - WW') asc
  ;
    
BEGIN
    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="rpt">');
    -- end - html output template

    --Display the heading with the date range that is being reported on
    --check the v_lookback_days and if it is -1 then run this as a monthly report
    if (v_lookback_days = -1) then
        edate := trunc(sysdate - to_number(to_char(sysdate,'dd')) + 1) - 1/86400;
        bdate := to_date(to_char(edate,'yyyymm') || '01','yyyymmdd');
        DBMS_OUTPUT.put_line ('<H4>CHDR Message Flow Analysis for<br>' || to_char(bdate, 'Month yyyy') || '</H4>');    
    elsif (v_lookback_days > 1) then
        DBMS_OUTPUT.put_line ('<H4>CHDR Message Flow Analysis for<br>' || to_char(bdate, 'Month dd, yyyy') || ' Thru ' || to_char(edate - 1, 'Month dd, yyyy') || '</H4>');
    else
        if (v_lookback_days = 0) then
            edate := sysdate;
            DBMS_OUTPUT.put_line ('<H4>CHDR Message Flow Analysis from midnight on<br>' || to_char(bdate, 'Month dd, yyyy') || ' until ' || to_char(edate, 'Month dd, yyyy hh24:mi:ss') || '</H4>');
        else
            DBMS_OUTPUT.put_line ('<H4>CHDR Message Flow Analysis for<br>' || to_char(bdate, 'Month dd, yyyy') || '</H4>');
        end if;
    end if;

    if (v_lookback_days != 0) then
        v_date_range_days := edate - bdate;
    end if;
    
    --ADC Summary Table
    DBMS_OUTPUT.put_line ('<div class="section">Active Dual Consumer (ADC) Summary</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing=0>');
    DBMS_OUTPUT.put_line ('<tr><th width="14%"><br>Create Date</th>');
    DBMS_OUTPUT.put_line ('<th width="26%"><br>Sending Site</th>');
    DBMS_OUTPUT.put_line ('<th width="20%">Activation<br>Attempts</th>');
    DBMS_OUTPUT.put_line ('<th width="20%">Inactivation<br>Attempts</th>');
    DBMS_OUTPUT.put_line ('<th width="20%">Distinct<br>Attempts</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curADCSummary LOOP
        v_ddd := to_number(to_char(to_date(recResults.created_date, 'yyyymmdd'),'DDD'));
    
        if (v_date_range_days > 1) then
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
        
        if (recResults.sending_site = v_va_site) then
            v_site_name := 'VA';
        else        
            v_site_name := 'DoD';
        end if;
        
        if (v_date_range_days > 1 and v_last_ddd = v_ddd) then
            DBMS_OUTPUT.put_line ('<td></td>');
        else
            DBMS_OUTPUT.put_line ('<td>' || to_date(recResults.created_date,'yyyymmdd') ||'</td>');
        end if;
        
        v_last_ddd := v_ddd;
        DBMS_OUTPUT.put_line ('<td>' || v_site_name ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.adc_act_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.adc_inact_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.distinct_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');
        v_tot_adc_act_attempts := v_tot_adc_act_attempts + recResults.adc_act_attempts;
        v_tot_adc_inact_attempts := v_tot_adc_inact_attempts + recResults.adc_inact_attempts;
        v_tot_distinct_attempts := v_tot_distinct_attempts + recResults.distinct_attempts;
    END LOOP;

    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td colspan="2"><br>Totals</td>');
    DBMS_OUTPUT.put_line ('<td><br>' || v_tot_adc_act_attempts ||'</td>');
    DBMS_OUTPUT.put_line ('<td><br>' || v_tot_adc_inact_attempts ||'</td>');
    DBMS_OUTPUT.put_line ('<td><br>' || v_tot_distinct_attempts ||'</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');
    
    --ADC Breakdown Table
    DBMS_OUTPUT.put_line ('<div class="section">Active Dual Consumer (ADC) Match Breakdown</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing="0">');
    DBMS_OUTPUT.put_line ('<tr><th width="14%"><br>Create Date</th>');
    DBMS_OUTPUT.put_line ('<th width="14%">Activation<br>Attempts</th>');
    DBMS_OUTPUT.put_line ('<th width="14%">Inactivation<br>Attempts</th>');
    DBMS_OUTPUT.put_line ('<th width="14%"><br>Activations</th>');
--    DBMS_OUTPUT.put_line ('<th width="14%"><br>Inactivations</th>');
    DBMS_OUTPUT.put_line ('<th width="14%">Single<br>Match</th>');
    DBMS_OUTPUT.put_line ('<th width="16%">No<br>Match</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curADCBreakdown LOOP
        v_ddd := to_number(to_char(to_date(recResults.msg_date, 'yyyymmdd'),'DDD'));
    
        if (v_date_range_days > 1) then
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
        if (v_date_range_days > 1 and v_last_ddd = v_ddd) then
            DBMS_OUTPUT.put_line ('<td></td>');
        else
            DBMS_OUTPUT.put_line ('<td>' || to_date(recResults.msg_date,'yyyymmdd') ||'</td>');
        end if;
        
        v_last_ddd := v_ddd;
        DBMS_OUTPUT.put_line ('<td>' || recResults.active_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.inactive_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.activations ||'</td>');
 --       DBMS_OUTPUT.put_line ('<td>' || recResults.inactivations ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.single_match ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.no_match ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');
        v_tot_active_attempts := v_tot_active_attempts + recResults.active_attempts;
        v_tot_inactive_attempts := v_tot_inactive_attempts + recResults.inactive_attempts;
        v_tot_activations := v_tot_activations + recResults.activations;
--        v_tot_inactivations := v_tot_inactivations + recResults.inactivations;
        v_tot_single_match := v_tot_single_match + recResults.single_match;
        v_tot_no_match := v_tot_no_match + recResults.no_match;
    END LOOP;

    -- total the results
    if (v_date_range_days > 1) then
        DBMS_OUTPUT.put_line ('<tr class="totals">');
        DBMS_OUTPUT.put_line ('<td><br>Totals</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_active_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_inactive_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_activations ||'</td>');
 --       DBMS_OUTPUT.put_line ('<td><br>' || v_tot_inactivations ||'</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_single_match ||'</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_no_match ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');
    end if;
    
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');
  
    --ADC Site Breakdown Table
    DBMS_OUTPUT.put_line ('<div class="section">Active Dual Consumer (ADC) Breakdown By Sending Site</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing="0">');
    DBMS_OUTPUT.put_line ('<tr><th width="14%"><br>Create Date</th>');
    DBMS_OUTPUT.put_line ('<th width="26%"><br>Sending Site</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Active<br>Attempts</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Inactive<br>Attempts</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Single<br>Match</th>');
    DBMS_OUTPUT.put_line ('<th width="12%"><br>No Match</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Failed<br>Z02 Response</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curADCBySite LOOP
        v_ddd := to_number(to_char(to_date(recResults.created_date, 'yyyymmdd'),'DDD'));
    
        if (v_date_range_days > 1) then
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
        if (recResults.site_id = v_dod_site_id) then
            v_site_name := 'DoD';
        else
            v_site_name := recResults.site_id;
        end if;

        if (v_date_range_days > 1 and v_last_ddd = v_ddd) then
            DBMS_OUTPUT.put_line ('<td colspan="2">' || v_site_name ||'</td>');
        else
            DBMS_OUTPUT.put_line ('<td>' || to_date(recResults.created_date,'yyyymmdd') ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || v_site_name ||'</td>');
        end if;
        
        v_last_ddd := v_ddd;
        DBMS_OUTPUT.put_line ('<td>' || recResults.activation_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.inactivation_attempts ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.single_match ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.no_match ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.failed_response ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');

        if (recResults.site_id = v_dod_site_id) then
            v_tot_dod_act_attempts := v_tot_dod_act_attempts + recResults.activation_attempts;
            v_tot_dod_inact_attempts := v_tot_dod_inact_attempts + recResults.inactivation_attempts;
            v_tot_dod_single_match := v_tot_dod_single_match + recResults.single_match;
            v_tot_dod_no_match := v_tot_dod_no_match + recResults.no_match;
            v_tot_dod_failed_response := v_tot_dod_failed_response + recResults.failed_response;
        else
            v_tot_va_act_attempts := v_tot_va_act_attempts + recResults.activation_attempts;
            v_tot_va_inact_attempts := v_tot_va_inact_attempts + recResults.inactivation_attempts;
            v_tot_va_single_match := v_tot_va_single_match + recResults.single_match;
            v_tot_va_no_match := v_tot_va_no_match + recResults.no_match;
            v_tot_va_failed_response := v_tot_va_failed_response + recResults.failed_response;
        end if;

    END LOOP;
    
    if (v_tot_dod_act_attempts > 0) then
        v_dod_adc_success_pct := round((v_tot_dod_single_match / v_tot_dod_act_attempts) * 100, 2);
        v_dod_adc_attempt_pct := round((v_tot_dod_act_attempts / (v_tot_dod_act_attempts + v_tot_va_act_attempts)) * 100, 2);
    end if;

    if (v_tot_va_act_attempts > 0) then
        v_vha_adc_success_pct := round((v_tot_va_single_match / v_tot_va_act_attempts) * 100, 2);
        v_vha_adc_attempt_pct := round((v_tot_va_act_attempts / (v_tot_dod_act_attempts + v_tot_va_act_attempts)) * 100, 2);
    end if;

    -- total the results
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td colspan="2" valign="top"><br>VA</td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_va_act_attempts || '<br><span class="pct">' || v_vha_adc_attempt_pct || '%</span></td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_va_inact_attempts || '</td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_va_single_match || '<br><span class="pct">' || v_vha_adc_success_pct || '%</span></td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_va_no_match || '</td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_va_failed_response || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td colspan="2" valign="top"><br>DoD</td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_dod_act_attempts || '<br><span class="pct">' || v_dod_adc_attempt_pct || '%</span></td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_dod_inact_attempts ||'</td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_dod_single_match || '<br><span class="pct">' || v_dod_adc_success_pct || '%</span></td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_dod_no_match ||'</td>');
    DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_dod_failed_response || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td class="totals" colspan="2"><br>Totals</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_dod_act_attempts + v_tot_va_act_attempts) ||'</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_dod_inact_attempts + v_tot_va_inact_attempts) ||'</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_dod_single_match + v_tot_va_single_match) ||'</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_dod_no_match + v_tot_va_no_match) ||'</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_dod_failed_response + v_tot_va_failed_response) ||'</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');

    --Clinical Message exchange (Z03/Z04)
    DBMS_OUTPUT.put_line ('<div class="section">Clinical Message Exchange By Sending Site</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing="0">');
    DBMS_OUTPUT.put_line ('<tr><th width="14%"><br>Create Date</th>');
    DBMS_OUTPUT.put_line ('<th width="8%">Sending<br>Site</th>');
    DBMS_OUTPUT.put_line ('<th width="12%"><br>Allergy</th>');
    DBMS_OUTPUT.put_line ('<th width="12%"><br>Lab</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Pharmacy<br>Fill</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Pharmacy<br>Order</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Successful<br>Z04 Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Failed<br>Z04 Rcvd</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curZ03_Z04 LOOP
        v_ddd := to_number(to_char(to_date(recResults.created_date, 'yyyymmdd'),'DDD'));
    
        if (v_date_range_days > 1) then
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
        if (v_date_range_days > 1 and v_last_ddd = v_ddd) then
            DBMS_OUTPUT.put_line ('<td></td>');
        else
            DBMS_OUTPUT.put_line ('<td>' || to_date(recResults.created_date,'yyyymmdd') ||'</td>');
        end if;
        
        v_last_ddd := v_ddd;

        if (recResults.site_id = v_va_site) then
            v_site_name  := 'VA';
        else
            v_site_name := 'DoD';
        end if;
        
        DBMS_OUTPUT.put_line ('<td>' || v_site_name ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.algy ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.chem ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.fill ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.pres ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z04_success ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z04_failure ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');

        if (recResults.site_id = v_va_site) then
            v_tot_algy_vha := v_tot_algy_vha + recResults.algy;
            v_tot_chem_vha := v_tot_chem_vha + recResults.chem;
            v_tot_fill_vha := v_tot_fill_vha + recResults.fill;
            v_tot_pres_vha := v_tot_pres_vha + recResults.pres;
            v_tot_Z04success_vha := v_tot_Z04success_vha + recResults.z04_success;
            v_tot_Z04failure_vha := v_tot_Z04failure_vha + recResults.z04_failure;
        else
            v_tot_algy_dod := v_tot_algy_dod + recResults.algy;
            v_tot_chem_dod := v_tot_chem_dod + recResults.chem;
            v_tot_fill_dod := v_tot_fill_dod + recResults.fill;
            v_tot_pres_dod := v_tot_pres_dod + recResults.pres;
            v_tot_Z04success_dod := v_tot_Z04success_dod + recResults.z04_success;
            v_tot_Z04failure_dod := v_tot_Z04failure_dod + recResults.z04_failure - recResults.chem;--change this with chem addition
        end if;

    END LOOP;
    
    -- total the results
    if (v_date_range_days > 1) then
        v_tot_vha_z03 := v_tot_algy_vha + v_tot_fill_vha + v_tot_pres_vha;
        v_tot_dod_z03 := v_tot_algy_dod + v_tot_fill_dod + v_tot_pres_dod;
        
        if (v_tot_vha_z03 > 0) then
            v_vha_success_pct := round((v_tot_Z04success_vha / v_tot_vha_z03) * 100, 2);
            v_vha_failure_pct := round((v_tot_Z04failure_vha / v_tot_vha_z03) * 100, 2);
        end if;

        if (v_tot_dod_z03 > 0) then
            v_dod_success_pct := round((v_tot_Z04success_dod / v_tot_dod_z03) * 100, 2);
            v_dod_failure_pct := round((v_tot_Z04failure_dod / v_tot_dod_z03) * 100, 2);
        end if;
        
        DBMS_OUTPUT.put_line ('<tr class="totals">');
        DBMS_OUTPUT.put_line ('<td colspan="2" valign="top"><br>VA</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_algy_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_chem_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_fill_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_pres_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04success_vha || '<br><span class="pct">' || v_vha_success_pct || '%</span></td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04failure_vha || '<br><span class="pct">' || v_vha_failure_pct || '%</span></td>');
        DBMS_OUTPUT.put_line ('</tr>');
        DBMS_OUTPUT.put_line ('<tr class="totals">');
        DBMS_OUTPUT.put_line ('<td colspan="2" valign="top"><br>DoD</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_algy_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_chem_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_fill_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_pres_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04success_dod || '<br><span class="pct">' || v_dod_success_pct || '%</span></td>');
        DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04failure_dod || '<br><span class="pct">' || v_dod_failure_pct || '%</span></td>');
        DBMS_OUTPUT.put_line ('</tr>');
    end if;
    
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td class="totals" colspan="2"><br>Totals</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_algy_dod + v_tot_algy_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_chem_dod + v_tot_chem_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_fill_dod + v_tot_fill_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_pres_dod + v_tot_pres_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_Z04success_dod + v_tot_Z04success_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_Z04failure_dod + v_tot_Z04failure_vha) || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('<br><span class="note">Note: The percentages reported EXCLUDE lab messages from the DoD calculations</span><br>');
    DBMS_OUTPUT.put_line ('<span class="note">Note: The percentages reported may not add up to 100% due to duplication of failed messages.</span><br>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');

    --Correlated Clinical Updates by event type (Z04)
    --reset variables used in previous report section to track counts
    v_tot_algy_vha := 0;
    v_tot_fill_vha := 0;
    v_tot_pres_vha := 0;
    v_tot_Z04success_vha := 0;
    v_tot_Z04failure_vha := 0;
    v_tot_algy_dod := 0;
    v_tot_fill_dod := 0;
    v_tot_pres_dod := 0;
    v_tot_Z04success_dod := 0;
    v_tot_Z04failure_dod := 0;

    --Correlated Clinical Message exchange (Z03/Z04)
    DBMS_OUTPUT.put_line ('<div class="section">Correlated Clinical Message Exchange By Z04 Sending Site</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing="0">');
    DBMS_OUTPUT.put_line ('<tr><th width="14%"><br>Z04 Response Date</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">Z04 Sending<br>Site</th>');
    DBMS_OUTPUT.put_line ('<th width="15%"><br>Allergy</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Pharmacy<br>Fill</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Pharmacy<br>Order</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Successful<br>Z04 Rcvd</th>');
    DBMS_OUTPUT.put_line ('<th width="15%">Failed<br>Z04 Rcvd</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curCorrelated_Z04 LOOP
      v_ddd := to_number(to_char(to_date(recResults.created_date, 'yyyymmdd'),'DDD'));

      if (v_date_range_days > 1) then
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
      if (v_date_range_days > 1 and v_last_ddd = v_ddd) then
        DBMS_OUTPUT.put_line ('<td></td>');
      else
        DBMS_OUTPUT.put_line ('<td>' || to_date(recResults.created_date,'yyyymmdd') ||'</td>');
      end if;

      v_last_ddd := v_ddd;

      if (recResults.sending_site = v_va_site) then
        v_site_name  := 'VA';
      else
        v_site_name := 'DoD';
      end if;

      DBMS_OUTPUT.put_line ('<td>' || v_site_name ||'</td>');
      DBMS_OUTPUT.put_line ('<td>' || recResults.algy ||'</td>');
      DBMS_OUTPUT.put_line ('<td>' || recResults.fill ||'</td>');
      DBMS_OUTPUT.put_line ('<td>' || recResults.pres ||'</td>');
      DBMS_OUTPUT.put_line ('<td>' || recResults.z04_success ||'</td>');
      DBMS_OUTPUT.put_line ('<td>' || recResults.z04_failure ||'</td>');
      DBMS_OUTPUT.put_line ('</tr>');

      if (recResults.sending_site = v_va_site) then
        v_tot_algy_vha := v_tot_algy_vha + recResults.algy;
        v_tot_fill_vha := v_tot_fill_vha + recResults.fill;
        v_tot_pres_vha := v_tot_pres_vha + recResults.pres;
        v_tot_Z04success_vha := v_tot_Z04success_vha + recResults.z04_success;
        v_tot_Z04failure_vha := v_tot_Z04failure_vha + recResults.z04_failure;
      else
        v_tot_algy_dod := v_tot_algy_dod + recResults.algy;
        v_tot_fill_dod := v_tot_fill_dod + recResults.fill;
        v_tot_pres_dod := v_tot_pres_dod + recResults.pres;
        v_tot_Z04success_dod := v_tot_Z04success_dod + recResults.z04_success;
        v_tot_Z04failure_dod := v_tot_Z04failure_dod + recResults.z04_failure;
      end if;

    END LOOP;

  -- total the results
    if (v_date_range_days > 1) then
      v_tot_vha_z04 := v_tot_algy_vha + v_tot_fill_vha + v_tot_pres_vha;
      v_tot_dod_z04 := v_tot_algy_dod + v_tot_fill_dod + v_tot_pres_dod;

      if (v_tot_vha_z04 > 0) then
        v_vha_success_pct := round((v_tot_Z04success_vha / v_tot_vha_z04) * 100, 2);
        v_vha_failure_pct := round((v_tot_Z04failure_vha / v_tot_vha_z04) * 100, 2);
      end if;

      if (v_tot_dod_z04 > 0) then
        v_dod_success_pct := round((v_tot_Z04success_dod / v_tot_dod_z04) * 100, 2);
        v_dod_failure_pct := round((v_tot_Z04failure_dod / v_tot_dod_z04) * 100, 2);
      end if;

      DBMS_OUTPUT.put_line ('<tr class="totals">');
      DBMS_OUTPUT.put_line ('<td colspan="2" valign="top"><br>VA</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_algy_vha || '</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_fill_vha || '</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_pres_vha || '</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04success_vha || '<br><span class="pct">' || v_vha_success_pct || '%</span></td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04failure_vha || '<br><span class="pct">' || v_vha_failure_pct || '%</span></td>');
      DBMS_OUTPUT.put_line ('</tr>');
      DBMS_OUTPUT.put_line ('<tr class="totals">');
      DBMS_OUTPUT.put_line ('<td colspan="2" valign="top"><br>DoD</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_algy_dod || '</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_fill_dod || '</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_pres_dod || '</td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04success_dod || '<br><span class="pct">' || v_dod_success_pct || '%</span></td>');
      DBMS_OUTPUT.put_line ('<td valign="top"><br>' || v_tot_Z04failure_dod || '<br><span class="pct">' || v_dod_failure_pct || '%</span></td>');
      DBMS_OUTPUT.put_line ('</tr>');
    end if;

    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td class="totals" colspan="2"><br>Totals</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_algy_dod + v_tot_algy_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_fill_dod + v_tot_fill_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_pres_dod + v_tot_pres_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_Z04success_dod + v_tot_Z04success_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_Z04failure_dod + v_tot_Z04failure_vha) || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');

    --batch message exchange (Z05-Z07)    
    DBMS_OUTPUT.put_line ('<div class="section">Batch Message Exchange By Sending Site</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing="0">');
    DBMS_OUTPUT.put_line ('<tr><th width="14%"><br>Create Date</th>');
    DBMS_OUTPUT.put_line ('<th width="14%"><br>Sending Site</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z05<br>Success</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z05<br>Failure</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z06<br>Success</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z06<br>Failure</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z07<br>Success</th>');
    DBMS_OUTPUT.put_line ('<th width="12%">Z07<br>Failure</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curZ05_Z06_Z07 LOOP
        v_ddd := to_number(to_char(to_date(recResults.created_date, 'yyyymmdd'),'DDD'));
    
        if (v_date_range_days > 1) then
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
        if (v_date_range_days > 1 and v_last_ddd = v_ddd) then
            DBMS_OUTPUT.put_line ('<td></td>');
        else
            DBMS_OUTPUT.put_line ('<td>' || to_date(recResults.created_date,'yyyymmdd') ||'</td>');
        end if;
        
        v_last_ddd := v_ddd;

        if (recResults.sending_site = v_va_site) then
            v_site_name  := 'VA';
        else
            v_site_name := 'DoD';
        end if;
        
        DBMS_OUTPUT.put_line ('<td>' || v_site_name ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z05_success ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z05_failure ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z06_success ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z06_failure ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z07_success ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.z07_failure ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');

        if (recResults.sending_site = v_va_site) then
            v_tot_z05s_vha := v_tot_z05s_vha + recResults.z05_success;
            v_tot_z05f_vha := v_tot_z05f_vha + recResults.z05_failure;
            v_tot_z06s_vha := v_tot_z06s_vha + recResults.z06_success;
            v_tot_z06f_vha := v_tot_z06f_vha + recResults.z06_failure;
            v_tot_z07s_vha := v_tot_z07s_vha + recResults.z07_success;
            v_tot_z07f_vha := v_tot_z07f_vha + recResults.z07_failure;
        else
            v_tot_z05s_dod := v_tot_z05s_dod + recResults.z05_success;
            v_tot_z05f_dod := v_tot_z05f_dod + recResults.z05_failure;
            v_tot_z06s_dod := v_tot_z06s_dod + recResults.z06_success;
            v_tot_z06f_dod := v_tot_z06f_dod + recResults.z06_failure;
            v_tot_z07s_dod := v_tot_z07s_dod + recResults.z07_success;
            v_tot_z07f_dod := v_tot_z07f_dod + recResults.z07_failure;
        end if;

    END LOOP;
    
    -- total the results
    if (v_date_range_days > 1) then
        DBMS_OUTPUT.put_line ('<tr class="totals">');
        DBMS_OUTPUT.put_line ('<td colspan="2"><br>VA</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z05s_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z05f_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z06s_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z06f_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z07s_vha || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z07f_vha || '</td>');
        DBMS_OUTPUT.put_line ('</tr>');
        DBMS_OUTPUT.put_line ('<tr class="totals">');
        DBMS_OUTPUT.put_line ('<td colspan="2"><br>DoD</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z05s_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z05f_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z06s_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z06f_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z07s_dod || '</td>');
        DBMS_OUTPUT.put_line ('<td><br>' || v_tot_z07f_dod || '</td>');
        DBMS_OUTPUT.put_line ('</tr>');
    end if;

    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td class="totals" colspan="2"><br>Totals</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_z05s_dod + v_tot_z05s_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_z05f_dod + v_tot_z05f_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_z06s_dod + v_tot_z06s_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_z06f_dod + v_tot_z06f_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_z07s_dod + v_tot_z07s_vha) || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || (v_tot_z07f_dod + v_tot_z07f_vha) || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');

    DBMS_OUTPUT.put_line ('<div class="section">ADT_A24/ACK_A24 Merge Message Exchange</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing="0">');
    DBMS_OUTPUT.put_line ('<tr><th width="14%"><br>Create Date</th>');
    DBMS_OUTPUT.put_line ('<th width="23%"><br>Sending Site</th>');
    DBMS_OUTPUT.put_line ('<th width="23%"><br>Receiving Site</th>');
    DBMS_OUTPUT.put_line ('<th width="10%"><br>A24s</th>');
    DBMS_OUTPUT.put_line ('<th width="10%">A24<br>ACKs</th>');
    DBMS_OUTPUT.put_line ('<th width="10%"><br>A43s</th>');
    DBMS_OUTPUT.put_line ('<th width="10%">A43<br>ACKs</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curA24_A43_ACKS LOOP
        v_ddd := to_number(to_char(to_date(recResults.created_date, 'yyyymmdd'),'DDD'));
    
        if (v_date_range_days > 1) then
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
        if (v_date_range_days > 1 and v_last_ddd = v_ddd) then
            DBMS_OUTPUT.put_line ('<td colspan="2">' || recResults.sending_site ||'</td>');
        else
            DBMS_OUTPUT.put_line ('<td>' || to_date(recResults.created_date,'yyyymmdd') ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || recResults.sending_site ||'</td>');
        end if;
        
        v_last_ddd := v_ddd;
        DBMS_OUTPUT.put_line ('<td>' || recResults.receiving_site ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.a24s ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.ack_a24s ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.a43s ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.ack_a43s ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');
        v_tot_a24s := v_tot_a24s + recResults.a24s;
        v_tot_ack_a24s := v_tot_ack_a24s + recResults.ack_a24s;
        v_tot_a43s := v_tot_a43s + recResults.a43s;
        v_tot_ack_a43s := v_tot_ack_a43s + recResults.ack_a43s;
    end loop;
    
    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td class="totals" colspan="3"><br>Totals</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || v_tot_a24s || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || v_tot_ack_a24s || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || v_tot_a43s || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals"><br>' || v_tot_ack_a43s || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div><br>');
    

    --if this is at least a weekly report run then get the running ADC counts
    if (edate - bdate >= 7) then
        DBMS_OUTPUT.put_line ('<h4>VA CHDR ADC RUNNING WEEKLY BREAKDOWN</h4>');
        DBMS_OUTPUT.put_line ('<div class="section">Weekly Breakdown of Active ADC Patients</div>');
        DBMS_OUTPUT.put_line ('<div class="rpt_display">');
        DBMS_OUTPUT.put_line ('<table class="display" cellspacing=0>');
        DBMS_OUTPUT.put_line ('<tr><th width="16%"><br>Year - Week</th>');
        DBMS_OUTPUT.put_line ('<th width="12%">Week<br>Start Date</th>');
        DBMS_OUTPUT.put_line ('<th width="12%">Weekly<br>ADC Count</th>');
        DBMS_OUTPUT.put_line ('<th width="12%">Running<br>ADC Total</th>');
        DBMS_OUTPUT.put_line ('<th width="48%"></th>');
        DBMS_OUTPUT.put_line ('</tr>');

        FOR recResults in curADCWeeklyBreakdown Loop
            if (MOD(v_greenbar, 2) > 0) then
                DBMS_OUTPUT.put_line ('<tr class="odd">');
            else
                DBMS_OUTPUT.put_line ('<tr class="even">');
            end if;
            
            v_greenbar := v_greenbar + 1;
            DBMS_OUTPUT.put_line ('<td>' || recResults.week_number ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || recResults.week_start_date ||'</td>');
            DBMS_OUTPUT.put_line ('<td>' || recResults.weekly_count ||'</td>');
           -- calculate totals
            v_wkly_adc_count := v_wkly_adc_count + recResults.weekly_count;
            DBMS_OUTPUT.put_line ('<td>' || v_wkly_adc_count ||'</td>');
            DBMS_OUTPUT.put_line ('<td></td>');
            DBMS_OUTPUT.put_line ('</tr>');
         END LOOP;

        DBMS_OUTPUT.put_line ('<tr class="totals">');
        DBMS_OUTPUT.put_line ('<td>Totals</td>');
        DBMS_OUTPUT.put_line ('<td></td>');
        DBMS_OUTPUT.put_line ('<td></td>');
        DBMS_OUTPUT.put_line ('<td>' || v_wkly_adc_count || '</td>');
        DBMS_OUTPUT.put_line ('<td></td>');
        DBMS_OUTPUT.put_line ('</tr>');
        DBMS_OUTPUT.put_line ('</table>');
        DBMS_OUTPUT.put_line ('<br>');
        DBMS_OUTPUT.put_line ('</div>');
    end if;
    
    DBMS_OUTPUT.put_line ('<br></div><br><br>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');    
   
END;
/
disconnect;
exit;
