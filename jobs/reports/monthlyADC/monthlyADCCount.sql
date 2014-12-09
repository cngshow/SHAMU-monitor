SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE

v_adc_count   NUMBER := 0;

BEGIN

--get the count of VA ADC patients based on the effective date in the patient xref table
select count(*)
into   v_adc_count
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
;

    DBMS_OUTPUT.ENABLE (1000000);
	DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
	DBMS_OUTPUT.put_line ('Total VA ADC Count = ' || v_adc_count);
	DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');
END;
/
disconnect;
exit;
