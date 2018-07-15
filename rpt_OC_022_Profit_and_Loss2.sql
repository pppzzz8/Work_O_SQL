USE [Oceania_Reporting]
GO

/****** Object:  StoredProcedure [dbo].[rpt_OC_022_Profit_and_Loss]    Script Date: 16/07/2018 11:26:31 a.m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[rpt_OC_022_Profit_and_Loss]
	@End_Date				datetime
	,@Facility				varchar(2000)
	,@Dataareaid			varchar(200)
	,@Cluster_Executive		varchar(2000)
	,@Consolidate_Facility	bit
	,@Facility_Type			varchar(200)
	,@Budget_Model			varchar(2000)
as

/*
--testing
declare
	@End_Date				datetime		= convert(datetime, '2012/08/31', 111)
	,@Facility				varchar(2000)	= '240'
	,@Dataareaid			varchar(200)	= 'C1'
	,@Cluster_Executive		varchar(2000)	= '%'
	,@Consolidate_Facility	bit				= 0
	,@Facility_Type			varchar(200)	= '%'
	,@Budget_Model			varchar(2000)	= 'FY12'
*/

-- Build Report Variables
declare 
	@Report_End_Date		datetime		= dateadd(DAY, 1, @End_Date)
declare
	@Report_Start_Date		datetime		= dateadd(month, -25, @Report_End_Date)
	,@13_Months_Start_Date	datetime		= dateadd(month, -13, @Report_End_Date)
	,@Report_YTD_Start_Date	datetime		= dbo.get_financial_start_date (@End_Date)
declare
	@LY_Fin_Start_Date		datetime		= dateadd(year, -1, @Report_YTD_Start_Date)
	,@LY_Fin_End_Date		datetime		= dateadd(year, -1, @Report_End_Date)
declare
	@Facility_List			varchar(2000)	= ''


-- Set @Facility_list to be the list of facilities the exec has access to or the Facility_type
begin
	declare @facility_code varchar(20)

	if @Cluster_Executive <> '%' or @Facility_Type <> '%'
	begin
		DECLARE facility_cursor CURSOR FOR  
			select Facility_Code 
			from Facility_Details
			where 
				(	(@Cluster_executive <> '%' and isnull(Cluster_Executive,'') like @Cluster_Executive)
					or (@facility_type <> '%' and isnull([type],'') like @Facility_Type))
				and charindex(facility_code, @facility) <> 0
	end
	else 
	begin
		DECLARE facility_cursor CURSOR FOR  
			select num
			from [DDB460-01\I460_01].PeoplePoint_Live.dbo.DIMENSIONS
			where dataareaid = 'VIRT'
				and charindex(num, @facility) <> 0
				and dimensioncode = 0
	end

	OPEN facility_cursor   
	FETCH NEXT FROM facility_cursor INTO @Facility_Code

	WHILE @@FETCH_STATUS = 0   
	BEGIN   
		   select @Facility_List = @Facility_List + ', ' + @Facility_Code

		   FETCH NEXT FROM facility_cursor INTO @Facility_code
	END   

	CLOSE facility_cursor   
	DEALLOCATE facility_cursor 	
end



-- Create temp table
create table #GL# (
	Record_Type				char(1)
	,Facility_Code			varchar(20)
	,Facility_Desc			varchar(100)
	,Group_Code				int
	,Account_Description	varchar(200)
	,Ordering				int
	,Trans_Month			datetime
	,Amount					decimal(28,12)
	,MTD_Amount				decimal(28,12)
	,YTD_Amount				decimal(28,12)
	,Budget_Amount			decimal(28,12)
	,Budget_MTD_Amount		decimal(28,12)
	,Budget_YTD_Amount		decimal(28,12)
	)

create table #Dates# (
	calandar_date		datetime
	)

-- Populate dates table
declare @date			datetime	= @Report_Start_Date

while @date < @Report_End_Date
begin
	insert into #Dates#
	select @date
	
	set @date = DATEADD(month, 1, @date)
end


-- Get GL Data - based on analysis code
insert into #GL# (
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Group_Code
	,Account_Description
	,Ordering
	,Trans_Month
	,Amount
	,MTD_Amount
	,YTD_Amount
	)

