SET serveroutput on
SET ECHO OFF
set verify off 

-- define local vars --

DECLARE
   v_tz                    CHAR(3):= '&1';
   v_job_code              VARCHAR2(50) := '&2';
   v_lookback              NUMBER := &3;    --this is the look back in minutes

   edate                   DATE   := sysdate;-- central in CHDR 2.0
   bdate                   DATE   := edate - ((v_lookback/60)/24); --pass in the minutes and it is calculated to hours

   v_count	               NUMBER;
   v_report_start_dt       DATE;
   v_report_end_dt         DATE;
   v_dod_site              VARCHAR2(50) := 'DODCHDR.HA.OSD.GOV';
   v_va_site               VARCHAR2(50) := 'VHACHDR.MED.VA.GOV';

BEGIN

   v_report_start_dt := SYSDATE;

   DBMS_OUTPUT.ENABLE (1000000);

    -- get the count of Z04s received for Z03s sent by VA in the time period passed
    SELECT count(*)
    INTO   v_count
    FROM   chdr2.audited_event a
    WHERE  a.event_type = 'ZCH_Z04'
    AND    a.sending_site = v_dod_site
    and    a.receiving_site = v_va_site
    and    a.outcome = 1
    and exists (
        select * 
        from chdr2.audited_event b
        WHERE a.CORRELATION_ID = B.message_id
        AND   b.created_date between bdate and edate
        AND   b.event_type in ('ALGY','CHEM','FILL','PRES')
        AND   b.RECEIVING_SITE = v_dod_site 
        and   b.outcome = 1 )
    ;           

   v_report_end_dt := SYSDATE;

    DBMS_OUTPUT.put_line ('********* RUNNING JOB: ' || v_job_code || ' ********* STARTING OK<br/>');
    DBMS_OUTPUT.put_line ('<html>');
    DBMS_OUTPUT.put_line ('<head>');
    DBMS_OUTPUT.put_line ('<style type="text/css">');
    DBMS_OUTPUT.put_line ('html, body {color:navy; margin:2; padding:2; background:#fff;font-family: "Courier New" Courier monospace;}');
    DBMS_OUTPUT.put_line ('h4 {text-align: center;text-decoration: underline; font-size: 12pt}');
    DBMS_OUTPUT.put_line ('span.red_light{font-size: 10pt; color:red;}');
    DBMS_OUTPUT.put_line ('span.green_light{font-size: 10pt; color:green;}');
    DBMS_OUTPUT.put_line ('span.job_code {text-align: left; font-size: 8pt; color:gray;}');
    DBMS_OUTPUT.put_line ('span.status{display: none;}');
    DBMS_OUTPUT.put_line ('div.output{font-size: 10pt; color:navy; border: 1px gray solid}');
    DBMS_OUTPUT.put_line ('</style>');
    DBMS_OUTPUT.put_line ('</head>');
    DBMS_OUTPUT.put_line ('<body>');
    DBMS_OUTPUT.put_line ('<div class="output" width="650px">');
    DBMS_OUTPUT.put_line ('Count of Z03s Sent by VA to DoD with a Z04 Response=' || v_count || '<br/>');
    DBMS_OUTPUT.put_line ('<span class="status">');

-- print out results --
   if (v_count > 0) then
       DBMS_OUTPUT.put_line ('__GREEN_LIGHT__');
       DBMS_OUTPUT.put_line ('</span>');   
       DBMS_OUTPUT.put_line ('<span class="green_light">GREEN LIGHT</span><br/><br/>');
   else
      DBMS_OUTPUT.put_line ('__RED_LIGHT__');
      DBMS_OUTPUT.put_line ('</span>');   
      DBMS_OUTPUT.put_line ('<span class="red_light">RED LIGHT</span><br/><br/>');
   end if;
   
   DBMS_OUTPUT.put_line ('<br/><br/>');
   DBMS_OUTPUT.put_line ('Begin Date (' || v_tz || ') = ' || to_char(bdate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
   DBMS_OUTPUT.put_line ('End Date (' || v_tz || ') = ' || to_char(edate, 'DD-MON-YY HH24:MI:SS') || '<br/>');
   DBMS_OUTPUT.put_line ('<span class="job_code">(' || v_job_code || ')</span><br/><br/>');
   DBMS_OUTPUT.put_line ('</div></body></html>');
   DBMS_OUTPUT.put_line ('EMAIL_RESULT_ABOVE:');
   DBMS_OUTPUT.put_line ('<br/>********* RUNNING JOB: ' || v_job_code || ' ********* END<br/>');

END;
/
disconnect;
exit;

