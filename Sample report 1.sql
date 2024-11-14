---Member Loss Run report
--Parameters:
declare @AsOfDate as date,@InsuredID as integer,@YNBR as integer
set @AsOfDate = getdate()
set @InsuredID =3760 -- 6441
set @YNBR = 10
;with a as
(
select 
c.[Litigated],
pol.[PolicyNumber], pp.[PolicyYear],
[Date of Incident]=c.DateOfIncident,
pp.DisplayValue,
i.[InsuredName],
Insured_Address1=ia.[Address1],
Insured_Address2=ia.[Address2],
Insure_LocationDBA=ia.[LocationDBA],
Insured_City=ia.City,
Insured_State=ia.[State],
Insured_PostCode=ia.PostCode,

IncidentPostalCode=ci.[PostalCode],

i.[InsuredCode],
c.ClaimStatus,
ClaimStatusDesc=CASE c.ClaimStatus
WHEN 1 THEN 'OPEN'
WHEN 2	THEN 'CLOSED'
WHEN 3	THEN 'REOPENED'
WHEN 4	THEN 'WASTED'
WHEN 5	THEN 'DENIED'
WHEN 6	THEN 'REPORT ONLY'
END,

c.ClaimNumber,
cl.ClaimantFirstName,
cl.ClaimantLastName,
c.ClaimType,
ClaimTypeDesc=
case c.ClaimType
when 1 then 'INDEMNITY'
WHEN 2 THEN 'MEDICAL'
WHEN 3 THEN 'EXPENSE'
END,

LocationName=coalesce(ia.LocationName, ci.IncidentLocation),
Insured_Location=ia.LocationName,
Incident_Location=(select LocationName from dbo_InsuredAddresses ia where c.InsuredAddressID = ia.AddressID),--ci.IncidentLocation,
coi.CauseOfInjuryTitle,

--bp.BodyPart,
(select top 1 BodyPart from clm_BodyPart bp join clm_ClaimBodyPart cbp on bp.BodyPartID = cbp.BodyPartID where cbp.ClaimIncidentID = ci.ClaimIncidentID order by cbp.ClaimBodyPartID) BodyPart,
c.DateClosed,
TotalPaid=SUM(CASE WHEN p.[TenantID]=2 and c.ProgramID=4 and p.PaymentStatus=1 and p.Recovery<>1 THEN p.PaidAmount ELSE 0 END), --p.ReserveTypeID in (5,4,6,7)

MedicalPaidAmt=SUM(CASE WHEN p.ReserveTypeID=5   and p.PaymentStatus=1 and isnull(p.Recovery,0)<>1 THEN p.PaidAmount ELSE 0 END), 
IndemnityPaidAmt=SUM(CASE WHEN p.ReserveTypeID=4   and p.PaymentStatus=1 and isnull(p.Recovery,0)<>1 THEN p.PaidAmount ELSE 0 END) ,
ExpensePaidAmt=SUM(CASE WHEN p.ReserveTypeID=6   and p.PaymentStatus=1 and isnull(p.Recovery,0)<>1 THEN p.PaidAmount ELSE 0 END)  ,



Reserve1=isnull(r.Reserve1,0), --[ReserveStatus]=1 
Reserve2=SUM(CASE WHEN  p.PaymentStatus=1 and isnull(p.Recovery,0)=0 THEN p.PaidAmount ELSE 0 END),--Reserves=Reserve1-Reserve2

RecoveryAmt=SUM(CASE WHEN  p.PaymentStatus=1 and isnull(p.Recovery,0)=1 THEN p.PaidAmount ELSE 0 END),

IncurredAmt=iif
--(case when c.DateClosed is null then 'Open' /*when c.DateClosed >= @AsOfDate then 'Open'*/ else 'Closed'END = 'Open',
(case when c.DateClosed is null then 'Open' when c.ClaimStatus = 1 then 'Open' /*when c.DateClosed >= @AsOfDate then 'Open'*/ else 'Closed'END = 'Open',

isnull((select sum(Amount) from clm_Reserve  where ClaimID = c.ClaimID and ReserveStatus = 1 and ReserveDate <= @AsOfDate),0)          ,--TotalReserve,
isnull((select sum(PaidAmount) from clm_Payment where ClaimID = c.ClaimID and Recovery = 0 and PaymentStatus = 1 and PaymentDate <= @AsOfDate),0)--totalpaid
),
--IncurredAmt=sum (case when (c.DateClosed is null /*or c.DateClosed > @AsOfDate */) and p.PaymentStatus=1 then Reserve1  else case when  p.PaymentStatus=1 then p.PaidAmount else 0 end end),

pol.[EffectiveDate],
pol.[ExpirationDate]

from clm_Claim c
left join clm_Payment p on c.ClaimID=p.ClaimID and p.TenantID = 2 
join clm_Claimant cl on cl.ClaimantID = c.PrimaryClaimantID   --c.PrimaryClaimantID --p.ClaimantID 
--left join silver_insuredaddresses ia on  ia.AddressID = c.InsuredAddressID
join clm_ClaimIncident ci on ci.ClaimID = c.ClaimID
left join clm_CauseOfInjury coi on coi.CauseOfInjuryID = ci.CauseOfInjuryID
--left join silver_claimbodypart cbp on cbp.ClaimIncidentID = ci.ClaimIncidentID
--left join silver_bodypart bp on bp.BodyPartID = cbp.BodyPartID  

LEFT join
(
SELECT [ClaimID],Reserve1=SUM([Amount]) from clm_Reserve
WHERE 
[ReserveStatus]=1  --APPROVED

group by [ClaimID] --order by 2 desc
) r
--on c.ClaimID=r.ClaimID and  (c.DateClosed is null  /*or c.DateClosed > @AsOfDate*/ )
on c.ClaimID=r.ClaimID and  (c.DateClosed is null or c.ClaimStatus = 1/*or c.DateClosed > @AsOfDate*/ )
left join dbo_Insured i on c.InsuredID=i.InsuredID
left join dbo_InsuredAddresses ia on  i.[PrimaryAddressID]=ia.AddressID -- ia.AddressID = c.InsuredAddressID OR
left join  dbo_Policy pol on pol.PolicyID = c.PolicyID
left join dbo_PolicyQuote pq on /*pq.PolicyID=pol.[PolicyID] and */pq.QuoteID=pol.CurrentQuoteID
and pq.EffectiveDate<= c.DateOfIncident and pq.ExpirationDate>c.DateOfIncident and pq.PolicyQuoteStatus=2--BOUND
left join dbo_PolicyPeriods pp on pp.PolicyPeriodID = pol.PolicyPeriodID

WHERE 
c.DateOfIncident <= @AsOfDate
AND (c.InsuredID = @InsuredID   )
AND (c.ClaimStatus <> 4 or c.ClaimStatus IS null) --Not wasted

and c.ProgramID=4

group by 
c.ClaimNumber,
cl.ClaimantFirstName,
cl.ClaimantLastName,
c.ClaimType,
ia.LocationName,
coi.CauseOfInjuryTitle,
c.DateOfIncident,
--bp.BodyPart,
c.DateClosed,
r.Reserve1,
ci.IncidentLocation,
ia.LocationName,
i.[InsuredName],
ia.[Address1],
ia.[Address2],
ia.[LocationDBA],
ia.City,
ia.[State],
ia.PostCode,
i.[InsuredCode],
c.ClaimStatus,
pp.DisplayValue,
ci.[PostalCode],
c.DateOfIncident,
pol.[PolicyNumber], pp.[PolicyYear],c.[Litigated],

pol.[EffectiveDate],
pol.[ExpirationDate],c.ClaimID,
c.InsuredAddressID,
ci.ClaimIncidentID
),
k as
(
select
PolicyYear= b.Policy_Year,
Litigated,
--PolicyNumber,
[Date of Incident],
DisplayValue,
InsuredName,
Insured_Address1,
Insured_Address2,
Insure_LocationDBA,
Insured_City,
Insured_State,
Insured_PostCode,
IncidentPostalCode,
InsuredCode,
ClaimStatus,
ClaimStatusDesc,
ClaimNumber,
ClaimantFirstName,
ClaimantLastName,
ClaimType,
ClaimTypeDesc,
LocationName,
Insured_Location,
Incident_Location,
CauseOfInjuryTitle,
BodyPart,
DateClosed,
TotalPaid=ISNULL(TotalPaid,0),
MedicalPaidAmt=ISNULL(MedicalPaidAmt,0),
IndemnityPaidAmt=ISNULL(IndemnityPaidAmt,0),
ExpensePaidAmt=ISNULL(ExpensePaidAmt,0),
Reserve1=ISNULL(Reserve1,0),
Reserve2=ISNULL(Reserve2,0),
RecoveryAmt=ISNULL(RecoveryAmt,0),
IncurredAmt=ISNULL(IncurredAmt,0),
EffectiveDate,
ExpirationDate

,
OutstandingReserve=case when UPPER(ClaimStatusDesc)='OPEN' THEN Reserve1-Reserve2 ELSE 0 END
--,
 --Renewal_Month=isnull((select max( month([EffectiveDate]) )from dbo_Policy WHERE InsuredID=@InsuredID) ,10)
from 

(
select * from(
--select year(@AsOfDate)
select distinct year([EffectiveDate]) as Policy_Year from [dbo].[dbo_Policy] where [InsuredID]=@InsuredID and [EffectiveDate] is not null and year([EffectiveDate])>= YEAR(@AsOfDate) - (@YNBR-1 )


)a
where Policy_Year >= YEAR(@AsOfDate) - (@YNBR-1 )

)b 
OUTER APPLY
(
select a.* from a
where  a.[PolicyYear]=b.Policy_Year


and  a.PolicyYear >= YEAR(@AsOfDate) - (@YNBR-1 )
)c

)

 select k.*, 
	  Renewal_Month=month(spol.EffectiveDate),
	  eff_day_policy=spol.EffectiveDate,
	  exp_day_policy=spol.ExpirationDate,
	  eff_day_policy_string=convert(varchar(25), spol.EffectiveDate, 101),
	  exp_day_policy_string=convert(varchar(25), spol.ExpirationDate, 101),
	  spol.[PolicyStatus], spol.PolicyNumber
	  from k 
	  right join
	 dbo_Policy spol on  spol.[InsuredID]=@InsuredID and k.PolicyYear=year(spol.[EffectiveDate])  and year(spol.[EffectiveDate]) >= YEAR(@AsOfDate) - (@YNBR-1 )
	
	where k.PolicyYear  >= YEAR(@AsOfDate) - (@YNBR-1 )
	and 
(
	spol.PolicyNumber is not null 

	or

isnull(TotalPaid,0)>0 or 
isnull(MedicalPaidAmt,0)>0 or
isnull(IndemnityPaidAmt,0)>0 or
isnull(ExpensePaidAmt,0)>0 or
isnull(Reserve1,0)>0 or
isnull(Reserve2,0)>0 or
isnull(RecoveryAmt,0)>0 or
isnull(IncurredAmt,0)>0 
)
	  order by 1 desc