321 1 select @rid from (traverse out() from (select from v_instance_app where name='app0') maxdepth 4) 
com.orientechnologies.orient.core.config.OGlobalConfiguration
ridBag.embeddedToSbtreeBonsaiThreshold
<properties>
        <entry name="log.console.level" value="info"/>
        <entry name="log.file.level" value="fine"/>
        <entry name="network.http.useToken" value="false"/>
    </properties>
select $path,name from (traverse out('e_instance_APP_businesses_BUSINESS') from (select from v_instance_app where name='app100') maxdepth 4) where name='business100'
select loginId from v where instanceId is null and name like '%小%'
