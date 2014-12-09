module ReplayMessages
  include ReplayHelpers

  def get_sql
    fault_detail_exclusions = [
    ]

    sql = <<-eos
            select a.message_id as message_id,
              trim(a.event_type) as event_type,
              a.fault_code as fault_code,
              a.fault_detail as fault_detail,
              a.message_content as message_content
            from chdr2.audited_event a
            where a.receiving_site = 'HDR.MED.VA.GOV'
            and   a.event_type in ('HDRPRES','HDRFILL','HDRALGY')
            and   a.created_date BETWEEN TO_DATE ('START_DATE','yyyymmdd') AND TO_DATE ('END_DATE','yyyymmdd')
            and   a.FAULT_CODE in ('900','903')
            and   a.message_id = '675379383828'
            FAULT_DETAIL_EXCLUSIONS
            order by a.created_date asc
    eos

    #set up the SQL to retrieve replay messages
    sql.gsub!("START_DATE") { |match| @start_date.strftime("%Y%m%d") }
    sql.gsub!("END_DATE") { |match| @end_date.strftime("%Y%m%d") }

    fault_detail_exclusions.map! { |e|
      "and a.fault_detail not like '%#{e}%'"
    }
    sql.gsub!("FAULT_DETAIL_EXCLUSIONS") { |match| fault_detail_exclusions.join("\n") }
  end

  def call_replay?(fault_code, fault_detail)
    true
  end

  def replay_message_call(message_id, event_type, message_content)
    dom = transform_to_dom(message_id, message_content)# do not do this only grab the ER7 component out of the XML
    #so do not call transform_to_dom
    return false if dom.nil?

    begin
      $logger.warn("calling service bus ...")
      #@service_bus.processOutbound("vistaComponent", dom)#what queue do we put this on? answer vistaComponent There is also an mpiComponent for a24s
        #dodComponent for z02s and z05s
        #for errored z03s look for specific text in fault detail, if you find those look for z03 and query z01
    rescue => ex
      @service_bus_error_count += 1
      raise ex
    end
    return true
  end

  def get_scrubbed_pid
      <<-eos
        <PID><PID.1>1</PID.1><PID.3><CX.1>1011165345V275861</CX.1><CX.5>DE</CX.5></PID.3><PID.3><CX.1>1011165345V275861</CX.1>
        <CX.4><HD.1>USVHA</HD.1><HD.3>0363</HD.3></CX.4><CX.5>NI</CX.5><CX.6><HD.1>VA FACILITY ID</HD.1><HD.2>200M</HD.2>
        <HD.3>L</HD.3></CX.6></PID.3><PID.3><CX.1>666010004</CX.1><CX.4><HD.1>USSSA</HD.1><HD.3>0363</HD.3>
        </CX.4><CX.5>SS</CX.5><CX.6><HD.1>VA FACILITY ID</HD.1><HD.2>508</HD.2><HD.3>L</HD.3></CX.6></PID.3>
        <PID.3><CX.1>""</CX.1><CX.4><HD.1>USDOD</HD.1><HD.3>0363</HD.3></CX.4><CX.5>TIN</CX.5><CX.6><HD.1>VA FACILITY ID</HD.1>
        <HD.2>508</HD.2><HD.3>L</HD.3></CX.6></PID.3><PID.3><CX.1>""</CX.1><CX.4><HD.1>USDOD</HD.1><HD.3>0363</HD.3>
        </CX.4><CX.5>FIN</CX.5><CX.6><HD.1>VA FACILITY ID</HD.1><HD.2>508</HD.2><HD.3>L</HD.3></CX.6></PID.3><PID.3>
        <CX.1>369417</CX.1><CX.4><HD.1>USVHA</HD.1><HD.3>0363</HD.3></CX.4><CX.5>PI</CX.5><CX.6><HD.1>VA FACILITY ID</HD.1>
        <HD.2>508</HD.2><HD.3>L</HD.3></CX.6></PID.3><PID.3><CX.1>666010004</CX.1><CX.4><HD.1>USVBA</HD.1><HD.3>0363</HD.3>
        </CX.4><CX.5>PN</CX.5><CX.6><HD.1>VA FACILITY ID</HD.1><HD.2>508</HD.2><HD.3>L</HD.3></CX.6></PID.3>
        <PID.3><CX.1>1011165345V275861</CX.1><CX.4><HD.1>USVHA</HD.1><HD.3>0363</HD.3></CX.4><CX.5>NI</CX.5><CX.6>
        <HD.1>VA FACILITY ID</HD.1><HD.2>508</HD.2><HD.3>L</HD.3></CX.6><CX.8>20100701</CX.8></PID.3><PID.5>
        <XPN.1><FN.1>CHDRKCCAAD</FN.1></XPN.1><XPN.2>MANADC</XPN.2><XPN.3>V</XPN.3><XPN.7>U</XPN.7></PID.5><PID.6>
        <XPN.1><FN.1>SCRUB</FN.1></XPN.1><XPN.7>M</XPN.7></PID.6><PID.7><TS.1>19550114</TS.1></PID.7><PID.8>M</PID.8>
        <PID.10><CE.1>2106-3-SLF</CE.1><CE.3>0005</CE.3><CE.4>2106-3</CE.4><CE.6>CDC</CE.6></PID.10><PID.11><XAD.1>
        <SAD.1>235 CHDR WAY</SAD.1></XAD.1><XAD.2>""</XAD.2><XAD.3>SOMEWHERE</XAD.3><XAD.4>GA</XAD.4><XAD.5>30054</XAD.5>
        <XAD.6>USA</XAD.6><XAD.7>P</XAD.7><XAD.8>""</XAD.8><XAD.9>217</XAD.9></PID.11><PID.11><XAD.3>UNKNOWN COUNTY</XAD.3>
        <XAD.4>GA</XAD.4><XAD.7>N</XAD.7></PID.11><PID.12>217</PID.12><PID.13><XTN.1>(555)222-1212</XTN.1></PID.13>
        <PID.13><XTN.1>(555)333-1212</XTN.1></PID.13><PID.14><XTN.1>""</XTN.1></PID.14><PID.16><CE.1>D</CE.1></PID.16>
        <PID.17><CE.1>3</CE.1></PID.17><PID.19>666010004</PID.19><PID.22><CE.1>2186-5-SLF</CE.1><CE.3>0189</CE.3><CE.4>2186-5</CE.4>
        <CE.6>CDC</CE.6></PID.22><PID.23>UNKNOWN COUNTY GA</PID.23><PID.24>N</PID.24><PID.29><TS.1>""</TS.1></PID.29></PID>
      eos
  end
end