select
	'A'									as Record_Type
	,case
		when @Consolidate_Facility = 1 then '%'
		else facility.num
		end								as Facility_Code
	,case
		when @Consolidate_Facility = 1 then 'Consolidated'
		else facility.description
		end								as Facility_Desc
	,pl_accounts.group_code
	,pl_accounts.account_description
	,pl_accounts.ordering
	
	,convert(datetime, convert(varchar(4), year(isnull(LEDGERTRANS.TRANSDATE, #Dates#.calandar_date)))
			+ '/' + CONVERT(varchar(2), month(isnull(LEDGERTRANS.transdate, #Dates#.calandar_date)))
			+ '/01', 111)				as Trans_Month

	,isnull(sum(case
		when pl_accounts.group_code = 11 then LEDGERTRANS.qty
		when pl_accounts.reverse_sign = 1 then LEDGERTRANS.AMOUNTMST * -1
		else LEDGERTRANS.AMOUNTMST
		end),0) as Amount

	,isnull(sum(case
		when pl_accounts.group_code = 11 and year(LEDGERTRANS.TRANSDATE) = year(@End_Date) and month(LEDGERTRANS.TRANSDATE) = month(@End_Date) then LEDGERTRANS.QTY
		when pl_accounts.reverse_sign = 1 and year(LEDGERTRANS.TRANSDATE) = year(@End_Date) and month(LEDGERTRANS.TRANSDATE) = month(@End_Date) then LEDGERTRANS.AMOUNTMST * -1
		when year(LEDGERTRANS.TRANSDATE) = year(@End_Date) and month(LEDGERTRANS.TRANSDATE) = month(@End_Date) then LEDGERTRANS.AMOUNTMST
		else 0
		end),0)							as MTD_Amount

	,isnull(sum(case
		when pl_accounts.group_code = 11 and LEDGERTRANS.TRANSDATE >= @Report_YTD_Start_Date then LEDGERTRANS.QTY
		when pl_accounts.reverse_sign = 1 and LEDGERTRANS.TRANSDATE >= @Report_YTD_Start_Date then LEDGERTRANS.AMOUNTMST * -1
		when LEDGERTRANS.TRANSDATE >= @Report_YTD_Start_Date then LEDGERTRANS.AMOUNTMST
		else 0
		end),0)							as YTD_Amount
from 
	dbo.PL_Accounts 
	
	inner join #Dates#
		on 1=1

	left outer join [DDB460-01\I460_01].PeoplePoint_Live.dbo.DIMENSIONS facility
		on  facility.dimensioncode = 0
		and facility.DATAAREAID = 'VIRT'
--		and charindex(facility.num, @Facility) <> 0
		and charindex(facility.num, @Facility_List) <> 0

	left outer join [DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERTRANS
		on  LEDGERTRANS.accountnum = pl_accounts.account_code
		and ledgertrans.dimension3_ = ISNULL(pl_Accounts.Analysis_Code, ledgertrans.dimension3_)
		and ledgertrans.dimension2_ = ISNULL(pl_Accounts.Commodity_Code, ledgertrans.dimension2_)
		and charindex(LEDGERTRANS.DATAAREAID, @Dataareaid) <> 0
		and LEDGERTRANS.TRANSDATE >= @Report_Start_Date
		and LEDGERTRANS.TRANSDATE < @Report_End_Date
		and ledgertrans.posting <> 19
		and ledgertrans.operationstax = 0
		and LEDGERTRANS.DIMENSION = facility.NUM
		and charindex(ledgertrans.dimension, @Facility_List) <> 0
		
		and #Dates#.calandar_date = convert(datetime, convert(varchar(4), year(LEDGERTRANS.TRANSDATE))
										+ '/' + CONVERT(varchar(2), month(LEDGERTRANS.transdate))
										+ '/01', 111)
		
group by
	case
		when @Consolidate_Facility = 1 then '%'
		else facility.num
		end
	,case
		when @Consolidate_Facility = 1 then 'Consolidated'
		else facility.description
		end
	,pl_accounts.group_code
	,pl_accounts.account_description
	,pl_accounts.ordering
	,convert(datetime, convert(varchar(4), year(isnull(LEDGERTRANS.TRANSDATE, #Dates#.Calandar_date)))
			+ '/' + CONVERT(varchar(2), month(isnull(LEDGERTRANS.transdate,#Dates#.calandar_date)))
			+ '/01', 111)
order by 1,2,3,4,5,6,7


-- Get Budget Data
insert into #GL# (
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Group_Code
	,Account_Description
	,Ordering
	,Trans_Month
	,Budget_Amount
	,Budget_MTD_Amount
	,Budget_YTD_Amount
	)

select
	'B'									as Record_Type
	,case
		when @Consolidate_Facility = 1 then '%'
		else LEDGERBUDGET.DIMENSION
		end								as Facility_Code
	,case
		when @Consolidate_Facility = 1 then 'Consolidated'
		else facility.DESCRIPTION
		end								as Facility_Desc
	,pl_accounts.group_code
	,pl_accounts.account_description
	,pl_accounts.ordering

	,convert(datetime, convert(varchar(4), year(LEDGERBUDGET.STARTDATE))
			+ '/' + CONVERT(varchar(2), month(LEDGERBUDGET.STARTDATE))
			+ '/01', 111)				as Trans_Month
			
	,sum(case
		when ledgertable.accountcategoryref = 53 and pl_accounts.reverse_sign = 1 then ledgerbudget.qty * -1
		when ledgertable.accountcategoryref = 53 then ledgerbudget.qty
		when pl_accounts.reverse_sign = 1 then ledgerbudget.amount * -1
		else ledgerbudget.amount
		end)			as Budget_Amount

	,sum(case
		when ledgertable.accountcategoryref = 53 
			and pl_accounts.reverse_sign = 1 
			and year(LEDGERBUDGET.STARTDATE) = year(@End_Date) 
			and month(LEDGERBUDGET.STARTDATE) = month(@End_Date) then ledgerbudget.qty * -1
		when ledgertable.accountcategoryref = 53 
			and year(LEDGERBUDGET.STARTDATE) = year(@End_Date) 
			and month(LEDGERBUDGET.STARTDATE) = month(@End_Date) then ledgerbudget.qty
		when pl_accounts.reverse_sign = 1 
			and year(LEDGERBUDGET.STARTDATE) = year(@End_Date) 
			and month(LEDGERBUDGET.STARTDATE) = month(@End_Date) then ledgerbudget.amount * -1
		when year(LEDGERBUDGET.STARTDATE) = year(@End_Date) 
			and month(LEDGERBUDGET.STARTDATE) = month(@End_Date) then ledgerbudget.amount
		else 0
		end)								as Budget_MTD_Amount

	,sum(case
		when ledgertable.accountcategoryref = 53 
			and pl_accounts.reverse_sign = 1 
			and LEDGERBUDGET.STARTDATE >= @Report_YTD_Start_Date then ledgerbudget.qty * -1
		when ledgertable.accountcategoryref = 53 
			and LEDGERBUDGET.STARTDATE >= @Report_YTD_Start_Date then ledgerbudget.qty
			
		when pl_accounts.reverse_sign = 1 and LEDGERBUDGET.STARTDATE >= @Report_YTD_Start_Date then ledgerbudget.amount * -1
		when LEDGERBUDGET.STARTDATE >= @Report_YTD_Start_Date then ledgerbudget.amount
		else 0
		end)								as Budget_YTD_Amount

from 
	[DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERBUDGET
	
--	inner join [DDB460-01\I460_01].PeoplePoint_Live.dbo.BUDGETMODEL
--		on  ledgerbudget.DATAAREAID = budgetmodel.DATAAREAID
--		and ledgerbudget.modelnum = budgetmodel.MODELID
		
	inner join [DDB460-01\I460_01].PeoplePoint_Live.dbo.DIMENSIONS facility
		on  ledgerbudget.DIMENSION = facility.NUM
		and facility.DATAAREAID = 'virt'
		and facility.DIMENSIONCODE = 0
		and charindex(facility.num, @Facility_List) <> 0

	inner join dbo.pl_accounts
		on  ledgerbudget.accountnum = pl_accounts.account_code
		and LEDGERBUDGET.dimension3_ = ISNULL(pl_Accounts.analysis_code, LEDGERBudget.dimension3_)
		and LEDGERBUDGET.dimension2_ = ISNULL(pl_Accounts.Commodity_Code, LEDGERBudget.dimension2_)
	
	inner join [DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERTABLE
		on  LEDGERBUDGET.ACCOUNTNUM = ledgertable.ACCOUNTNUM
		and LEDGERTABLE.DATAAREAID = 'VIRT'

where 
	charindex(LEDGERBUDGET.DATAAREAID, @Dataareaid) <> 0
	and LEDGERBUDGET.STARTDATE >= @Report_Start_Date
	and LEDGERBUDGET.STARTDATE < @Report_End_Date
	and charindex(ledgerbudget.dimension, @Facility_List) <> 0
	and charindex(ledgerbudget.modelnum, @Budget_Model) <> 0

group by
	case
		when @Consolidate_Facility = 1 then '%'
		else LEDGERBUDGET.DIMENSION
		end
	,case
		when @Consolidate_Facility = 1 then 'Consolidated'
		else facility.DESCRIPTION
		end
	,pl_accounts.group_code
	,pl_accounts.account_description
	,pl_accounts.ordering

	,convert(datetime, convert(varchar(4), year(LEDGERBUDGET.STARTDATE))
			+ '/' + CONVERT(varchar(2), month(LEDGERBUDGET.STARTDATE))
			+ '/01', 111)

			

-- Set Group Totals
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Group_Code
	,case
		when Group_Code = 1 then 'Care Income'
		when Group_Code = 2 then 'Village Income'
		when Group_Code = 3 then 'Other Income'
		when Group_Code = 4 then 'Total Staff Costs'
		when Group_Code = 5 then 'Total Patient welfare'
		when Group_Code = 6 then 'Total Occupancy'
		when Group_Code = 7 then 'Total overheads'
		else ''
		end					as Account_Description
	,100					as Ordering
	,Trans_Month
	,sum(Amount)			as Amount
	,sum(MTD_Amount)		as MTD_Amount
	,sum(YTD_Amount)		as YTD_Amount
	,sum(Budget_Amount)		as Budget_Amount
	,sum(Budget_MTD_Amount)	as Budget_MTD_Amount
	,sum(Budget_YTD_Amount)	as Budget_YTD_Amount
from 
	#GL#
where
	Group_Code <= 7
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,case
		when Group_Code = 1 then 'Care Income'
		when Group_Code = 2 then 'Village Income'
		when Group_Code = 3 then 'Other Income'
		when Group_Code = 4 then 'Total Staff Costs'
		when Group_Code = 5 then 'Total Patient welfare'
		when Group_Code = 6 then 'Total Occupancy'
		when Group_Code = 7 then 'Total overheads'
		else ''
		end
	,Trans_Month
	,Group_Code

-- Set Total Income
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,3 as Group_Code
	,'Total Income'			as Account_Description
	,101					as Ordering
	,Trans_Month
	,sum(Amount)			as Amount
	,sum(MTD_Amount)		as MTD_Amount
	,sum(YTD_Amount)		as YTD_Amount
	,sum(Budget_Amount)		as Budget_Amount
	,sum(Budget_MTD_Amount)	as Budget_MTD_Amount
	,sum(Budget_YTD_Amount)	as Budget_YTD_Amount
from 
	#GL#
where
	Group_Code in (1,2,3)
	and Ordering = 100
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month

-- Set Gross Margin $
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,6 as Group_Code
	,'Gross Margin $'		as Account_Description
	,101					as Ordering
	,Trans_Month
	,sum(case
		when group_code in (1,2,3) then Amount
		else Amount * -1
		end)			as Amount
	,sum(case
		when group_code in (1,2,3) then MTD_Amount
		else MTD_Amount * -1
		end)		as MTD_Amount
	,sum(case
		when group_code in (1,2,3) then YTD_Amount
		else YTD_Amount * -1
		end)		as YTD_Amount

	,sum(case
		when group_code in (1,2,3) then Budget_Amount
		else Budget_Amount * -1
		end)		as Budget_Amount
	,sum(case
		when group_code in (1,2,3) then Budget_MTD_Amount
		else Budget_MTD_Amount * -1
		end)	as Budget_MTD_Amount
	,sum(case
		when group_code in (1,2,3) then Budget_YTD_Amount
		else Budget_YTD_Amount * -1
		end)	as Budget_YTD_Amount
from 
	#GL#
where
	Group_Code in (1,2,3,4,5,6)
	and Ordering = 100
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month


-- Set Gross Margin %
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,6 as Group_Code
	,'Gross Margin %'		as Account_Description
	,102					as Ordering
	,Trans_Month
	,case
		when SUM(case when group_code = 3 then Amount else 0 end) <> 0
			then SUM(case when group_code = 6 then Amount else 0 end) / SUM(case when group_code = 3 then Amount else 0 end)
		else 0
		end					as Amount
		
	,case
		when SUM(case when group_code = 3 then MTD_Amount else 0 end) <> 0
			then SUM(case when group_code = 6 then MTD_Amount else 0 end) / SUM(case when group_code = 3 then MTD_Amount else 0 end)
		else 0
		end					as MTD_Amount

-- Replaced TG 7/5/2012, because this is a percentage, it cant be summed in the report
/*	,case
		when SUM(case when group_code = 3 then YTD_Amount else 0 end) <> 0
			then SUM(case when group_code = 6 then YTD_Amount else 0 end) / SUM(case when group_code = 3 then YTD_Amount else 0 end)
		else 0
		end					as YTD_Amount
*/
	,case
		when year(trans_month) = year(@End_Date) and month(trans_month) = month(@End_date) and record_type = 'A' then (
				select
					case
						when SUM(case when group_code = 3 then YTD_Amount else 0 end) <> 0
							then SUM(case when group_code = 6 then YTD_Amount else 0 end) / SUM(case when group_code = 3 then YTD_Amount else 0 end)
						else 0
						end
				from #gl#
				where
					Group_Code in (3,6)
					and Ordering = 101
					and record_type = 'A'
			)
		else 0
		end					as YTD_Amount
		

	,case
		when SUM(case when group_code = 3 then Budget_Amount else 0 end) <> 0
			then SUM(case when group_code = 6 then Budget_Amount else 0 end) / SUM(case when group_code = 3 then Budget_Amount else 0 end)
		else 0
		end					as Budget_Amount

	,case
		when SUM(case when group_code = 3 then Budget_MTD_Amount else 0 end) <> 0
			then SUM(case when group_code = 6 then Budget_MTD_Amount else 0 end) / SUM(case when group_code = 3 then Budget_MTD_Amount else 0 end)
		else 0
		end					as Budget_MTD_Amount

-- Replaced TG 7/5/2012, because this is a percentage, it cant be summed in the report
/*	,case
		when SUM(case when group_code = 3 then Budget_YTD_Amount else 0 end) <> 0
			then SUM(case when group_code = 6 then Budget_YTD_Amount else 0 end) / SUM(case when group_code = 3 then Budget_YTD_Amount else 0 end)
		else 0
		end					as Budget_YTD_Amount
*/
	,case
		when year(trans_month) = year(@End_Date) and month(trans_month) = month(@End_date) and record_type = 'B' then (
				select
					case
						when SUM(case when group_code = 3 then Budget_YTD_Amount else 0 end) <> 0
							then SUM(case when group_code = 6 then Budget_YTD_Amount else 0 end) / SUM(case when group_code = 3 then Budget_YTD_Amount else 0 end)
						else 0
						end
				from #gl#
				where
					Group_Code in (3,6)
					and Ordering = 101
					and record_type = 'B'
			)
		else 0
		end					as Budget_YTD_Amount

from 
	#GL#
where
	Group_Code in (3,6)
	and Ordering = 101
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month

-- Set Total Operating Expenses
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,7 as Group_Code
	,'Total Operating Expenses'	as Account_Description
	,101						as Ordering
	,Trans_Month
	,sum(Amount)				as Amount
	,sum(MTD_Amount)			as MTD_Amount
	,sum(YTD_Amount)			as YTD_Amount
	,sum(Budget_Amount)			as Budget_Amount
	,sum(Budget_MTD_Amount)		as Budget_MTD_Amount
	,sum(Budget_YTD_Amount)		as Budget_YTD_Amount
from 
	#GL#
where
	Group_Code in (4,5,6,7)
	and Ordering = 100
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month

-- Set E.B.I.T.D.A.R
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,7 as Group_Code
	,'E.B.I.T.D.A.R'		as Account_Description
	,102					as Ordering
	,Trans_Month
	,sum(case
		when group_code in (3) then Amount
		else Amount * -1
		end)			as Amount
	,sum(case
		when group_code in (3) then MTD_Amount
		else MTD_Amount * -1
		end)		as MTD_Amount
	,sum(case
		when group_code in (3) then YTD_Amount
		else YTD_Amount * -1
		end)		as YTD_Amount

	,sum(case
		when group_code in (3) then Budget_Amount
		else Budget_Amount * -1
		end)		as Budget_Amount
	,sum(case
		when group_code in (3) then Budget_MTD_Amount
		else Budget_MTD_Amount * -1
		end)	as Budget_MTD_Amount
	,sum(case
		when group_code in (3) then Budget_YTD_Amount
		else Budget_YTD_Amount * -1
		end)	as Budget_YTD_Amount
from 
	#GL#
where
	Group_Code in (3,7)
	and Ordering = 101
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month

-- Set E.B.I.T.D.A
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,8 as Group_Code
	,'E.B.I.T.D.A'		as Account_Description
	,103					as Ordering
	,Trans_Month
	,sum(case
		when group_code in (7) then Amount
		else Amount * -1
		end)			as Amount
	,sum(case
		when group_code in (7) then MTD_Amount
		else MTD_Amount * -1
		end)		as MTD_Amount
	,sum(case
		when group_code in (7) then YTD_Amount
		else YTD_Amount * -1
		end)		as YTD_Amount

	,sum(case
		when group_code in (7) then Budget_Amount
		else Budget_Amount * -1
		end)		as Budget_Amount
	,sum(case
		when group_code in (7) then Budget_MTD_Amount
		else Budget_MTD_Amount * -1
		end)	as Budget_MTD_Amount
	,sum(case
		when group_code in (7) then Budget_YTD_Amount
		else Budget_YTD_Amount * -1
		end)	as Budget_YTD_Amount
from 
	#GL#
where
	(Group_Code = 7 and Ordering = 102)
	or (Group_Code = 8 and Ordering < 100)
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month


-- Set NET SURPLUS ATT. TO SHAREHOLDERS
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,9 as Group_Code
	,'NET SURPLUS ATT. TO SHAREHOLDERS'		as Account_Description
	,104					as Ordering
	,Trans_Month
	,sum(case
		when group_code in (8) then Amount
		else Amount * -1
		end)			as Amount
	,sum(case
		when group_code in (8) then MTD_Amount
		else MTD_Amount * -1
		end)		as MTD_Amount
	,sum(case
		when group_code in (8) then YTD_Amount
		else YTD_Amount * -1
		end)		as YTD_Amount

	,sum(case
		when group_code in (8) then Budget_Amount
		else Budget_Amount * -1
		end)		as Budget_Amount
	,sum(case
		when group_code in (8) then Budget_MTD_Amount
		else Budget_MTD_Amount * -1
		end)	as Budget_MTD_Amount
	,sum(case
		when group_code in (8) then Budget_YTD_Amount
		else Budget_YTD_Amount * -1
		end)	as Budget_YTD_Amount
from 
	#GL#
where
	(Group_Code = 8 and Ordering = 103)
	or (Group_Code = 9 and Ordering < 100)
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month


-- Set NET RETAINED EARNINGS MOVEMENT
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,10 as Group_Code
	,'NET RETAINED EARNINGS MOVEMENT'		as Account_Description
	,105					as Ordering
	,Trans_Month
	,sum(case
		when group_code in (9) then Amount
		else Amount * -1
		end)			as Amount
	,sum(case
		when group_code in (9) then MTD_Amount
		else MTD_Amount * -1
		end)		as MTD_Amount
	,sum(case
		when group_code in (9) then YTD_Amount
		else YTD_Amount * -1
		end)		as YTD_Amount

	,sum(case
		when group_code in (9) then Budget_Amount
		else Budget_Amount * -1
		end)		as Budget_Amount
	,sum(case
		when group_code in (9) then Budget_MTD_Amount
		else Budget_MTD_Amount * -1
		end)	as Budget_MTD_Amount
	,sum(case
		when group_code in (9) then Budget_YTD_Amount
		else Budget_YTD_Amount * -1
		end)	as Budget_YTD_Amount
from 
	#GL#
where
	(Group_Code = 9 and Ordering = 104)
	or (Group_Code = 10 and Ordering < 100)
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month

-- Set Occupancy (%)
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,10 as Group_Code
	,'Occupancy (%)'		as Account_Description
	,106					as Ordering
	,Trans_Month
	,case
		when SUM(case when Ordering in (4,5,6) then Amount else 0 end) <> 0
			then SUM(case when Ordering in (1,2,3) then Amount else 0 end) / SUM(case when Ordering in (4,5,6) then Amount else 0 end)
		else 0
		end					as Amount
		
	,case
		when SUM(case when Ordering in (4,5,6) then MTD_Amount else 0 end) <> 0
			then SUM(case when Ordering in (1,2,3) then MTD_Amount else 0 end) / SUM(case when Ordering in (4,5,6) then MTD_Amount else 0 end)
		else 0
		end					as MTD_Amount

-- Replaced TG 7/5/2012, because this is a percentage, it cant be summed in the report
/*	,case
		when SUM(case when Ordering in (4,5,6) then YTD_Amount else 0 end) <> 0
			then SUM(case when Ordering in (1,2,3) then YTD_Amount else 0 end) / SUM(case when Ordering in (4,5,6) then YTD_Amount else 0 end)
		else 0
		end					as YTD_Amount
*/
	,case
		when year(trans_month) = year(@End_Date) and month(trans_month) = month(@End_date) and record_type = 'A' then (
				select
					case
						when SUM(case when ordering in (4,5,6) then YTD_Amount else 0 end) <> 0
							then SUM(case when ordering in (1,2,3) then YTD_Amount else 0 end) / SUM(case when ordering in (4,5,6) then YTD_Amount else 0 end)
						else 0
						end
				from #gl#
				where
					Group_Code in (11)
					and Ordering < 100
					and record_type = 'A'
			)
		else 0
		end					as YTD_Amount
		
	,case
		when SUM(case when Ordering in (4,5,6) then Budget_Amount else 0 end) <> 0
			then SUM(case when Ordering in (1,2,3) then Budget_Amount else 0 end) / SUM(case when Ordering in (4,5,6) then Budget_Amount else 0 end)
		else 0
		end					as Budget_Amount

	,case
		when SUM(case when Ordering in (4,5,6) then Budget_MTD_Amount else 0 end) <> 0
			then SUM(case when Ordering in (1,2,3) then Budget_MTD_Amount else 0 end) / SUM(case when Ordering in (4,5,6) then Budget_MTD_Amount else 0 end)
		else 0
		end					as Budget_MTD_Amount

-- Replaced TG 7/5/2012, because this is a percentage, it cant be summed in the report
/*	,case
		when SUM(case when Ordering in (4,5,6) then Budget_YTD_Amount else 0 end) <> 0
			then SUM(case when Ordering in (1,2,3) then Budget_YTD_Amount else 0 end) / SUM(case when Ordering in (4,5,6) then Budget_YTD_Amount else 0 end)
		else 0
		end					as Budget_YTD_Amount
*/
	,case
		when year(trans_month) = year(@End_Date) and month(trans_month) = month(@End_date) and record_type = 'B' then (
				select
					case
						when SUM(case when ordering in (4,5,6) then Budget_YTD_Amount else 0 end) <> 0
							then SUM(case when ordering in (1,2,3) then Budget_YTD_Amount else 0 end) / SUM(case when ordering in (4,5,6) then Budget_YTD_Amount else 0 end)
						else 0
						end
				from #gl#
				where
					Group_Code in (11)
					and Ordering < 100
					and record_type = 'B'
			)
		else 0
		end					as Budget_YTD_Amount

from 
	#GL#
where
	Group_Code in (11)
	and Ordering < 100
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month

-- Set Staff cost/Revenue (%)
insert into #GL#
select
	Record_Type
	,Facility_Code
	,Facility_Desc
	,10 as Group_Code
	,'Staff cost/Revenue (%)'		as Account_Description
	,107					as Ordering
	,Trans_Month
	,case
		when SUM(case when Group_Code in (1) then Amount else 0 end) <> 0
			then SUM(case when Group_Code in (4) then Amount else 0 end) / SUM(case when Group_Code in (1) then Amount else 0 end)
		else 0
		end					as Amount
		
	,case
		when SUM(case when Group_Code in (1) then MTD_Amount else 0 end) <> 0
			then SUM(case when Group_Code in (4) then MTD_Amount else 0 end) / SUM(case when Group_Code in (1) then MTD_Amount else 0 end)
		else 0
		end					as MTD_Amount

-- Replaced TG 7/5/2012, because this is a percentage, it cant be summed in the report
/*	,case
		when SUM(case when Group_Code in (1) then YTD_Amount else 0 end) <> 0
			then SUM(case when Group_Code in (4) then YTD_Amount else 0 end) / SUM(case when Group_Code in (1) then YTD_Amount else 0 end)
		else 0
		end					as YTD_Amount
*/
	,case
		when year(trans_month) = year(@End_Date) and month(trans_month) = month(@End_date) and record_type = 'A' then (
				select
					case
						when SUM(case when group_code in (1) then YTD_Amount else 0 end) <> 0
							then SUM(case when group_code in (4) then YTD_Amount else 0 end) / SUM(case when group_code in (1) then YTD_Amount else 0 end)
						else 0
						end
				from #gl#
				where
					(	(Group_Code in (4) and Ordering = 100)
						or (Group_Code in (1) and Ordering = 100)
					)
					and record_type = 'A'
			)
		else 0
		end					as YTD_Amount



	,case
		when SUM(case when Group_Code in (1) then Budget_Amount else 0 end) <> 0
			then SUM(case when Group_Code in (4) then Budget_Amount else 0 end) / SUM(case when Group_Code in (1) then Budget_Amount else 0 end)
		else 0
		end					as Budget_Amount

	,case
		when SUM(case when Group_Code in (1) then Budget_MTD_Amount else 0 end) <> 0
			then SUM(case when Group_Code in (4) then Budget_MTD_Amount else 0 end) / SUM(case when Group_Code in (1) then Budget_MTD_Amount else 0 end)
		else 0
		end					as Budget_MTD_Amount

-- Replaced TG 7/5/2012, because this is a percentage, it cant be summed in the report
/*	,case
		when SUM(case when Group_Code in (1) then Budget_YTD_Amount else 0 end) <> 0
			then SUM(case when Group_Code in (4) then Budget_YTD_Amount else 0 end) / SUM(case when Group_Code in (1) then Budget_YTD_Amount else 0 end)
		else 0
		end					as Budget_YTD_Amount
*/
	,case
		when year(trans_month) = year(@End_Date) and month(trans_month) = month(@End_date) and record_type = 'B' then (
				select
					case
						when SUM(case when group_code in (1) then Budget_YTD_Amount else 0 end) <> 0
							then SUM(case when group_code in (4) then Budget_YTD_Amount else 0 end) / SUM(case when group_code in (1) then Budget_YTD_Amount else 0 end)
						else 0
						end
				from #gl#
				where
					(	(Group_Code in (4) and Ordering = 100)
						or (Group_Code in (1) and Ordering = 100)
					)
					and record_type = 'B'
			)
		else 0
		end					as Budget_YTD_Amount

from 
	#GL#
where
	(Group_Code in (4) and Ordering = 100)
	or (Group_Code in (1) and Ordering = 100)
group by
	Record_Type
	,Facility_Code
	,Facility_Desc
	,Trans_Month


-- Return Data
select
	#GL#.Record_Type
	,#GL#.Facility_Code
	,#GL#.Facility_Desc
	,Group_Code
	,Account_Description
	,Ordering
	,#GL#.Trans_Month
	,isnull(#GL#.Amount,0)				as Amount
	,isnull(#GL#.MTD_Amount,0)			as MTD_Amount
	,isnull(#GL#.YTD_Amount,0)			as YTD_Amount
	,isnull(#GL#.Budget_Amount,0)		as Budget_Amount
	,isnull(#GL#.Budget_MTD_Amount,0)	as Budget_MTD_Amount
	,isnull(#GL#.Budget_YTD_Amount,0)	as Budget_YTD_Amount
	
	,case
		when Group_Code = 6 and Ordering = 102 then '0%'
		when Group_Code = 10 and Ordering in (106,107) then '0%'
		else '#,0;(#,0)'
		end								as Field_Format

	,isnull(case
		when MONTH(Trans_Month) = MONTH(@End_Date) and YEAR(Trans_Month) = YEAR(@End_Date) then Amount
		when MONTH(Trans_Month) = MONTH(@End_Date) and YEAR(Trans_Month) = YEAR(@End_Date)-1 then Amount * -1
		else 0 
		end,0)							as PCP_MTD_Amount
	,ISNULL(
		(select
			case
				when Trans_Month >= @Report_YTD_Start_Date then Amount
				when Trans_Month >= @LY_Fin_Start_Date and Trans_Month <= @LY_Fin_End_Date then Amount * -1
				else 0
				end
		from #GL# LY
		where
			#GL#.Record_Type = LY.Record_Type
			and #GL#.Facility_Code = LY.Facility_Code
			and #GL#.Group_Code = LY.Group_Code
			and #GL#.Account_Description = LY.Account_Description
			and #GL#.Ordering = LY.Ordering
			and #GL#.Trans_Month = LY.Trans_Month
			),0)							as PCP_YTD_Amount
	,Facility_Details.Cluster_Executive
	,facility_details.Facility_Manager
	,facility_details.Type

	,case
		when #GL#.Group_Code <= 3 then 1
		when #GL#.Group_Code = 6 and #GL#.Ordering = 101 then 1
		when #GL#.Group_Code = 6 and #GL#.Ordering = 102 then 1
		when #GL#.Group_code = 7 and #GL#.Ordering = 102 then 1
		when #GL#.Group_code = 8 and #GL#.Ordering = 103 then 1
		when #GL#.Group_code = 9 and #GL#.Ordering = 104 then 1
		when #GL#.Group_code = 10 and #GL#.Ordering = 105 then 1
		when #GL#.Group_code = 10 and #GL#.Ordering = 106 then 1
		else 0
		end									as Income_or_Expense_Account
from
	#GL#
	left outer join Facility_Details
		on #GL#.Facility_Code = Facility_Details.Facility_Code
where
	Trans_Month >= @13_Months_Start_Date
order by
	1,2,4,6

	
-- Clean Up
drop table #GL#
drop table #Dates#

GO

