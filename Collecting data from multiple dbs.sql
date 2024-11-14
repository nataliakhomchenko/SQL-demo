--declare @user as  VARCHAR(255)

--SELECT @user=CURRENT_USER; 

/*******************Physical Medicine Implementation Mgmt Report Query**********************************/

DECLARE @StartDate as datetime,@EndDate as datetime

set @StartDate='03/19/2024'

set @EndDate=getdate()

declare @account as  VARCHAR(255)

set @account='All'/*Possible choice:All,Aetna,Coventry,Centene,Gateway  */

 

/**********************START*******************************/

declare @account2 as varchar(255)

set @account2='%'+@account+'%'


set ansi_warnings off      

set nocount on             

----------------------------------------------------------------------

--Get all Phys Med auths

 

IF OBJECT_ID('tempdb..#db_list') IS NOT NULL drop table #db_list

IF OBJECT_ID('tempdb..#result') IS NOT NULL drop table #result

---------------------------------------------------

 

SELECT distinct  name, ROW_NUMBER() OVER(ORDER BY name) AS RN

into #db_list 

FROM sys.databases

where

name like case @account when 'All' then '%' else @account2 end

and name <>'centene'

and name <>'centeneKY'

and

(

name like '%Aetna%'

or name like 'Coventry%'

or name like 'Centene%'

or name like 'Gateway%'

)

 

 

/***************************tables**************************************************/

DECLARE @auths TABLE(auth_id VARCHAR(20))

DECLARE @queues TABLE

(

[auth_id]  VARCHAR(15),

                [date_queued] [datetime2](7) ,

                [queue_code] [char](3) ,

                [queue_routing_id] [int] ,

                [isfinal] [tinyint] ,

                [report_translation] [char](3) ,

                [date_left_queue] [datetime2](7)

)

declare @cte_e table

(

auth_id VARCHAR(15),

max_offer_note_date [datetime2](7)

)

declare @cte_f table

(

auth_id VARCHAR(15),

note [varchar](7800),

offer_note_date [datetime2](7)

)

 

declare @g table

(

auth_id VARCHAR(15),

tracking_number[varchar](50), 

date_call_rcvd [datetime2](7) ,

member_id [varchar](20),

phys_id [varchar](20),

fac_id [varchar](20),

dos datetime,

oon_flag [varchar](20),

case_outcome [varchar](20),

provider_type [varchar](20) ,

cpt4_code [varchar](20),

proc_desc[varchar](7800),

auth_origin [varchar](20),

expedite_flag [varchar](20),

retro_flag [varchar](20),

retro_type [varchar](20),

icd10_code [varchar](20),

icd10_descr [varchar](7800),

Apprv_by_Algo [varchar](20),

accept_or_decline_trmt_plan [varchar](20)

)

declare @g2 table

(

auth_id VARCHAR(15),

tracking_number[varchar](50), 

date_call_rcvd [datetime2](7) ,

member_id [varchar](20),

phys_id [varchar](20),

fac_id integer,

dos datetime,

oon_flag [varchar](20),

case_outcome [varchar](20),

provider_type [varchar](20) ,

cpt4_code [varchar](20),

proc_desc[varchar](7800),

auth_origin [varchar](20),

expedite_flag [varchar](20),

retro_flag [varchar](20),

retro_type [varchar](20),

icd10_code [varchar](20),

icd10_descr [varchar](7800),

Apprv_by_Algo [varchar](20),

accept_or_decline_trmt_plan [varchar](20),

 

determ_date [datetime2](7) ,

auth_status [varchar](50),

status_desc [varchar](255),

auth_outcome [varchar](255),

UM_Outcome [varchar](255),   

client_member_id [varchar](50),

mbr_name [varchar](255),

mbr_dob [datetime2](7) ,

plan_name [varchar](255),

line_of_business [varchar](255),

car_id int,

car_name [varchar](255),

phys_tax_id [varchar](50),

phys_npi [varchar](50),

client_physician_id [varchar](50),

phys_name [varchar](255),

visits_requested integer,

visits_approved integer,

visits_denied integer,

initial_fax_date datetime,

               

has_1570 [varchar](20)

)

 

declare @g3 table

