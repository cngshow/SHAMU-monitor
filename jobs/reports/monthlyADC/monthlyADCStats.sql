SET SERVEROUTPUT ON
SET ECHO OFF
set verify off 
set term off;
set feedback off;
set heading off;
set linesize 50;

spool './jobs/reports/monthlyADC/va-chdr-monthly-adc.txt'

--retrieve all active ADC patients as of midnight on the first of the current month excluding test patients
select a.EXTERNAL_AGENCY_PATIENT_ID || ',' || a.vpid || ',' || to_char(a.EFFECTIVE_DATE, 'yyyymmdd hh24:mi:ss')
from   CHDR2.PATIENT_IDENTITY_XREF a
where  a.status = 1
and    a.effective_date < to_date(to_char(sysdate,'YYYYMM') || '01','yyyymmdd')
and    a.VPID not in ('1013294092V222341',
                     '1013315517V028320',
                     '1013021125V518154',
                     '1013294025V219497',
                     '1013315140V913383',
                     '1013315516V299401',
                     '1013315518V151249',
                     '1013315550V776742',
                     '1013315553V589439')
and   A.EXTERNAL_AGENCY_PATIENT_ID not in ('0011223366',
                                           '0011223322',
                                           '0011223399',
                                           '0011223388',
                                           '0011223377',
                                           '0011223333',
                                           '0011223311',
                                           '0011223300')
order by A.EFFECTIVE_DATE desc
;

spool off;
disconnect;
exit;
