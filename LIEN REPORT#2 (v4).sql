use nineced

DECLARE @CreditOffice int
SET @CreditOffice = 9744	--Should be parameter in final report


DECLARE @LastShip TABLE 
(
caID int
,lastshipid int
)

INSERT INTO @LastShip (caID, lastshipid)

select
CA.id
,lastShipid = 
	(SELECT TOP 1
	ar.id
	FROM ArTran ar  
	left join ArTranExt ate on ate.id = ar.id
	WHERE ar.custAccountId = ca.id 
	and ate.shipDate is Not null
	and ar.tranTypeId = 10
	and ar.origAmount > 100	--Should be parameter in final report
	ORDER BY ate.shipDate desc, ar.origAmount desc
	)
FROM
CustAccount ca
LEFT OUTER JOIN OrgMember om on ca.id = om.id
WHERE 
om.divisionId = @CreditOffice
and EXISTS (SELECT * FROM ArTran atx WHERE atx.custAccountId = ca.id and atx.state = 0) 
and ca.typeId = 101	--Need to confirm with Ben Graham that this is the only type this report needs to show

select
	c.[name] as customername
,	c.num  as customernumber
,	ca.[name] as customeraccountname
,	ca.num as customeraccountnumber
,	om.divisionid as CreditOffice							
,	om.branchid as ProfitCenter								
,	[at].refnum													--refnum NEW ADDITION
,	[at].docType												--doctype NEW ADDITION
,	l.[state] as lienstate
,	l.jobName
,	l.materialAmt
,	oc.totalDue
,	ate.shipDate as 'Last Ship'
,	CONVERT (varchar, getdate(), 101) as 'current date'
,	DATEDIFF (d, ate.shipDate, getdate()) as 'daydiff'
,	[at].tranDate									--MAX trandate NEW ADDITION
,	[at].origAmount								--SUM of MAX trandates NEW ADDITION
from CustAccount ca										--customeraccountname, customeraccountnumber
left join Customer c on c.id = ca.custid				--customername, customernumber
left join CustAccountLien l on ca.lienId = l.id			--lienstate, jobname, materialamt
left join OrgCalc oc on oc.orgId = ca.id				--totaldue
left outer join @LastShip ls on ca.id = ls.caID
left outer join ArTran [at] on ls.lastshipid = [at].id
left outer join ArTranExt ate on [at].Id = ate.id
left outer join OrgMember om on ca.id = om.id
WHERE 
om.divisionId = @CreditOffice
and oc.totaldue > 10000	--Should be parameter in final report
and DATEDIFF (d, ate.shipDate, getdate()) > 90	--Should be parameter in final report
order by oc.totalDue

--Joseph Test