(

auth_id VARCHAR(15),

tracking_number[varchar](50), 

date_call_rcvd [datetime2](7) ,

member_id [varchar](20),

phys_id [varchar](20),

fac_id integer,

dos datetime,

oon_flag [varchar](20),

case_outcome [varchar](20),

provider_type [varchar](20) ,

cpt4_code [varchar](20),

proc_desc[varchar](7800),

auth_origin [varchar](20),

expedite_flag [varchar](20),

retro_flag [varchar](20),

retro_type [varchar](20),

icd10_code [varchar](20),

icd10_descr [varchar](7800),

Apprv_by_Algo [varchar](20),

accept_or_decline_trmt_plan [varchar](20),

 

determ_date [datetime2](7) ,

auth_status [varchar](50),

status_desc [varchar](255),

auth_outcome [varchar](255),

UM_Outcome [varchar](255),   

client_member_id [varchar](50),

mbr_name [varchar](255),

mbr_dob [datetime2](7) ,

plan_name [varchar](255),

line_of_business [varchar](255),

car_id int,

car_name [varchar](255),

phys_tax_id [varchar](50),

phys_npi [varchar](50),

client_physician_id [varchar](50),

phys_name [varchar](255),

visits_requested integer,

visits_approved integer,

visits_denied integer,

initial_fax_date datetime,

has_1570 [varchar](20),

Request_Date datetime,

Rendering_is_OON [varchar](50),

Rendering_fac_id [varchar](50),

Rendering_fac_name [varchar](255),

Rendering_tax_id[varchar](50),

Rendering_NPI[varchar](50),

Rendering_fac_street[varchar](255),

Rendering_fac_city [varchar](255),

Rendering_fac_state [varchar](50),

fac_zip [varchar](50),

Rendering_MIS [varchar](50),

fac_phone [varchar](50),

Rendering_fac_zip [varchar](50),

auth_validity_start datetime,

auth_validity_end datetime,

initial_or_subsequent [varchar](50),

hab_or_rehab [varchar](255),

eval_date  varchar(max)

                               

)

declare @g4 table

(

auth_id VARCHAR(15),

tracking_number[varchar](50), 

date_call_rcvd [datetime2](7) ,

member_id [varchar](20),

phys_id [varchar](20),

fac_id integer,

dos datetime,

oon_flag [varchar](20),

case_outcome [varchar](20),

provider_type [varchar](20) ,

cpt4_code [varchar](20),

proc_desc[varchar](7800),

auth_origin [varchar](20),

expedite_flag [varchar](20),

retro_flag [varchar](20),

retro_type [varchar](20),

icd10_code [varchar](20),

icd10_descr [varchar](7800),

Apprv_by_Algo [varchar](20),

accept_or_decline_trmt_plan [varchar](20),

 

determ_date [datetime2](7) ,

auth_status [varchar](50),

status_desc [varchar](255),

auth_outcome [varchar](255),

UM_Outcome [varchar](255),   

client_member_id [varchar](50),

mbr_name [varchar](255),

mbr_dob [datetime2](7) ,

plan_name [varchar](255),

line_of_business [varchar](255),

car_id int,

car_name [varchar](255),

phys_tax_id [varchar](50),

phys_npi [varchar](50),

client_physician_id [varchar](50),

phys_name [varchar](255),

visits_requested integer,

visits_approved integer,

visits_denied integer,

initial_fax_date datetime,

has_1570 [varchar](20),

Request_Date datetime,

Rendering_is_OON [varchar](50),

Rendering_fac_id [varchar](50),

Rendering_fac_name [varchar](255),

Rendering_tax_id[varchar](50),

Rendering_NPI[varchar](50),

Rendering_fac_street[varchar](255),

Rendering_fac_city [varchar](255),

Rendering_fac_state [varchar](50),

fac_zip [varchar](50),

Rendering_MIS [varchar](50),

fac_phone [varchar](50),

Rendering_fac_zip [varchar](50),

auth_validity_start datetime,

auth_validity_end datetime,

initial_or_subsequent [varchar](50),       

hab_or_rehab [varchar](255),

eval_date  varchar(max),

current_status [varchar](255),

current_queue [varchar](255),

current_queue_date datetime ,

                               

Has_Clinical_Pend_status [varchar](20) ,

 

Clinical_Pend_status_date datetime,

Sent_to_PM_ClinReview_Queue [varchar](255),

PM_ClinReview_queue_date datetime,

PhysMed_Clinical_Docu_Review_queue_date datetime,

repl_for_validity_ext int ,

repl_for_addtl_visits int,

repl_for_denied_visits int

)

