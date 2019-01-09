use nineced

DECLARE @CreditOffice int
SET @CreditOffice = 9833										--Should be parameter in final report


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
	and ar.tranTypeId = 10										--TranTypeId 10 = Invoice
	and ar.origAmount > 0										--Should be parameter in final report
	ORDER BY ate.shipDate desc, ar.origAmount desc
	)
FROM
CustAccount ca
LEFT OUTER JOIN OrgMember om on ca.id = om.id
WHERE 
om.divisionId = @CreditOffice
and EXISTS (SELECT * FROM ArTran atx WHERE atx.custAccountId = ca.id and atx.state = 0) 
and ca.typeId = 101												--Need to confirm with Ben Graham that this is the only type this report needs to show - TypeId 101 = Secured Lien

select
	c.[name]		as	'CustomerName'
,	c.num			as	'CustomerNumber'
,	ca.[name]		as	'CustomerAccountName'
,	ca.num			as	'CustomerAccountNumber'
,	om.divisionid		as	'CreditOffice'							
,	om.branchid		as	'ProfitCenter'								
,	[at].refnum		as	'ReferenceNumber'							
,	[at].docType		as	'DocumentType'								
,	l.[state]		as	'LienState'
,	l.jobName		as	'JobName'
,	l.materialAmt		as	'MaterialAmount'
,	oc.totalDue		as	'AmountDue'
,	[at].origAmount 	as	'TotalAmountLastShip'	
,	ate.shipDate		as	'LastShip'	
,	[at].tranDate		as	'TransactionDate'	
,	CONVERT (varchar, getdate(), 101)	as 'CurrentDate'
,	DATEDIFF (d, ate.shipDate, getdate())	as 'DayDifference'
						
					
from CustAccount ca												--customeraccountname; customeraccountnumber
left join Customer c			on c.id = ca.custid				--customername; customernumber
left join CustAccountLien l		on ca.lienId = l.id				--lienstate; jobname; materialamount
left join OrgCalc oc			on oc.orgId = ca.id				--totaldue
left outer join @LastShip ls		on ca.id = ls.caID					
left outer join ArTran [at]		on ls.lastshipid = [at].id			--referencenumber; documenttype
left outer join ArTranExt ate		on [at].Id = ate.id				--lastship
left outer join OrgMember om		on ca.id = om.id				--creditoffice; profitcenter
WHERE 
om.divisionId = @CreditOffice
and oc.totaldue > 0												--Should be parameter in final report
and DATEDIFF (d, ate.shipDate, getdate()) > 1					--Should be parameter in final report
order by 'TotalAmountLastShip'
