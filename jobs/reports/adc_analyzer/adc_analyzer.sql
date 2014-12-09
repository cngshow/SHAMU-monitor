SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --
DECLARE
   v_running_total    NUMBER := 0;
   v_last_day         DATE := null;
   v_cur_day          DATE := null;
      
   CURSOR curADCAnalysis IS
        select to_char(a.effective_date,'yyyy-mm-dd') as effective_date,
               count(*) as daily_count
        from   chdr2.patient_identity_xref a
        where  a.status = 1
        and    a.effective_date < trunc(sysdate)
        and    a.VPID not in ('1013294092V222341',
                             '1013315517V028320',
                             '1013021125V518154',
                             '1013294025V219497',
                             '1013315140V913383',
                             '1013315516V299401',
                             '1013315518V151249',
                             '1013315550V776742',
                             '1013315553V589439')
        and    A.EXTERNAL_AGENCY_PATIENT_ID not in ('0011223366',
                                                   '0011223322',
                                                   '0011223399',
                                                   '0011223388',
                                                   '0011223377',
                                                   '0011223333',
                                                   '0011223311',
                                                   '0011223300')
        group by to_char(a.effective_date,'yyyy-mm-dd')
        order by to_char(a.effective_date,'yyyy-mm-dd') asc
        ;

BEGIN
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line('DATA_BELOW');

    FOR recResults in curADCAnalysis Loop
        v_cur_day := to_date(recResults.effective_date,'yyyy-mm-dd');

        if (v_last_day is null) then
            v_last_day := v_cur_day;
        end if;
        
        WHILE (v_cur_day - v_last_day) > 1
        LOOP
            v_last_day := v_last_day + 1;
            DBMS_OUTPUT.put_line (to_char(v_last_day,'yyyy-mm-dd') || ',0,' || to_char(v_running_total));
        END LOOP;    
        
        v_running_total := v_running_total + recResults.daily_count;
        DBMS_OUTPUT.put_line (to_char(v_cur_day,'yyyy-mm-dd') || ',' || to_char(recResults.daily_count) || ',' || to_char(v_running_total));
        v_last_day := v_cur_day;
     END LOOP;

    DBMS_OUTPUT.put_line('DATA_ABOVE');
END;
/
disconnect;
exit;
