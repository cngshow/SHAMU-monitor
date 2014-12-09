SET serveroutput on
SET ECHO OFF
set verify off

-- define local vars --

DECLARE

v_start_date     VARCHAR2(8) := '&1'; -- a date passed in as yyyymmdd
v_lookback_days  NUMBER := &2;    --this is the look back in days
bdate            DATE := to_date(v_start_date,'yyyymmdd') - v_lookback_days;
edate            DATE := bdate + v_lookback_days;
v_greenbar       NUMBER := 0;

--daily totals
v_ora_cnt NUMBER := 0;
v_idm_cnt NUMBER := 0;
v_pre_read_req_cnt NUMBER := 0;
v_jdbc_cnt NUMBER := 0;
v_cds_cnt NUMBER := 0;
v_vista_cnt NUMBER := 0;
v_other_cnt NUMBER := 0;
v_total_cnt NUMBER := 0;

--report totals
v_ora_cnt_tot NUMBER := 0;
v_idm_tot NUMBER := 0;
v_pre_read_req_tot NUMBER := 0;
v_jdbc_tot NUMBER := 0;
v_cds_tot NUMBER := 0;
v_vista_tot NUMBER := 0;
v_other_tot NUMBER := 0;
v_total_tot NUMBER := 0;

-- messages received and sent by VA
CURSOR curErrors IS
    select audit_date as audit_date,
        sum(ora_00001) as ora_cnt,
        sum(idm) as idm_cnt,
        sum(read_req) as pre_read_req_cnt,
        sum(jdbc) as jdbc_cnt,
        sum(cds) as cds_cnt,
        sum(vista) as vista_cnt,
        sum(cnt) - (sum(ora_00001) + sum(idm) + sum(read_req) + sum(jdbc) + sum(cds) + sum(vista)) as other_cnt,
        sum(cnt) as total_cnt
    from (
        Select to_char(M.CREATED_DATE,'yyyymmdd') as audit_date,
            case when fault_detail like '%ORA-00001%' then 1 else 0 end as ora_00001,
            case when fault_detail like '%IDM_SERVICE%' then 1 else 0 end as idm,
            case when fault_detail like '%READ_REQUEST_PRE_%' then 1 else 0 end as read_req,
            case when fault_detail like '%HDRII_OPERATION_FAILED%' then 1 else 0 end as jdbc,
            case when fault_detail like '%CDS_2X_SERVICE_FAILURE%' then 1 else 0 end as cds,
            case when fault_detail like '%READ_REQUEST_DATA_SOURCE_FAILURE: displayMessage=Assigning Facility%' then 1 else 0 end as vista,
            1 as cnt
        from   CHDR2.AUDITED_EVENT m
        where m.created_date BETWEEN bdate AND edate
        and m.FAULT_CODE = '906'
    )
    group by audit_date
    order by audit_date
;

BEGIN
    if (v_lookback_days = 0) then
        bdate := trunc(sysdate);
        edate := sysdate;
    end if;

    -- begin - html output template
    DBMS_OUTPUT.ENABLE (1000000);
    DBMS_OUTPUT.put_line ('OUTPUT_BELOW:');
    DBMS_OUTPUT.put_line ('<div class="rpt">');
    -- end - html output template

    DBMS_OUTPUT.put_line ('<h4>906 Error Breakdown from ' || to_char(bdate, 'Month dd, yyyy') || ' thru ' || to_char(edate, 'Month dd, yyyy') || '</h4>');
    DBMS_OUTPUT.put_line ('<div class="section">906 Error Breakdown</div>');
    DBMS_OUTPUT.put_line ('<div class="rpt_display">');
    DBMS_OUTPUT.put_line ('<table class="display" cellspacing=0>');
    DBMS_OUTPUT.put_line ('<tr><th width="12%">Audit<br>Date</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">Oracle<br>Constraint</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">IDM<br>Errors</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">Privilege<br>Violation</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">JDBC<br>Errors</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">CDS<br>Errors</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">VistA<br>Errors</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">Other<br>Errors</th>');
    DBMS_OUTPUT.put_line ('<th width="11%">Total<br>Errors</th>');
    DBMS_OUTPUT.put_line ('</tr>');

    FOR recResults in curErrors Loop
        if (MOD(v_greenbar, 2) > 0) then
            DBMS_OUTPUT.put_line ('<tr class="odd">');
        else
            DBMS_OUTPUT.put_line ('<tr class="even">');
        end if;

        v_greenbar := v_greenbar + 1;
        DBMS_OUTPUT.put_line ('<td>' || to_char(to_date(recResults.audit_date,'YYYYMMDD'), 'MON-DD-YYYY') ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.ora_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.idm_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.pre_read_req_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.jdbc_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.cds_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.vista_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.other_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('<td>' || recResults.total_cnt ||'</td>');
        DBMS_OUTPUT.put_line ('</tr>');

        -- calculate totals

        v_ora_cnt_tot := v_ora_cnt_tot + recResults.ora_cnt;
        v_idm_tot := v_idm_tot + recResults.idm_cnt;
        v_pre_read_req_tot := v_pre_read_req_tot + recResults.pre_read_req_cnt;
        v_jdbc_tot := v_jdbc_tot + recResults.jdbc_cnt;
        v_cds_tot := v_cds_tot + recResults.cds_cnt;
        v_vista_tot := v_vista_tot + recResults.vista_cnt;
        v_other_tot := v_other_tot + recResults.other_cnt;
        v_total_tot := v_total_tot + recResults.total_cnt;

    END LOOP;

    DBMS_OUTPUT.put_line ('<tr class="totals">');
    DBMS_OUTPUT.put_line ('<td class="totals">Totals</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_ora_cnt_tot || '</td>');--see if we can just use tr.totals
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_idm_tot || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_pre_read_req_tot || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_jdbc_tot || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_cds_tot || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_vista_tot || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_other_tot || '</td>');
    DBMS_OUTPUT.put_line ('<td class="totals">' || v_total_tot || '</td>');
    DBMS_OUTPUT.put_line ('</tr>');
    DBMS_OUTPUT.put_line ('</table>');
    DBMS_OUTPUT.put_line ('</div>');
    DBMS_OUTPUT.put_line ('<br><br>');
    DBMS_OUTPUT.put_line ('OUTPUT_ABOVE:');
END;
/
disconnect;
exit;