/**************************************************************end of tables*******************/

DECLARE @Counter INT ,@total int

select @total=count(*)  from

(

SELECT distinct name

FROM #db_list

)  a

               

SET @Counter=1

-------------------------------------------------GOING TROUGH DBS--------------------------------------------------

WHILE ( @Counter <= @total)

 

BEGIN

 

 

IF OBJECT_ID('tempdb..#auths') IS NOT NULL drop table #auths  

IF OBJECT_ID('tempdb..#offer') IS NOT NULL drop table #offer

IF OBJECT_ID('tempdb..#queues') IS NOT NULL drop table #queues

IF OBJECT_ID('tempdb..#cte_e') IS NOT NULL drop table #cte_e

DELETE FROM @auths

DELETE FROM @queues

delete from @cte_e

delete from @cte_f

delete  from @g

delete  from @g2

delete  from @g3

delete  from @g4

DECLARE @DBNAME VARCHAR(255)

SELECT  @DBNAME = NAME FROM #db_list where rn=@Counter

 

 

INSERT INTO  @auths

exec(' select       

                                a.auth_id

from '+@DBNAME+'.dbo.authorizations a with(nolock)

where   a.authorization_type_id = 16

                                and a.retro_flag <> ''c''')

SELECT * into #auths FROM @auths

--select * from #auths

---------------------------------------------------

--Combine queue history tables

 

INSERT INTO @queues

 

EXEC('select

aqh.[auth_id]

,aqh.[date_queued]

,aqh.[queue_code]

,aqh.[queue_routing_id]

,aqh.[isfinal]

,aqh.[report_translation]

,aqh.[date_left_queue]

 

from '+@DBNAME+'.DBO.auth_queue_history aqh with(nolock)

                                join #auths x with(nolock) on (aqh.auth_id = x.auth_id)

union all

select    

aqha.[auth_id]

,aqha.[date_queued]

,aqha.[queue_code]

,aqha.[queue_routing_id]

,aqha.[isfinal]

,aqha.[report_translation]

,aqha.[date_left_queue]

 

 

 

from '+@DBNAME+'.DBO.auth_queue_history_arch aqha with(nolock)

                                join #auths x2 with(nolock) on (aqha.auth_id = x2.auth_id)

')

 

select * into #queues from @queues

--SELECT * FROM  #queues

 

insert into @cte_e

exec(

'select    an.auth_id,

                                max_offer_note_date = max(an.date_entered)

 

from      #auths a with(nolock)

                                join '+ @DBNAME+'.DBO.auth_notes an with(nolock) on (a.auth_id = an.auth_id)

where   an.note in (''Requester accepted offered treatment plan'', ''Requester declined offered treatment plan'')

group by an.auth_id'

)

 

select * INTO #cte_e from @cte_e

 

insert into @cte_f

exec(

'select    an.auth_id,

                                an.note,

                                offer_note_date = an.date_entered

                               

from      #cte_e e

                                join '+ @DBNAME+'.DBO.auth_notes an with(nolock) on (e.auth_id = an.auth_id

                                                                                                                and e.max_offer_note_date = an.date_entered)'

)

 

select * into #offer from @cte_f

--select *  from #offer

 

 

IF OBJECT_ID('tempdb..#g') IS NOT NULL drop table #g

insert into @g

exec(

'

 

select     a.auth_id, a.tracking_number,    a.date_call_rcvd, a.member_id, a.phys_id,

                                a.fac_id, a.dos,

                                oon_flag = case when a.fac_id = 1 then ''Yes'' else '''' end,

                                a.case_outcome, provider_type = ads.data, a.cpt4_code, a.proc_desc,

                                auth_origin = case when a.is_user_id = ''1998'' then ''RadMD'' else ''CallCenter'' end,

                                a.expedite_flag,

                                a.retro_flag,

                                retro_type = r.description,

                                a.icd10_code,

                                ic.icd10_descr,

                                Apprv_by_Algo = case when a.case_outcome = ''Approve Physical Medicine request'' then ''Yes'' else ''No'' end,

                                accept_or_decline_trmt_plan = case when f.note like ''%accepted%'' then ''Accepted''

                                                                                                                                                when f.note like ''%declined%'' then ''Declined''

                                                                                                                                                else '''' end

 

                               

 

 

from      #auths a2 with(nolock)

                                join '+@DBNAME+'.DBO.authorizations a with(nolock) on (a2.auth_id = a.auth_id)

                                left outer join '+@DBNAME+'.DBO.authorization_data_supplemental ads with(nolock) on (a.auth_id = ads.auth_id and ads.data_type_id = 542) --provider type

                                join niacore..auth_retro_flags r with(nolock) on (a.retro_flag = r.retro_flag)

                               

                                left outer join niacore..icd10_codes ic with(nolock) on (a.icd10_code = ic.icd10_code)

                               

                                left outer join #offer f with(nolock) on (a.auth_id = f.auth_id)

                               

where                                   a.date_call_rcvd >='+''''+@StartDate+''''+' and a.date_call_rcvd <= '+''''+@EndDate+'''')

                                               

 

SELECT * into #g FROM @g where date_call_rcvd >=@StartDate

--select 'g',* from #g

----------------------------------------------------------------------

--Look for determs and other info

 

IF OBJECT_ID('tempdb..#g2') IS NOT NULL drop table #g2

insert into @g2

exec

('select  g.*,

                                determ_date = aschg.date_changed,

                                ascd.auth_status,

                                ascd.status_desc,

                                ascd.auth_outcome,

                                               

                                case

                                                when cd.customer_group_determination_code in (''1'',''5'') then ''Certified''

                                                when cd.customer_group_determination_code in (''2'',''6'') then ''Clinical Non-Certified''

                                                when cd.customer_group_determination_code in (''7'',''8'') then ''Partially Non-Certified''

                                                when cd.customer_group_determination_code = ''3'' then ''Administrative Non-Certified''

                                                when cd.customer_group_determination_code = ''4'' then ''Inactivated by Ordering Provider''

                                end as UM_Outcome,   

 

                                m.client_member_id,

                                mbr_name = m.lname + '', '' + m.fname,

                                mbr_dob = convert (char(10), m.dob, 101),

                                hp.plan_name,

                                line_of_business = lob.description,

                                hc.car_id,

                                hc.car_name,

                                phys_tax_id = p.tax_id,

                                phys_npi = p.npi,

                                p.client_physician_id,

                                phys_name = p.lname + '', '' + p.fname,

                               

                                tp.visits_requested,

                                tp.visits_approved,

                                tp.visits_denied,

                               

                                               

                                initial_fax_date = (select min(aal.date_action) from auth_action_log aal with(nolock)

                                                                                                where aal.auth_id = g.auth_id

                                                                                                and aal.date_action < g.date_call_rcvd

                                                                                                and aal.auth_action_code = 1302),  --Date and Time Fax received recorded during auth entry (used for timeliness rules)

                               

                               

                                has_1570 = case when exists (select * from auth_action_log aal2 with(nolock) where

                                                                                g.auth_id = aal2.auth_id                and aal2.auth_action_code = 1570)  --Physical Medicine - Subsequent request via phone

                                                                                then 1 else 0 end

                               

 

from      #g g with(nolock)

 

                                join '+ @DBNAME+'.DBO.members m with(nolock) on (g.member_id = m.member_id)

                                join '+@DBNAME+'.DBO.physicians p with(nolock) on (g.phys_id = p.phys_id)

                               

                                join niacore..health_plan hp with(nolock) on (m.plan_id = hp.plan_id)

                                join niacore..line_of_business lob with(nolock) on (hp.line_of_business = lob.line_of_business)

                                join niacore..health_carrier hc with(nolock) on (hp.car_id = hc.car_id)

                               

                                left outer join '+@DBNAME+'.DBO.auth_status_change aschg with(nolock) on (g.auth_id = aschg.auth_id

                                                                                and aschg.date_changed = (select max(aschg2.date_changed) from '+@DBNAME+'.DBO.auth_status_change aschg2 with(nolock)

                                                                                                                                                                                                join niacore..auth_status_codes ascd2 with(nolock) on (aschg2.new_auth_status = ascd2.auth_status)

                                                                                                                                                                                                where aschg.auth_id = aschg2.auth_id

                                                                                                                                                                                                and ascd2.final_status_flag = 1))

                                                                                                                                                                                               

                                left outer join niacore..auth_status_codes ascd with(nolock) on (aschg.new_auth_status = ascd.auth_status)

                                left outer join niacore..auth_outcomes aout with(nolock) on (ascd.auth_outcome = aout.auth_outcome)

 

                                left outer join niacore..Customer_Determination_Codes cd with (nolock) on (ascd.customer_determination_code = cd.customer_determination_code)

                                left outer join niacore..Customer_Group_Determination_Codes cgd with (nolock) on (cd.customer_group_determination_code = cgd.customer_group_determination_code)                 

               

                                left outer join '+@DBNAME+'.DBO.physical_medicine_therapy_plan tp with(nolock) on (g.auth_id = tp.auth_id)')

 

 

                                                               

select *  into #g2 from @g2

--select 'g2',* from #g2  

                               

----------------------------------------------------------------------

--Get facility info

 

IF OBJECT_ID('tempdb..#g3') IS NOT NULL drop table #g3               

insert into @g3

exec

('select  a.*,

 

                                Request_Date = ISNULL(initial_fax_date, date_call_rcvd),

                                Rendering_is_OON = a.oon_flag,

                                Rendering_fac_id = case when a.fac_id = 1 then afg.fac_id else a.fac_id end,

                                Rendering_fac_name = case when a.fac_id = 1 then afg.facility_name else f.facility_name end,

                                Rendering_tax_id = case when a.fac_id = 1 then afg.provider_tax_id else f.provider_tax_id end,

                                Rendering_NPI = case when a.fac_id = 1 then NULL else app.provider_npi end,

                                Rendering_fac_street = case when a.fac_id = 1 then afg.address1 else f.address1 end,

                                Rendering_fac_city = case when a.fac_id = 1 then afg.city else f.city end,

                                Rendering_fac_state = case when a.fac_id = 1 then afg.state else f.state end,

                                fac_zip = case when a.fac_id = 1 then afg.zip else f.zip end,

                                Rendering_MIS = case when a.fac_id = 1 then NULL else app.provider_mis end,

                                fac_phone = case when a.fac_id = 1 then afg.contact_ac + ''-'' + afg.contact_phone else f.ac + ''-'' + f.phone end,

                                Rendering_fac_zip = case when a.fac_id = 1 then afg.zip else f.zip end,

 

                                auth_validity_start = avs.start_date,

                                auth_validity_end = avs.end_date,

                               

                               

                               

                                initial_or_subsequent = case when /*a.car_id in (141) and  */

                                                                                                                                                                RIGHT(rtrim(a.auth_id),1) in (''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'')  --Ends in number

                                                                                                                                               

                                                                                                                                                                THEN ''Initial''

                                                                                                                                                               

                                                                                                                when /*a.car_id in (141) and*/

                                                                                                                                                                RIGHT(rtrim(a.auth_id),1) in (''A'',''B'',''C'',''D'',''E'',''F'',''G'',''H'',''I'',''J'',''K'',  --Ends in letter

                                                                                                                                                                ''L'',''M'',''N'',''O'',''P'',''Q'',''R'',''S'',''T'',''U'',''V'',''W'',''X'',''Y'',''Z'')

                                                                                               

                                                                                                                                                               

                                                                                                                                                                THEN ''Subsequent''

                                                                                               

                                                                                                                else ''N/A''

                                                                                               

                                                                                                end,

                                                                                               

                                hab_or_rehab = ads.data,

                                eval_date = case when proc_desc = ''Therapy-PT'' then ads2.data

                                                                                                when proc_desc = ''Therapy-ST'' then ads3.data

                                                                                                when proc_desc = ''Therapy-OT'' then ads4.data

                                                                                               

                                                                                                 else '' '' end

                               

 

 

from      #g2 a with(nolock)

                               

                                join nirad..facilities f with(nolock) on (a.fac_id = f.fac_id)

                                left outer join nirad..applications app with(nolock) on (f.fac_id = app.fac_id and a.car_id = app.car_id)

 

                                left outer join '+@DBNAME+'.DBO.auth_facility_generic afg with(nolock) on (a.auth_id = afg.auth_id

                                                                                and afg.date_updated = (select max(afg2.date_updated) from '+@DBNAME+'.DBO.auth_facility_generic afg2 with(nolock)

                                                                                                                                                                                where afg2.auth_id = a.auth_id

                                                                                                                                                                                and afg2.facility_name not like ''%cancel%''

                                                                                                                                                                                and afg2.facility_name not like ''Other%'')

                                                                                )

 

                                left outer join '+@DBNAME+'.DBO.auth_validity_spans avs with(nolock) on (a.auth_id = avs.auth_id and avs.sequence =

                                                (select max(avs2.sequence) from '+@DBNAME+'.DBO.auth_validity_spans avs2 with(nolock)

                                                 where avs.auth_id = avs2.auth_id))

               

                                left outer join '+@DBNAME+'.DBO.authorization_data_supplemental ads with(nolock) on (a.auth_id = ads.auth_id

                                                                and ads.data_type_id = 413)

                                                               

                                left outer join '+@DBNAME+'.DBO.authorization_data_supplemental ads2 with(nolock) on (a.auth_id = ads2.auth_id

                                                                and ads2.data_type_id = 399)  --Physical Medicine - Physical Therapy Evaluation date

                                                               

                                left outer join '+@DBNAME+'.DBO.authorization_data_supplemental ads3 with(nolock) on (a.auth_id = ads3.auth_id

                                                                and ads3.data_type_id = 407)  --Physical Medicine - Speech Therapy evaluation date                               

                                                               

                                left outer join '+@DBNAME+'.DBO.authorization_data_supplemental ads4 with(nolock) on (a.auth_id = ads4.auth_id

                                                                and ads4.data_type_id = 396)  --Physical Medicine - Occupational Therapy evaluation date

                                                                ')            

                                                               

 

select * INTO #g3 from @g3

--select 'g3', * from #g3

 

----------------------------------------------------------------------

--Get current queue, current status

--1555  Physical Medicine - Replicated for validity date extension requiring clinical review

--1556  Physical Medicine - Replicated for additional visits request.

--1566  Physical Medicine - Replicated for denied visits

 

IF OBJECT_ID('tempdb..#g4') IS NOT NULL drop table #g4

insert into @g4

exec

('select  a.*,

 

                                current_status = ascd.status_desc,

                                current_queue = i1.description, --isnull(i1.description, i2.description),

                                current_queue_date = z3.date_queued,  --ISNULL(aqh.date_queued, aqha.date_queued),

                               

                                Has_Clinical_Pend_status = case when y.date_changed is not null then ''Yes'' else ''No'' end,

 

                                Clinical_Pend_status_date = convert(varchar(10), y.date_changed, 120),

                                Sent_to_PM_ClinReview_Queue = case when z1.date_queued is not null then ''Yes'' else ''No'' end,

                                PM_ClinReview_queue_date = convert(varchar(10), z1.date_queued, 120),

                                PhysMed_Clinical_Docu_Review_queue_date = convert(varchar(10), z2.date_queued, 120),

 

                               

                                repl_for_validity_ext = case when exists (select aal.auth_id from auth_action_log aal with(nolock)

                                                                                                where a.auth_id = aal.auth_id and aal.auth_action_code = 1555)                                --Physical Medicine - Replicated for validity date extension requiring clinical review

                                                                                               

                                                                                                then 1 else 0 end,

                                                                                               

                                repl_for_addtl_visits = case when exists (select aal.auth_id from auth_action_log aal with(nolock)

                                                                                                where a.auth_id = aal.auth_id and aal.auth_action_code = 1556)                                --Physical Medicine - Replicated for additional visits request.

                                                                                               

                                                                                                then 1 else 0 end,

                                                                                               

                                repl_for_denied_visits = case when exists (select aal.auth_id from auth_action_log aal with(nolock)

                                                                                                where a.auth_id = aal.auth_id and aal.auth_action_code = 1566)                                --Physical Medicine - Replicated for denied visits

                                                                                               

                                                                                                then 1 else 0 end

                               

                               

               

 

 

from      #g3 a with(nolock)

 

                                left outer join #queues z1 with(nolock) on (a.auth_id = z1.auth_id and z1.queue_code = ''por''

                                                                and z1.date_queued = (select min(z1a.date_queued) from #queues z1a with(nolock)

                                                                                                                                                where z1.auth_id = z1a.auth_id and z1a.queue_code = ''por''))

 

                                left outer join #queues z2 with(nolock) on (a.auth_id = z2.auth_id and z2.queue_code = ''pmd''

                                                                and z2.date_queued = (select min(z2a.date_queued) from #queues z2a with(nolock)

                                                                                                                                                where z2.auth_id = z2a.auth_id and z2a.queue_code = ''pmd''))

                                                                                                                                               

                                left outer join #queues z3 with(nolock) on (a.auth_id = z3.auth_id and z3.isfinal = 1)

                                               

                                left outer join '+@DBNAME+'.DBO.auth_status_change y with(nolock) on (a.auth_id = y.auth_id

                                                                                and y.new_auth_status = ''cp''

                                                                                and y.date_changed = (select min(y2.date_changed) from '+@DBNAME+'.DBO.auth_status_change y2 with(nolock)

                                                                                                                                                where y2.auth_id = y.auth_id and y2.new_auth_status = ''cp''))                                                                                      

                                                                                                                                               

                               

                                                                               

                                left outer join niacore..informa_queues i1 with(nolock) on (z3.queue_code = i1.queue_code)

                                --left outer join niacore..informa_queues i2 with(nolock) on (aqha.queue_code = i2.queue_code)

                               

                                left outer join '+@DBNAME+'.DBO.auth_status_change aschg with(nolock) on (a.auth_id = aschg.auth_id and aschg.isfinal = 1)

                                left outer join niacore..auth_status_codes ascd with(nolock) on (aschg.new_auth_status = ascd.auth_status)

                                ')

                               

 

IF OBJECT_ID('tempdb..#g_final') IS NOT NULL drop table #g_final

               

select *

into        #g_final

from      @g4

 

--select 'g final',* from #g_final

--------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#g_results') IS NOT NULL drop table #g_results

               

select     car_id,

                                car_name,

                                auth_id,

                                tracking_number,

                                initial_or_subsequent,

                                repl_for_validity_ext,

                                repl_for_addtl_visits,

                                --repl_for_denied_visits,

                                Request_Date = convert(varchar(10), Request_Date, 120),  --convert(char(20),Request_Date, 101),

                                --date_call_rcvd,

                                Date_of_Svc = convert (char(20), dos, 101),

                                plan_name = rtrim(plan_name),

                                line_of_business,

                                expedite_flag,

                                cpt4_code,

                                proc_desc,

                                icd10_code,

                                icd10_descr,

                                Apprv_by_Algo,

                                accept_or_decline_trmt_plan,

                                determ_date = convert(varchar(10), determ_date, 120) ,

                                final_outcome = auth_outcome,

                                final_determ = status_desc,

                                --Member_Letter_Date,

                                --Phys_Letter_Date,

                                UM_Outcome,

                                auth_origin,

                               

                                visits_requested,

                                visits_approved,

                                visits_denied,

                                                               

                                --member_id,

                                client_member_id,

                                mbr_dob,

                                mbr_name,

                                --phys_id,

                                client_physician_id,

                                phys_tax_id,

                                phys_npi,

                                phys_name,

                                Rendering_is_OON,

                                Provider_Type,

                                --Rendering_fac_id,

                                Rendering_fac_name,

                                Rendering_MIS,

                                Rendering_tax_id,

                                Rendering_NPI,

                               

                                Rendering_fac_street,

                                Rendering_fac_city,

                                Rendering_fac_state,

                                Rendering_fac_zip,

                                --clinical_rationale = ISNULL(CAST(REPLACE(REPLACE(REPLACE(g.clinical_rationale, CHAR(13), ''), CHAR(10), ''), CHAR(9), '') AS VARCHAR(255)),''),

                                current_status,

                                current_queue,

                                current_queue_date = convert(varchar(10), current_queue_date, 120) ,

                               

                                auth_validity_start,

                                auth_validity_end,

                               

                                Has_Clinical_Pend_status,

                                Clinical_Pend_status_date,

                                Sent_to_PM_ClinReview_Queue,

                                PM_ClinReview_queue_date,

                                PhysMed_Clinical_Docu_Review_queue_date,

                               

                                hab_or_rehab,

                                eval_date

                               

                               

into        #g_results

from      #g_final g with(nolock)

 

 

 

 

if @Counter=1

select @DBNAME as dbname, * into #result from #g_results

else

INSERT INTO #result

(dbname              ,

car_id    ,

car_name            ,

auth_id ,

tracking_number              ,

initial_or_subsequent     ,

repl_for_validity_ext       ,

repl_for_addtl_visits       ,

Request_Date    ,

Date_of_Svc       ,

plan_name          ,

line_of_business               ,

expedite_flag     ,

cpt4_code           ,

proc_desc            ,

icd10_code         ,

icd10_descr        ,

Apprv_by_Algo ,

accept_or_decline_trmt_plan      ,

determ_date      ,

final_outcome   ,

final_determ      ,

UM_Outcome   ,

auth_origin         ,

visits_requested               ,

visits_approved ,

visits_denied      ,

client_member_id            ,

mbr_dob             ,

mbr_name          ,

client_physician_id          ,

phys_tax_id        ,

phys_npi              ,

phys_name         ,

Rendering_is_OON          ,

Provider_Type   ,

Rendering_fac_name      ,

Rendering_MIS ,

Rendering_tax_id             ,

Rendering_NPI  ,

Rendering_fac_street      ,

Rendering_fac_city          ,

Rendering_fac_state       ,

Rendering_fac_zip            ,

current_status   ,

current_queue  ,

current_queue_date       ,

auth_validity_start          ,

auth_validity_end            ,

Has_Clinical_Pend_status              ,

Clinical_Pend_status_date            ,

Sent_to_PM_ClinReview_Queue               ,

PM_ClinReview_queue_date       ,

PhysMed_Clinical_Docu_Review_queue_date     ,

hab_or_rehab    ,

eval_date            

)

select @DBNAME as dbname,

car_id    ,

car_name            ,

auth_id ,

tracking_number              ,

initial_or_subsequent     ,

repl_for_validity_ext       ,

repl_for_addtl_visits       ,

Request_Date    ,

Date_of_Svc       ,

plan_name          ,

line_of_business               ,

expedite_flag     ,

cpt4_code           ,

proc_desc            ,

icd10_code         ,

icd10_descr        ,

Apprv_by_Algo ,

accept_or_decline_trmt_plan      ,

determ_date      ,

final_outcome   ,

final_determ      ,

UM_Outcome   ,

auth_origin         ,

visits_requested               ,

visits_approved ,

visits_denied      ,

client_member_id            ,

mbr_dob             ,

mbr_name          ,

client_physician_id          ,

phys_tax_id        ,

phys_npi              ,

phys_name         ,

Rendering_is_OON          ,

Provider_Type   ,

Rendering_fac_name      ,

Rendering_MIS ,

Rendering_tax_id             ,

Rendering_NPI  ,

Rendering_fac_street      ,

Rendering_fac_city          ,

Rendering_fac_state       ,

Rendering_fac_zip            ,

current_status   ,

current_queue  ,

current_queue_date       ,

auth_validity_start          ,

auth_validity_end            ,

Has_Clinical_Pend_status              ,

Clinical_Pend_status_date            ,

Sent_to_PM_ClinReview_Queue               ,

PM_ClinReview_queue_date       ,

PhysMed_Clinical_Docu_Review_queue_date     ,

hab_or_rehab    ,

eval_date            

from #g_results

order by determ_date

 

SET @Counter  = @Counter  + 1

 

 

end

 

select 'result',  * from #result

order by determ_date

 