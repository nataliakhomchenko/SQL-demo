/*Msdb jobs:*/

 

select j.name

,jh.run_date

    ,js.step_name, command

    ,jh.sql_severity

    ,jh.message

  

    ,jh.run_time,jh.run_status,*

FROM msdb.dbo.sysjobs AS j

INNER JOIN msdb.dbo.sysjobsteps AS js

   ON js.job_id = j.job_id

INNER JOIN msdb.dbo.sysjobhistory AS jh

   ON jh.job_id = j.job_id AND jh.step_id = js.step_id

WHERE

jh.run_date like '202512%'

--and

--jh.run_status = 0

and name like 'Specialty Care Report%'

order by jh.run_date