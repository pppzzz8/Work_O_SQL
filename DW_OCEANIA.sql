USE [master]
GO
/****** Object:  Database [DW_OCEANIA]    Script Date: 16/07/2018 11:49:35 a.m. ******/
CREATE DATABASE [DW_OCEANIA]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DW_OCEANIA', FILENAME = N'D:\MSSQL13.I460_01\MSSQL\DATA\DW_OCEANIA.mdf' , SIZE = 8192000KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DW_OCEANIA_log', FILENAME = N'D:\MSSQL13.I460_01\MSSQL\DATA\DW_OCEANIA_log.ldf' , SIZE = 3293184KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DW_OCEANIA].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [DW_OCEANIA] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET ARITHABORT OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [DW_OCEANIA] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DW_OCEANIA] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DW_OCEANIA] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET  DISABLE_BROKER 
GO
ALTER DATABASE [DW_OCEANIA] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DW_OCEANIA] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [DW_OCEANIA] SET  MULTI_USER 
GO
ALTER DATABASE [DW_OCEANIA] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DW_OCEANIA] SET DB_CHAINING OFF 
GO
ALTER DATABASE [DW_OCEANIA] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [DW_OCEANIA] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
USE [DW_OCEANIA]
GO
/****** Object:  User [DESKTOP\PeterZ.OCA]    Script Date: 16/07/2018 11:49:36 a.m. ******/
CREATE USER [DESKTOP\PeterZ.OCA] FOR LOGIN [DESKTOP\PeterZ.OCA] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [DESKTOP\PeterZ.OCA]
GO
/****** Object:  StoredProcedure [dbo].[get_CPACK]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_CPACK]
as
DECLARE @DATE DATE
SELECT @DATE=GETDATE()
--SELECT @DATE
	INSERT INTO dbo.Fact_CPACK
		SELECT H.DIMENSION, @DATE [Date], ROUND(SUM(FEEAMOUNT)/1.15,2) Total_CPACK 
		--INTO dbo.Fact_CPACK
		FROM [DDB460-01\I460_01].[PeoplePoint_Live].dbo.ECL_ACMFeeSetup C
		INNER JOIN [DDB460-01\I460_01].[PeoplePoint_Live].dbo.ECL_ACMACCOMMODATIONHISTORY H ON C.ACCOMMODATIONHISTORYID=H.ACCOMMODATIONHISTORYID 
		  WHERE FEEID='CPACK' AND STARTDATE<>ENDDATE AND @DATE BETWEEN STARTDATE AND CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN '2100-01-01 00:00:00.000' ELSE ENDDATE END
		  GROUP BY H.DIMENSION
		  ORDER BY H.DIMENSION
GO
/****** Object:  StoredProcedure [dbo].[get_PG_OverWorkedHours]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_PG_OverWorkedHours]
(	@DATE DATETIME,
	@HOURS INT=110)
AS
--DECLARE @DATE DATETIME='2018-05-01'
--DECLARE @HOURS INT = 110

  --EXEC dbo.get_PG_OverWorkedHours '2018-05-01'
    --SELECT * FROM dbo.Fact_OverWorkedHours

DELETE FROM dbo.Fact_OverWorkedHours WHERE PeriodStart>=@DATE

INSERT INTO dbo.Fact_OverWorkedHours
SELECT [EmployeeCode]
	  ,P.PeriodStart
	  ,P.PeriodEnd
	  ,UPPER(LEFT(DATENAME(MONTH,P.PeriodStart),3))+'-'+LTRIM(STR(YEAR(P.PeriodStart))) [PayStartDate]
	  ,UPPER(LEFT(DATENAME(MONTH,P.PeriodEnd),3))+'-'+LTRIM(STR(YEAR(P.PeriodEnd))) [PayEndDate]
	  ,SUM(T.[OrdHours]+T.[OvertimeHours]) TotalHours
	--INTO dbo.Fact_OverWorkedHours
  FROM [DDB460-18\I460_01].[PayGlobal].[dbo].[TransCurrentMaster] T INNER JOIN [DDB460-18\I460_01].[PayGlobal].[dbo].TransPerPaySequence P
  ON T.PaySequence=P.PaySequence
  WHERE GLExport=1 AND PeriodStart>=@DATE--'102554' EmployeeCode=@EMP AND
  GROUP BY [EmployeeCode]
	  ,P.PeriodStart
	  ,P.PeriodEnd
  HAVING SUM(T.[OrdHours]+T.[OvertimeHours]) > @HOURS
  ORDER BY 2 DESC




GO
/****** Object:  StoredProcedure [dbo].[get_PG_Trans]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[get_PG_Trans] 
AS
-- delete any 30 or less days old and re-process

DECLARE @DATE DATE
SELECT @DATE=DATEADD(DAY, -31, GETDATE())

DELETE FROM dbo.SOURCE_PG_Trans WHERE  Date>@DATE

INSERT INTO dbo.SOURCE_PG_Trans
SELECT     HA.EmployeeCode,  HA.PaySequence, HA.StartDate, HA.Date, HA.AllowanceCode
			,  HA.RateAmount, HA.Factor, HA.TotalAmount, HA.FTEHours, HA.Quantity  
				--, HA.CostCentreCode,  C.Description AS CostCentreDesc, C.GeneralLedgerCode, C.GeneralLedgerDesc
				, [dbo].[fn_GetDelimitedValue] (C.GeneralLedgerCode, 1) Company
				, [dbo].[fn_GetDelimitedValue] (C.GeneralLedgerCode, 2) Facility
				, [dbo].[fn_GetDelimitedValue] (C.GeneralLedgerCode, 3) Account
				, [dbo].[fn_GetDelimitedValue] (C.GeneralLedgerCode, 4) Commodity
				, [dbo].[fn_GetDelimitedValue] (C.GeneralLedgerCode, 5) Analysis
				, C.LocationCode,  HA.PositionCode
--INTO dbo.SOURCE_PG_Trans
FROM          [DDB460-18\I460_01].PayGlobal.dbo.HistoricalAllowance AS HA LEFT OUTER JOIN
						[DDB460-18\I460_01].PayGlobal.dbo.CostCentre AS C ON HA.CostCentreCode = C.CostCentreCode 
						--LEFT OUTER JOIN
						--[DDB460-18\I460_01].PayGlobal.dbo.Location AS L ON L.LocationCode = C.LocationCode INNER JOIN
						--[DDB460-18\I460_01].PayGlobal.dbo.Employee AS E ON E.EmployeeCode = HA.EmployeeCode INNER JOIN
						--[DDB460-18\I460_01].PayGlobal.dbo.Allowance AS A ON HA.AllowanceCode = A.AllowanceCode LEFT OUTER JOIN
						--[DDB460-18\I460_01].PayGlobal.dbo.Position AS P ON P.PositionCode = HA.PositionCode INNER JOIN
						--[DDB460-18\I460_01].PayGlobal.dbo.TransPerPaySequence AS S ON HA.PaySequence=S.PaySequence
WHERE     HA.Date>@DATE AND C.LocationCode IS NOT NULL

-- delete any records beyond 31 days from today
SELECT @DATE=DATEADD(DAY, 31, GETDATE())

DELETE FROM dbo.SOURCE_PG_Trans WHERE  Date>@DATE

--SELECT * FROM dbo.SOURCE_PG_Trans


GO
/****** Object:  StoredProcedure [dbo].[get_PL]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[get_PL] (
@Report_Start_Date DATETIME,
@Report_End_Date DATETIME)

AS 


--declare @Report_Start_Date datetime='2018-01-01'
--declare @Report_End_Date datetime='2018-03-01'

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

select
	'A'									as Record_Type
	, ledgertrans.dimension as Facility_Code
	--, facility.description as Facility_Desc
	, LEDGERTRANS.DataAreaID Company
	--,pl_accounts.group_code
	,pl_accounts.account_description
	--,pl_accounts.ordering
	
	,convert(datetime, convert(varchar(4), year(isnull(LEDGERTRANS.TRANSDATE, #Dates#.calandar_date)))
			+ '/' + CONVERT(varchar(2), month(isnull(LEDGERTRANS.transdate, #Dates#.calandar_date)))
			+ '/01', 111)				as Trans_Month

	,isnull(sum(case
		when pl_accounts.group_code = 11 then LEDGERTRANS.qty
		when pl_accounts.reverse_sign = 1 then LEDGERTRANS.AMOUNTMST * -1
		else LEDGERTRANS.AMOUNTMST
		end),0) as Amount

from 
	dbo.PL_Accounts 
	
	inner join #Dates#
		on 1=1

	--left outer join [DDB460-01\I460_01].PeoplePoint_Live.dbo.DIMENSIONS facility
	--	on  facility.dimensioncode = 0
	--	and facility.DATAAREAID = 'VIRT'


	left outer join [DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERTRANS
		on  LEDGERTRANS.accountnum = pl_accounts.account_code
		and ledgertrans.dimension3_ = ISNULL(pl_Accounts.Analysis_Code, ledgertrans.dimension3_)
		and ledgertrans.dimension2_ = ISNULL(pl_Accounts.Commodity_Code, ledgertrans.dimension2_)
		and LEDGERTRANS.TRANSDATE >= @Report_Start_Date
		and LEDGERTRANS.TRANSDATE < @Report_End_Date
		and ledgertrans.posting <> 19
		and ledgertrans.operationstax = 0
		--and LEDGERTRANS.DIMENSION = facility.NUM
		and #Dates#.calandar_date = convert(datetime, convert(varchar(4), year(LEDGERTRANS.TRANSDATE))
										+ '/' + CONVERT(varchar(2), month(LEDGERTRANS.transdate))
										+ '/01', 111)
WHERE LEDGERTRANS.DataAreaID IS NOT NULL			
group by
	ledgertrans.dimension 
	--, facility.description 
	, LEDGERTRANS.DataAreaID
	,pl_accounts.group_code
	,pl_accounts.account_description
	,pl_accounts.ordering
	,convert(datetime, convert(varchar(4), year(isnull(LEDGERTRANS.TRANSDATE, #Dates#.Calandar_date)))
			+ '/' + CONVERT(varchar(2), month(isnull(LEDGERTRANS.transdate,#Dates#.calandar_date)))
			+ '/01', 111)
--order by 1,2,3,4,5,6,7

-- budget figures 
UNION

select
	'B'									as Record_Type
	, LEDGERBUDGET.dimension as Facility_Code
	--, facility.description as Facility_Desc
	, ledgerbudget.DataAreaID Company
	--,pl_accounts.group_code
	,pl_accounts.account_description
	--,pl_accounts.ordering

	,convert(datetime, convert(varchar(4), year(LEDGERBUDGET.STARTDATE))
			+ '/' + CONVERT(varchar(2), month(LEDGERBUDGET.STARTDATE))
			+ '/01', 111)				as Trans_Month
			
	,sum(case
		when ledgertable.accountcategoryref = 53 and pl_accounts.reverse_sign = 1 then ledgerbudget.qty * -1
		when ledgertable.accountcategoryref = 53 then ledgerbudget.qty
		when pl_accounts.reverse_sign = 1 then ledgerbudget.amount * -1
		else ledgerbudget.amount
		end)			as Budget_Amount


from 
	[DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERBUDGET
	--inner join [DDB460-01\I460_01].PeoplePoint_Live.dbo.DIMENSIONS facility
	--	on  ledgerbudget.DIMENSION = facility.NUM
	--	and facility.DATAAREAID = 'virt'
	--	and facility.DIMENSIONCODE = 0

	inner join dbo.pl_accounts
		on  ledgerbudget.accountnum = pl_accounts.account_code
		and LEDGERBUDGET.dimension3_ = ISNULL(pl_Accounts.analysis_code, LEDGERBudget.dimension3_)
		and LEDGERBUDGET.dimension2_ = ISNULL(pl_Accounts.Commodity_Code, LEDGERBudget.dimension2_)
	
	inner join [DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERTABLE
		on  LEDGERBUDGET.ACCOUNTNUM = ledgertable.ACCOUNTNUM
		and LEDGERTABLE.DATAAREAID = 'VIRT'

where 
	LEDGERBUDGET.STARTDATE >= @Report_Start_Date
	and LEDGERBUDGET.STARTDATE < @Report_End_Date


group by
	ledgerbudget.dimension 
	--, facility.description 
	, LEDGERBUDGET.DataAreaID
	,pl_accounts.group_code
	,pl_accounts.account_description
	,pl_accounts.ordering

	,convert(datetime, convert(varchar(4), year(LEDGERBUDGET.STARTDATE))
			+ '/' + CONVERT(varchar(2), month(LEDGERBUDGET.STARTDATE))
			+ '/01', 111)

DROP TABLE #Dates#




GO
/****** Object:  StoredProcedure [dbo].[get_PP_Occupancy]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[get_PP_Occupancy]
	--@DATE DATETIME
as

DECLARE @DATE DATE=GETDATE()
DECLARE @SD DATETIME=@DATE
DECLARE @ED DATETIME=@DATE
DECLARE @FACILITY NVARCHAR(50)=null--'360'
-- exec [dbo].[rpt_OC_055_Occupancy1] '2017-03-01', '2017-03-31', '700'


-- Get Data
-- get residents during period
--C25030, C25060, C22400 Need to use Distinct to remove any duplication
SELECT DISTINCT CUSTACCOUNT, ENTRYDATE, CASE WHEN ENTRYDATE<@SD THEN @SD ELSE ENTRYDATE END SD
, DEPARTUREDATE, BILLINGCEASEDATE, CASE WHEN BILLINGCEASEDATE='1900-01-01 00:00:00.000' AND DEPARTUREDATE='1900-01-01 00:00:00.000' THEN @ED
						WHEN BILLINGCEASEDATE='1900-01-01 00:00:00.000' AND DEPARTUREDATE<=@ED THEN DATEADD(D, -1, DEPARTUREDATE)
						WHEN BILLINGCEASEDATE<>'1900-01-01 00:00:00.000' AND DEPARTUREDATE<>'1900-01-01 00:00:00.000' AND BILLINGCEASEDATE>=DEPARTUREDATE AND DEPARTUREDATE<=@ED THEN DATEADD(D, -1, BILLINGCEASEDATE)
						ELSE @ED END ED
, DATEDIFF(D, CASE WHEN ENTRYDATE<@SD THEN @SD ELSE ENTRYDATE END, 
		CASE WHEN BILLINGCEASEDATE='1900-01-01 00:00:00.000' AND DEPARTUREDATE='1900-01-01 00:00:00.000' THEN @ED
						WHEN BILLINGCEASEDATE='1900-01-01 00:00:00.000' AND DEPARTUREDATE<=@ED THEN DATEADD(D, -1, DEPARTUREDATE)
						WHEN BILLINGCEASEDATE<>'1900-01-01 00:00:00.000' AND DEPARTUREDATE<>'1900-01-01 00:00:00.000' AND BILLINGCEASEDATE>=DEPARTUREDATE AND DEPARTUREDATE<=@ED THEN DATEADD(D, -1, BILLINGCEASEDATE)
						ELSE @ED END)+1 [DAYS]
--CASE DEPARTUREDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE DEPARTUREDATE END ED
, FACILITYID, DIMENSION --'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' FacilityName
, RESIDENTTYPEID,  ACCOMMODATIONID, ACCOMMODATIONHISTORYID
--, DATEDIFF(D, CASE WHEN ENTRYDATE<@SD THEN @SD ELSE ENTRYDATE END, CASE WHEN (CASE DEPARTUREDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE DEPARTUREDATE END)>=@ED THEN @ED ELSE DEPARTUREDATE END)+1 DAYS
, 'XXXXXXXXX' [R_TYPE], 999999.99 [REV_FAC], 999999.99 [REV_CUS],  99999.99 [REV_CUS1], 'XXXXXXXXXXXX' [ACCT_FAC], 'XXXXXXXXXX' [ACCT_CUS], 'XXXXXXXXXXXX' [ACCT_CUS1]
, 99999 [DAYS_FAC],  99999 [DAYS_CUS],  99999 [DAYS_CUS1], 999999.99 [REV]
INTO #RESIDENTS
FROM [DDB460-01\I460_01].[PeoplePoint_Live].dbo.ECL_ACMACCOMMODATIONHISTORY 
WHERE DATAAREAID='VIRT'
AND ENTRYDATE<=@ED AND CASE DEPARTUREDATE WHEN '1900-01-01 00:00:00.000'  THEN @ED ELSE DEPARTUREDATE END >=@SD --BETWEEN @SD AND @ED
AND DEPARTUREDATE<>ENTRYDATE AND DIMENSION=ISNULL(@FACILITY, DIMENSION)
ORDER BY CUSTACCOUNT

-- Get facility charge
SELECT S.FEEID, F.LEDGERACCOUNT, L.ACCOUNTNAME, S.DIMENSION, FACILITYID, RESIDENTTYPEID, STARTDATE, ENDDATE, S.FEEAMOUNT
, T.TAXCODE, T.TAXVALUE, F.FEEUNIT,  CASE F.FEEUNIT WHEN 2 THEN ((S.FEEAMOUNT/7)/((100+T.TAXVALUE)/100)) WHEN 4 THEN (((S.FEEAMOUNT*12)/365)/((100+T.TAXVALUE)/100)) ELSE ((S.FEEAMOUNT)/((100+T.TAXVALUE)/100)) END Daily_Rate
,CASE WHEN STARTDATE<@SD THEN @SD ELSE STARTDATE END SD
, CASE WHEN (CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE ENDDATE END) >= @ED THEN @ED ELSE ENDDATE END ED
, DATEDIFF(D, CASE WHEN STARTDATE<@SD THEN @SD ELSE STARTDATE END, CASE WHEN (CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE ENDDATE END) >= @ED THEN @ED ELSE ENDDATE END)+1 [DAYS]
INTO #REV_Facility
FROM   [DDB460-01\I460_01].PeoplePoint_Live.dbo.ECL_ACMFEESETUP AS S
INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.ECL_ACMFEE AS F ON  F.FEEID = S.FEEID AND F.DATAAREAID = S.DATAAREAID
INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERTABLE AS L ON  L.DATAAREAID = F.DATAAREAID AND L.ACCOUNTNUM = F.LEDGERACCOUNT 
INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.TAXDATA T ON F.TAXGROUP = T.TAXCODE AND T.DATAAREAID = F.DATAAREAID AND T.DATAAREAID='virt'
WHERE F.DATAAREAID='virt' AND LEN(CUSTACCOUNT)=0 AND STARTDATE<=@ED AND CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE ENDDATE END>=@SD 
AND LEN(CUSTACCOUNT)=0 AND LEN(RESIDENTTYPEID)>0 AND LEN(S.DIMENSION)>0
AND LEN(ACCOMMODATIONTYPEID)=0 AND CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN STARTDATE ELSE ENDDATE END >=STARTDATE
--AND DIMENSION=@FACILITY
ORDER BY DIMENSION, FEEID

-- get charge for residents individual
SELECT S.FEEID, F.LEDGERACCOUNT, L.ACCOUNTNAME, S.DIMENSION, FACILITYID, RESIDENTTYPEID, STARTDATE, ENDDATE, S.FEEAMOUNT, CUSTACCOUNT, ACCOMMODATIONHISTORYID 
, T.TAXCODE, T.TAXVALUE, F.FEEUNIT,  CASE F.FEEUNIT WHEN 2 THEN ((S.FEEAMOUNT/7)/((100+T.TAXVALUE)/100)) WHEN 4 THEN (((S.FEEAMOUNT*12)/365)/((100+T.TAXVALUE)/100)) ELSE ((S.FEEAMOUNT)/((100+T.TAXVALUE)/100)) END Daily_Rate
, CASE WHEN STARTDATE<@SD THEN @SD ELSE STARTDATE END SD
, CASE WHEN (CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE ENDDATE END) >= @ED THEN @ED ELSE ENDDATE END ED
, DATEDIFF(D, CASE WHEN STARTDATE<@SD THEN @SD ELSE STARTDATE END, CASE WHEN (CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE ENDDATE END) >= @ED THEN @ED ELSE ENDDATE END)+1 [DAYS]
INTO #REV_CUST
FROM   [DDB460-01\I460_01].PeoplePoint_Live.dbo.ECL_ACMFEESETUP AS S
INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.ECL_ACMFEE AS F ON  F.FEEID = S.FEEID AND F.DATAAREAID = S.DATAAREAID
INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.LEDGERTABLE AS L ON  L.DATAAREAID = F.DATAAREAID AND L.ACCOUNTNUM = F.LEDGERACCOUNT
INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.TAXDATA T ON F.TAXGROUP = T.TAXCODE AND T.DATAAREAID = F.DATAAREAID AND T.DATAAREAID='virt'
WHERE LEN(CUSTACCOUNT)<>0 AND STARTDATE<=@ED AND CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN @ED ELSE ENDDATE END>=@SD
AND CASE ENDDATE WHEN '1900-01-01 00:00:00.000' THEN STARTDATE ELSE ENDDATE END >=STARTDATE
--AND DIMENSION=@FACILITY
ORDER BY CUSTACCOUNT

-- UPDATE for the total revenue by facility charges (applies to long term REST, HOS, DEM care only)
UPDATE R SET R.DAYS_FAC=ISNULL(G.F_DAYS,0), R.[ACCT_FAC]=ISNULL(G.LEDGERACCOUNT,'XXXX'), R.[REV_FAC]=ISNULL(G.F_REVNUES,0)  	
FROM #RESIDENTS R LEFT OUTER JOIN (
-- update with total facility charge (need total as price could change during the query period)
	SELECT CUSTACCOUNT, R.ACCOMMODATIONHISTORYID, R.DAYS R_DAYS, F.FEEID, F.LEDGERACCOUNT, F.ACCOUNTNAME,SUM(F.DAYS) F_DAYS, SUM(F.Daily_Rate*F.DAYS) F_REVNUES
	FROM #RESIDENTS R LEFT OUTER JOIN #REV_Facility F ON R.FACILITYID=F.FACILITYID AND R.RESIDENTTYPEID=F.RESIDENTTYPEID
	GROUP BY CUSTACCOUNT, R.ACCOMMODATIONHISTORYID, R.DAYS, F.FEEID, F.LEDGERACCOUNT, F.ACCOUNTNAME) G
ON R.CUSTACCOUNT=G.CUSTACCOUNT AND R.ACCOMMODATIONHISTORYID=G.ACCOMMODATIONHISTORYID

-- update for the total revenues for Rest, Dem and Hos cares
UPDATE R SET R.DAYS_CUS=ISNULL(G.C_DAYS,0), R.[ACCT_CUS]=ISNULL(G.ACCOUNTNAME,'XXXX'), R.[REV_CUS]=ISNULL(G.C_REVNUES,0)  	
FROM #RESIDENTS R LEFT OUTER JOIN (
	SELECT CUSTACCOUNT, MIN(LEDGERACCOUNT) ACCOUNTNAME, SUM(DAYS) C_DAYS, SUM(Daily_Rate*DAYS) C_REVNUES
	FROM #REV_CUST WHERE LEDGERACCOUNT IN ('1105', '1110', '1115', '1135', '1130', '1125') GROUP BY CUSTACCOUNT) G 
	ON R.CUSTACCOUNT=G.CUSTACCOUNT

-- update for the total revenues for OTHER NOT Rest, Dem and Hos cares
UPDATE R SET R.DAYS_CUS1=ISNULL(G.C_DAYS,0), R.[ACCT_CUS1]=ISNULL(G.ACCOUNTNAME,'XXXX'), R.[REV_CUS1]=ISNULL(G.C_REVNUES,0)  	
FROM #RESIDENTS R LEFT OUTER JOIN (
	SELECT CUSTACCOUNT, MIN(LEDGERACCOUNT) ACCOUNTNAME, SUM(DAYS) C_DAYS, SUM(Daily_Rate*DAYS) C_REVNUES
	FROM #REV_CUST WHERE LEDGERACCOUNT NOT IN ('1105', '1110', '1115', '1135', '1130', '1125') GROUP BY CUSTACCOUNT) G 
	ON R.CUSTACCOUNT=G.CUSTACCOUNT


-- UDPATE TOTAL INCOMES
UPDATE R SET REV=REV_FAC+REV_CUS+REV_CUS1 FROM #RESIDENTS R

-- UPDATE FACILITY NAME
--UPDATE R SET FacilityName=[dbo].[fn_GetDimensionName](DIMENSION, 0) FROM #RESIDENTS R
--INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.DIMENSIONS D WHERE D


-- UPDATE TYPE
UPDATE R SET R_TYPE=
	CASE WHEN ACCT_FAC='1105' THEN 'REST'
		WHEN ACCT_FAC='1110' THEN 'HOS'
		WHEN ACCT_FAC='1115' THEN 'DEM'
		WHEN RESIDENTTYPEID='ILU' AND ACCT_FAC='XXXX' THEN 'ILU'
		WHEN ACCT_CUS='1105' THEN 'REST'
		WHEN ACCT_CUS='1110' THEN 'HOS'
		WHEN ACCT_CUS='1115' THEN 'DEM'
		WHEN ACCT_CUS='1130' AND REV<=150 THEN 'REST'
		WHEN ACCT_CUS='1130' AND REV>150 THEN 'HOS'
		WHEN ACCT_CUS='1135' AND REV<=150 THEN 'REST'
		WHEN ACCT_CUS='1135' AND REV>150 THEN 'HOS'
		WHEN ACCT_CUS='1125' AND REV<=150 THEN 'REST'
		WHEN ACCT_CUS='1125' AND REV>150 THEN 'HOS'
		WHEN REV=0 AND ACCT_CUS+ACCT_CUS1+ACCT_FAC='XXXXXXXXXXXX' THEN 'NRS'
		ELSE 'OTH' END
 FROM #RESIDENTS R

INSERT INTO Fact_Daily_Occupancy1
SELECT R.CUSTACCOUNT, @SD RECORD_DATE, R.ENTRYDATE, R.SD, R.DEPARTUREDATE, R.BILLINGCEASEDATE, R.ED, R.DAYS, CAST(R.DAYS AS numeric(5,2))/(DATEDIFF(DAY, @SD, @ED)+1) DAYS1, R.FACILITYID
, R.DIMENSION, R.RESIDENTTYPEID, R.ACCOMMODATIONID, R.ACCOMMODATIONHISTORYID, R.R_TYPE, R.REV_FAC
, R.REV_CUS, R.REV_CUS1, R.ACCT_FAC, R.ACCT_CUS, R.ACCT_CUS1, R.DAYS_FAC, R.DAYS_CUS, R.DAYS_CUS1
, R.REV, D.DESCRIPTION FacilityName, C.NAME ResidentName, C.ECL_ACMLASTNAME LastName, C.CreatedDatetime + GETDATE() - GETUTCDATE() CreatedDateTime, C.CreatedBy
 FROM #RESIDENTS R INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.DIMENSIONS D 
ON R.DIMENSION=D.NUM AND  D.DIMENSIONCODE = 0 AND D.DATAAREAID = 'virt'
INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.CUSTTABLE C ON R.CUSTACCOUNT=C.ACCOUNTNUM AND C.DATAAREAID = 'virt'
--INNER JOIN [DDB460-01\I460_01].PeoplePoint_Live.dbo.ECL_ACMACCOMMODATIONHISTORY A ON R.ACCOMMODATIONHISTORYID=A.ACCOMMODATIONHISTORYID
--SELECT * FROM #REV_Facility
--SELECT * FROM #REV_CUST

INSERT INTO Fact_Daily_Occupancy
SELECT R.CUSTACCOUNT, R.SD RECORD_DATE, R.FACILITYID, R.DIMENSION, R.RESIDENTTYPEID, R.ACCOMMODATIONHISTORYID, R.ACCOMMODATIONID, 
F.FEEID, F.LEDGERACCOUNT, F.ACCOUNTNAME, F.TAXVALUE, ISNULL(F.Daily_Rate*F.DAYS,0) DAILY_EXGST
FROM #RESIDENTS R INNER JOIN #REV_Facility F ON R.FACILITYID=F.FACILITYID AND R.RESIDENTTYPEID=F.RESIDENTTYPEID

INSERT INTO Fact_Daily_Occupancy
SELECT R.CUSTACCOUNT, R.SD RECORD_DATE, R.FACILITYID, R.DIMENSION, R.RESIDENTTYPEID, R.ACCOMMODATIONHISTORYID, R.ACCOMMODATIONID, 
F.FEEID, F.LEDGERACCOUNT, F.ACCOUNTNAME, F.TAXVALUE, ISNULL(F.Daily_Rate*F.DAYS,0) DAILY_EXGST
FROM #RESIDENTS R INNER JOIN #REV_CUST F ON R.CUSTACCOUNT=F.CUSTACCOUNT


DROP TABLE #RESIDENTS
DROP TABLE #REV_Facility
DROP TABLE #REV_CUST


--SELECT * FROM dbo.Fact_Daily_Occupancy

--TRUNCATE TABLE  dbo.Fact_Daily_Occupancy1






GO
/****** Object:  StoredProcedure [dbo].[get_TT_Sum]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[get_TT_Sum]

as 

DELETE 			FROM dbo.SOURCE_TT_Timesheet_SUM
	WHERE  Date BETWEEN DATEADD(DAY, -36, GETDATE()) AND DATEADD(DAY, -1, GETDATE())  

INSERT	INTO dbo.SOURCE_TT_Timesheet_SUM
SELECT LEFT(ExportCode,3) DIMENSION, PayDate [Date],  SUM(TotalCost) NET_Costs,
		CAST(SUM(NetMins) AS decimal(10,2))/60 Net_Hrs,
		ROUND(SUM(CASE ShiftType WHEN 'ANNUALLEAVE' THEN TotalCost*1.08 ELSE TotalCost*1.116 END),2) TOT_Costs
		FROM [DDB460-18\I460_19].[TimeTarget].[dbo].[Timesheet] T INNER JOIN 
		[DDB460-18\I460_19].[TimeTarget].[dbo].[Employee] E ON T.Employee=E.UID
	INNER JOIN [DDB460-18\I460_19].[TimeTarget].[dbo].[Location] L ON T.LocationID=L.LocationId
	WHERE  PayDate BETWEEN DATEADD(DAY, -36, GETDATE()) AND DATEADD(DAY, -1, GETDATE())  AND Authorised=1 
	AND Deleted=0 AND SUBSTRING(ExportCode, 4, 1)='C'--AND ExportCode='240C'
	GROUP BY ExportCode, PayDate--, CASE ShiftType WHEN 'ANNUALLEAVE' THEN 'AL' ELSE 'ORD' END
	ORDER BY 1,2
GO
/****** Object:  StoredProcedure [dbo].[TravelRequest_Status_Update]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TravelRequest_Status_Update] (
 @ID INT,
 @Status NVARCHAR(20)
 --,@Note NVARCHAR(MAX) OUTPUT
 )

 AS
--DECLARE @ID INT
-- EXEC dbo.TravelRequest_Status_Update 49, 'Submitted'

UPDATE [dbo].[TravelRequest] SET RequestStatus=@Status, EditedOn=GETDATE() WHERE ID=@ID

IF @Status='Submitted'
BEGIN
	DECLARE @Note NVARCHAR(MAX)=''
	SELECT @Note=@Note + 'Request ID ' + LTRIM(STR(ID)) + '; Organised by ' + EditedBy + ' on ' + CONVERT(VARCHAR, EditedOn,103) + '; ' +CHAR(13) + CHAR(10)+CHAR(13) + CHAR(10)
		+ 'Traveller Passport Name: ' + EmployeeName + '; Email: ' +  EmployeeEmail + '; Phone: ' + EmployeePhone + '; ' +CHAR(13) + CHAR(10)
		+ 'Approver: ' + ApprovalEmail + '; Travel Reason: ' + TravelReason + '; Account Code: ' + Company + Facility + CHAR(13) + CHAR(10)
		--+ '; Request Status: ' + RequestStatus + '; ' 
		+ 'Note for Request: ' +  ISNULL(TravelNote,'') + '; ' +CHAR(13) + CHAR(10)+CHAR(13) + CHAR(10)
	   FROM [DW_OCEANIA].[dbo].[TravelRequest] WHERE ID=@ID

	SELECT @Note=@Note + ItineraryType + ':' +CHAR(13) + CHAR(10) + CityDeparture + ' to ' + CityArrival 
	+ '; Departure on ' + DepartureOn +  '; Arrive on: ' + ArrivalOn + '; ' +CHAR(13) + CHAR(10)
	+ Luggage + '; Note: ' + ISNULL(ItinararyNote, '') + '; ' +CHAR(13) + CHAR(10) +CHAR(13) + CHAR(10)   
	FROM [DW_OCEANIA].[dbo].[TravelRequest_Itinerary] WHERE TravelRequestID=@ID

	INSERT INTO dbo.TravelRequest_EmailNote 
	Values (@ID, @Note)
END
--RETURN(@Note)




GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetAge]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Zhou
-- Create date: 2015-03-30
-- Description:	calculate age from DOB
-- =============================================
CREATE FUNCTION [dbo].[fn_GetAge] 
(
	@DOB DATETIME,
	@DATE DATETIME 
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @AGE INT
	
	
	SELECT @AGE=CASE WHEN @DOB='1900-01-01' THEN 0 ELSE
				CASE WHEN MONTH(@DATE)>MONTH(@DOB) THEN DATEDIFF(YEAR,@DOB,@DATE)
					WHEN MONTH(@DATE)<MONTH(@DOB) THEN DATEDIFF(YEAR,@DOB,@DATE)-1
					WHEN MONTH(@DATE)=MONTH(@DOB) THEN 
						CASE WHEN DAY(@DATE)>=DAY(@DOB) THEN DATEDIFF(YEAR,@DOB,@DATE) 
							 WHEN DAY(@DATE)<DAY(@DOB) THEN DATEDIFF(YEAR,@DOB,@DATE)-1
						END
				END
			END

	RETURN @AGE
	

END

--SELECT  [dbo].[fn_GetAge]('1935-03-31', GETDATE())

GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetAgeAsToday]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Peter Zhou
-- Create date: 2015-03-30
-- Description:	get age as of today from DOB
-- =============================================
CREATE FUNCTION [dbo].[fn_GetAgeAsToday] 
(
	@DOB DATETIME 
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @AGE INT
	
	
	SELECT @AGE=CASE WHEN @DOB='1900-01-01' THEN 0 ELSE
				CASE WHEN MONTH(GETDATE())>MONTH(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE())
					WHEN MONTH(GETDATE())<MONTH(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE())-1
					WHEN MONTH(GETDATE())=MONTH(@DOB) THEN 
						CASE WHEN DAY(GETDATE())>=DAY(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE()) 
							 WHEN DAY(GETDATE())<DAY(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE())-1
						END
				END
			END

	RETURN @AGE
	

END

--SELECT  [dbo].[fn_GetAgeAsToday]('1935-03-31')

GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetAgeBucketAsToday]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Peter Zhou
-- Create date: 2015-03-30
-- Description:	get age as of today from DOB
-- =============================================
CREATE FUNCTION [dbo].[fn_GetAgeBucketAsToday] 
(
	@DOB DATETIME 
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @AGE INT
	DECLARE @AGE_BUCKET INT
	
	
	SELECT @AGE=CASE WHEN @DOB='1900-01-01' THEN 0 ELSE
				CASE WHEN MONTH(GETDATE())>MONTH(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE())
					WHEN MONTH(GETDATE())<MONTH(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE())-1
					WHEN MONTH(GETDATE())=MONTH(@DOB) THEN 
						CASE WHEN DAY(GETDATE())>=DAY(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE()) 
							 WHEN DAY(GETDATE())<DAY(@DOB) THEN DATEDIFF(YEAR,@DOB,GETDATE())-1
						END
				END
			END

	SELECT @AGE_BUCKET=AgeBucket FROM dbo.AgeBucket WHERE @AGE BETWEEN AgeMin AND AgeMax

	RETURN @AGE_BUCKET
	

END

--SELECT  [dbo].[fn_GetAgeBucketAsToday]('1935-03-31')


GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetDelimiedValue]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Peter Zhou
-- Create date: 2016-09-27
-- Description:	get string from a delimited string
-- =============================================
CREATE FUNCTION [dbo].[fn_GetDelimiedValue] 
(
	@STRING NVARCHAR(50),
	@N INT 
)
RETURNS NVARCHAR(50)
AS
BEGIN

DECLARE @VALUE NVARCHAR(50)
SELECT @VALUE=Category FROM dbo.MultiValueParamSplitWithOrder(@STRING,',') WHERE Row_Counter=@N
RETURN @VALUE
--	-- Declare the return variable here
----DECLARE @STRING NVARCHAR(50)='C1,290,2105,,050'
----DECLARE @N INT=2
--		DECLARE @COUNTER INT=1
--		DECLARE @START INT=1
--		DECLARE @POSITION INT=1
--		--DECLARE @ANSWER INT
--		WHILE @COUNTER<=@N
--		BEGIN
--			SELECT @POSITION=CHARINDEX(',', @STRING,@POSITION)+1
--			SET @COUNTER=@COUNTER+1
--		END

--		RETURN @POSITION

END

--SELECT  [dbo].[fn_GetDelimiedValue] ('C1,290,2105,,050', 3)


GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetDelimitedValue]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Peter Zhou
-- Create date: 2016-09-27
-- Description:	get string from a delimited string
-- =============================================
CREATE FUNCTION [dbo].[fn_GetDelimitedValue] 
(
	@STRING NVARCHAR(50),
	@N INT 
)
RETURNS NVARCHAR(50)
AS
BEGIN

DECLARE @VALUE NVARCHAR(50)
SELECT @VALUE=Category FROM dbo.MultiValueParamSplitWithOrder(@STRING,',') WHERE Row_Counter=@N
RETURN CASE LEN(@VALUE) WHEN 0 THEN 'NA' ELSE @VALUE END
--	-- Declare the return variable here
----DECLARE @STRING NVARCHAR(50)='C1,290,2105,,050'
----DECLARE @N INT=2
--		DECLARE @COUNTER INT=1
--		DECLARE @START INT=1
--		DECLARE @POSITION INT=1
--		--DECLARE @ANSWER INT
--		WHILE @COUNTER<=@N
--		BEGIN
--			SELECT @POSITION=CHARINDEX(',', @STRING,@POSITION)+1
--			SET @COUNTER=@COUNTER+1
--		END

--		RETURN @POSITION

END

--SELECT  [dbo].[fn_GetDelimitedValue] ('C1,290,2105,,050', 4)


GO
/****** Object:  UserDefinedFunction [dbo].[MultiValueParamSplitWithOrder]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function [dbo].[MultiValueParamSplitWithOrder](
@InputCategories Varchar(3000),
@Delimiter Varchar(2))
--Returns Table Variable which holds the multiple Categories
--pass from our SSRS
RETURNS @Categories TABLE (Row_Counter Int, Category Varchar(3000))

AS

BEGIN
DECLARE
@CategoryPos Int, -- Find first Character/Letter of each Category 
@CategoryEnd Int, -- Find last Character/Letter of each Category
@CategoryTextLength Int, -- Find Length of each Category (i.e., "Accessories" has 11 Characters) 
@DelimiterLength Int, -- Find Length of the Delimiter, in our case a comma (,).
@Row_Counter Int


SET @CategoryTextLength = DataLength(@InputCategories)

IF @CategoryTextLength = 0 RETURN -- Exit Function if No Category Input is detected. You always want to have something in there.

SET @CategoryPos = 1
SET @DelimiterLength = DataLength(@Delimiter)
SET @Row_Counter=1

IF @DelimiterLength = 0 BEGIN

WHILE @CategoryPos <= @CategoryTextLength BEGIN

INSERT @Categories (Row_Counter, Category) VALUES (@Row_Counter, SubString(@InputCategories,@CategoryPos,1))
SET @Row_Counter=@Row_Counter+1
SET @CategoryPos = @CategoryPos + 1
END
END

ELSE BEGIN
SET @InputCategories = @InputCategories + @Delimiter
SET @CategoryEnd = CharIndex(@Delimiter, @InputCategories)

WHILE @CategoryEnd > 0 BEGIN

INSERT @Categories (Row_Counter, Category) VALUES (@Row_Counter, SubString(@InputCategories, @CategoryPos, @CategoryEnd- @CategoryPos))
SET @Row_Counter=@Row_Counter+1

SET @CategoryPos = @CategoryEnd + @DelimiterLength

SET @CategoryEnd = CharIndex(@Delimiter, @InputCategories, @CategoryPos)

END

END

RETURN

END

GO
/****** Object:  Table [dbo].[AgeBucket]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgeBucket](
	[AgeBucket] [int] NOT NULL,
	[AgeBucketDescrption] [nvarchar](100) NOT NULL,
	[AgeMin] [int] NOT NULL,
	[AgeMax] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CONTRACTS]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CONTRACTS](
	[ContractID] [int] IDENTITY(1,1) NOT NULL,
	[Dimension] [nvarchar](20) NULL,
	[Contract_No] [nvarchar](50) NULL,
	[Addendum_No] [nvarchar](20) NULL,
	[Commencing_Date] [date] NULL,
	[Expiry_Date] [date] NULL,
	[Resident_Type] [nvarchar](50) NULL,
	[PU_ID] [nvarchar](50) NULL,
	[Fee_Excl_GST] [float] NULL,
	[GST_Rate] [float] NULL,
	[Billing_Details] [nvarchar](255) NULL,
	[Content_Invoice] [nvarchar](max) NULL,
	[Excluded_Services] [nvarchar](max) NULL,
	[Note] [nvarchar](max) NULL,
	[Type] [nvarchar](10) NULL,
	[Email] [nvarchar](50) NULL,
	[Contract_Type] [nvarchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[ContractID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Courses]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Courses](
	[ID] [bigint] NULL,
	[Course Name] [nvarchar](50) NULL,
	[Intake Name] [nvarchar](100) NULL,
	[StartDate] [datetime] NULL,
	[coinEndDate] [datetime] NULL,
	[Quota] [float] NULL,
	[Booked] [float] NULL,
	[Trainers] [nvarchar](255) NULL,
	[Providers] [nvarchar](255) NULL,
	[Location] [nvarchar](255) NULL,
	[Venue] [nvarchar](255) NULL,
	[Event Start Time] [datetime] NULL,
	[Event End Time] [datetime] NULL,
	[F14] [nvarchar](255) NULL,
	[F15] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DayCare_Cust]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DayCare_Cust](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[NHI] [nvarchar](50) NOT NULL,
	[Name_First] [nvarchar](100) NOT NULL,
	[Name_Last] [nvarchar](100) NOT NULL,
	[DOB] [datetime] NOT NULL,
	[Gender] [nvarchar](1) NULL,
	[Note] [nvarchar](255) NULL,
	[Photo] [image] NULL,
	[LastModifiedOn] [datetime] NOT NULL,
	[LastModifiedBy] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK__DayCare___3214EC272FDF6468] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__DayCare___C7DEDB1C5520E622] UNIQUE NONCLUSTERED 
(
	[NHI] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DayCare_Tran]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DayCare_Tran](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Cust_ID] [int] NOT NULL,
	[Date] [datetime] NOT NULL,
	[Time_Start] [time](7) NOT NULL,
	[Time_End] [time](7) NOT NULL,
	[Units] [decimal](5, 2) NOT NULL,
	[Facility] [nvarchar](10) NOT NULL,
	[PU_ID] [nvarchar](20) NOT NULL,
	[CareLevel] [nvarchar](20) NOT NULL,
	[Status] [nvarchar](50) NOT NULL,
	[Note] [nvarchar](255) NULL,
	[LastModifiedOn] [datetime] NOT NULL,
	[LastModifiedBy] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK__DayCare___3214EC2737D3C353] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DayCare_User]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DayCare_User](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[LogonUser] [nvarchar](100) NOT NULL,
	[Facility] [nvarchar](10) NOT NULL,
	[UserType] [nvarchar](20) NOT NULL,
	[LastModifedBy] [nvarchar](100) NOT NULL,
	[LastModifiedOn] [datetime] NOT NULL,
	[Note] [nvarchar](255) NULL,
 CONSTRAINT [PK__DayCare___3214EC27D546A831] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_UserFacility] UNIQUE NONCLUSTERED 
(
	[LogonUser] ASC,
	[Facility] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DayCare_UserType]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DayCare_UserType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserType] [nvarchar](20) NOT NULL,
	[Note] [nvarchar](255) NULL,
 CONSTRAINT [PK__DayCare___3214EC2782F2A448] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_UserType] UNIQUE NONCLUSTERED 
(
	[UserType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Dim_Dates]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Dim_Dates](
	[Date_Id] [int] NOT NULL,
	[Calendar_Date] [datetime] NOT NULL,
	[Calendar_Year] [smallint] NOT NULL,
	[Calendar_Month] [tinyint] NOT NULL,
	[Calendar_Month_Short] [varchar](3) NOT NULL,
	[Calendar_Month_Long] [varchar](20) NOT NULL,
	[Calendar_Day] [tinyint] NOT NULL,
	[Calendar_Day_Short] [varchar](4) NOT NULL,
	[Calendar_Day_Long] [varchar](20) NOT NULL,
	[Calendar_Day_of_Week] [tinyint] NOT NULL,
	[Financial_Month] [tinyint] NOT NULL,
	[Financial_Year] [int] NULL,
	[Daylight_Saving_Time] [bit] NOT NULL,
	[UTC_Offset] [tinyint] NOT NULL,
	[Is_Last_Day_Of_Month] [bit] NOT NULL,
	[Last_Day_Of_Month] [datetime] NOT NULL,
	[No_Days_In_Month] [smallint] NOT NULL,
	[First_Day_Of_Month] [datetime] NOT NULL,
	[Week_Number] [int] NULL,
	[Week_Start_Date] [datetime] NULL,
	[Week_End_Date] [datetime] NULL,
	[Current_Month_Start_Date] [datetime] NULL,
	[Current_Month_End_Date] [datetime] NULL,
	[Last_Month_Start_Date] [datetime] NULL,
	[Last_Month_End_Date] [datetime] NULL,
	[Last_12_Months_Start_Date] [datetime] NULL,
	[Last_12_Months_End_Date] [datetime] NULL,
	[Last_12_Full_Months_Start_Date] [datetime] NULL,
	[Last_12_Full_Months_End_Date] [datetime] NULL,
	[Financial_Year_Start_Date] [datetime] NULL,
	[Financial_Year_End_Date] [datetime] NULL,
	[Last_6_Months_Start_Date] [datetime] NULL,
	[Last_6_Months_End_Date] [datetime] NULL,
	[Last_6_Full_Months_Start_Date] [datetime] NULL,
	[Last_6_Full_Months_End_Date] [datetime] NULL,
	[Days_in_Month] [smallint] NULL,
	[Period_Number] [int] NULL,
	[Period] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Dim_Facility_ManualPay]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dim_Facility_ManualPay](
	[NUM] [nchar](20) NULL,
	[Facility Name] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Dim_Reasons_ManualPay]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dim_Reasons_ManualPay](
	[NUM] [int] NULL,
	[Reason] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Dim_Vendors]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Dim_Vendors](
	[ACCOUNTNUM] [nvarchar](50) NOT NULL,
	[NAME] [nvarchar](60) NOT NULL,
	[VENDGROUP] [nvarchar](20) NOT NULL,
	[PAYMTERMID] [nvarchar](20) NOT NULL,
	[BLOCKED] [varchar](7) NOT NULL,
	[COUNTRYREGIONID] [nvarchar](20) NOT NULL,
	[PAYMMODE] [nvarchar](20) NOT NULL,
	[BANKACCOUNT] [nvarchar](10) NOT NULL,
	[ZIPCODE] [nvarchar](10) NOT NULL,
	[TAXGROUP] [nvarchar](20) NOT NULL,
	[PREFERED] [varchar](3) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Dim_VisaType]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Dim_VisaType](
	[WorkPermit] [varchar](20) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DW_Employee_MasterXXX]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DW_Employee_MasterXXX](
	[EmployeeCode] [varchar](12) NULL,
	[Gender] [varchar](6) NOT NULL,
	[BirthDate] [datetime] NOT NULL,
	[Age] [int] NULL,
	[City] [varchar](30) NOT NULL,
	[PositionCode] [varchar](12) NULL,
	[LocationCode] [varchar](12) NULL,
	[DepartmentCode] [varchar](12) NULL,
	[PayPeriodCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[BusinessArea] [varchar](12) NULL,
	[Region] [varchar](12) NULL,
	[Area] [varchar](12) NULL,
	[HolidayGroupCode] [varchar](12) NOT NULL,
	[ContractCode] [varchar](12) NULL,
	[EmployeeStatusCode] [varchar](12) NOT NULL,
	[UnionCode] [varchar](12) NOT NULL,
	[Salary] [numeric](11, 2) NOT NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[StartDate] [datetime] NULL,
	[HireYear] [int] NULL,
	[HireMonth] [int] NULL,
	[BadHire] [varchar](1) NOT NULL,
	[TerminationDate] [datetime] NOT NULL,
	[TerminationYear] [int] NULL,
	[TerminationMonth] [int] NULL,
	[Terminated] [varchar](1) NOT NULL,
	[TermReasonCode] [varchar](12) NOT NULL,
	[ParentLvStartDate] [datetime] NOT NULL,
	[ParentLvEndDate] [datetime] NOT NULL,
	[PayType] [varchar](8) NULL,
	[PayMethod] [varchar](13) NULL,
	[TaxCode] [varchar](7) NULL,
	[StudentDebt] [varchar](7) NOT NULL,
	[ALGross] [numeric](11, 2) NOT NULL,
	[ALGrossAccrued] [numeric](11, 2) NOT NULL,
	[ALPaidAdvance] [numeric](11, 2) NOT NULL,
	[ALOutstandLiable] [numeric](11, 2) NULL,
	[ALLiability] [numeric](11, 2) NULL,
	[ALOutstandRate] [numeric](11, 4) NULL,
	[ALAccruedRate] [numeric](11, 4) NULL,
	[ALOutstand] [numeric](11, 2) NULL,
	[ALAccrued] [numeric](11, 4) NOT NULL,
	[ALTotalUnits] [numeric](11, 4) NULL,
	[SLTotalUnits] [numeric](11, 4) NULL,
	[SLLiability] [numeric](11, 2) NULL,
	[SLOutstandRate] [numeric](11, 4) NULL,
	[SLOutstand] [numeric](11, 4) NOT NULL,
	[SLAccrued] [numeric](11, 4) NOT NULL,
	[X52WKAVG] [numeric](12, 4) NOT NULL,
	[X4WKREL] [numeric](12, 4) NOT NULL,
	[XELOCATION] [varchar](30) NOT NULL,
	[XEAVGHRS] [numeric](11, 2) NULL,
	[AvgWorkedHoursPerWeek] [numeric](11, 4) NOT NULL,
	[Record_Date] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Facility_MedCall]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Facility_MedCall](
	[Company] [nvarchar](20) NOT NULL,
	[Facility] [nvarchar](50) NOT NULL,
	[entity_name] [nvarchar](200) NULL,
	[branch] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FacilityMap]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FacilityMap](
	[Facility No ] [varchar](50) NULL,
	[Facility Type] [varchar](50) NULL,
	[Facility Name] [varchar](50) NULL,
	[DHB] [varchar](50) NULL,
	[Region] [varchar](50) NULL,
	[Street name] [varchar](50) NULL,
	[Postcode] [varchar](50) NULL,
	[City] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Fact_CPACK]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fact_CPACK](
	[DIMENSION] [nvarchar](20) NOT NULL,
	[Date] [date] NULL,
	[Total_CPACK] [numeric](38, 10) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Fact_Daily_Occupancy]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fact_Daily_Occupancy](
	[CUSTACCOUNT] [nvarchar](50) NOT NULL,
	[RECORD_DATE] [datetime] NULL,
	[FACILITYID] [nvarchar](20) NOT NULL,
	[DIMENSION] [nvarchar](20) NOT NULL,
	[RESIDENTTYPEID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONHISTORYID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONID] [nvarchar](20) NOT NULL,
	[FEEID] [nvarchar](10) NOT NULL,
	[LEDGERACCOUNT] [nvarchar](50) NOT NULL,
	[ACCOUNTNAME] [nvarchar](60) NOT NULL,
	[TAXVALUE] [numeric](28, 12) NOT NULL,
	[DAILY_EXGST] [numeric](38, 6) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Fact_Daily_Occupancy1]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Fact_Daily_Occupancy1](
	[CUSTACCOUNT] [nvarchar](50) NOT NULL,
	[RECORD_DATE] [datetime] NULL,
	[ENTRYDATE] [datetime] NOT NULL,
	[SD] [datetime] NULL,
	[DEPARTUREDATE] [datetime] NOT NULL,
	[BILLINGCEASEDATE] [datetime] NOT NULL,
	[ED] [datetime] NULL,
	[DAYS] [int] NULL,
	[DAYS1] [numeric](16, 13) NULL,
	[FACILITYID] [nvarchar](20) NOT NULL,
	[DIMENSION] [nvarchar](20) NOT NULL,
	[RESIDENTTYPEID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONHISTORYID] [nvarchar](20) NOT NULL,
	[R_TYPE] [varchar](9) NOT NULL,
	[REV_FAC] [numeric](8, 2) NOT NULL,
	[REV_CUS] [numeric](8, 2) NOT NULL,
	[REV_CUS1] [numeric](7, 2) NOT NULL,
	[ACCT_FAC] [varchar](12) NOT NULL,
	[ACCT_CUS] [varchar](10) NOT NULL,
	[ACCT_CUS1] [varchar](12) NOT NULL,
	[DAYS_FAC] [int] NOT NULL,
	[DAYS_CUS] [int] NOT NULL,
	[DAYS_CUS1] [int] NOT NULL,
	[REV] [numeric](8, 2) NOT NULL,
	[FacilityName] [nvarchar](60) NOT NULL,
	[ResidentName] [nvarchar](60) NOT NULL,
	[LastName] [nvarchar](20) NOT NULL,
	[CreatedDateTime] [datetime] NULL,
	[CreatedBy] [nvarchar](5) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Fact_HATB]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fact_HATB](
	[ACCOUNTNUM] [nvarchar](50) NOT NULL,
	[DIMENSION] [nvarchar](20) NULL,
	[RVREGIONID] [nvarchar](10) NULL,
	[FACILITY] [nvarchar](20) NULL,
	[ARCHIVED] [int] NULL,
	[PAYMMODE] [nvarchar](20) NULL,
	[CREDITRATING] [nvarchar](10) NULL,
	[Resident_Type] [nvarchar](20) NULL,
	[DOB] [datetime] NULL,
	[Age] [int] NULL,
	[Entry_Date] [datetime] NULL,
	[Departure_Date] [datetime] NULL,
	[Daily_Rate] [numeric](12, 5) NULL,
	[Outstanding_Private] [numeric](38, 12) NOT NULL,
	[PVT_AGEING_0] [numeric](38, 12) NOT NULL,
	[PVT_AGEING_1] [numeric](38, 12) NOT NULL,
	[PVT_AGEING_2] [numeric](38, 12) NOT NULL,
	[PVT_AGEING_3] [numeric](38, 12) NOT NULL,
	[PVT_AGEING_4] [numeric](38, 12) NOT NULL,
	[Outstanding_MOH] [numeric](38, 12) NOT NULL,
	[MOH_AGEING_0] [numeric](38, 12) NOT NULL,
	[MOH_AGEING_1] [numeric](38, 12) NOT NULL,
	[MOH_AGEING_2] [numeric](38, 12) NOT NULL,
	[MOH_AGEING_3] [numeric](38, 12) NOT NULL,
	[MOH_AGEING_4] [numeric](38, 12) NOT NULL,
	[Outstanding_WINZ] [numeric](38, 12) NOT NULL,
	[WINZ_AGEING_0] [numeric](38, 12) NOT NULL,
	[WINZ_AGEING_1] [numeric](38, 12) NOT NULL,
	[WINZ_AGEING_2] [numeric](38, 12) NOT NULL,
	[WINZ_AGEING_3] [numeric](38, 12) NOT NULL,
	[WINZ_AGEING_4] [numeric](38, 12) NOT NULL,
	[Outstanding_ACC] [numeric](38, 12) NOT NULL,
	[ACC_AGEING_0] [numeric](38, 12) NOT NULL,
	[ACC_AGEING_1] [numeric](38, 12) NOT NULL,
	[ACC_AGEING_2] [numeric](38, 12) NOT NULL,
	[ACC_AGEING_3] [numeric](38, 12) NOT NULL,
	[ACC_AGEING_4] [numeric](38, 12) NOT NULL,
	[Total_Balance] [numeric](38, 12) NOT NULL,
	[Record_Date] [date] NOT NULL,
	[DHB] [nvarchar](50) NULL,
	[CUSTGROUP] [nvarchar](20) NULL,
	[LAST_PVT_PAYMENT_DATE] [datetime] NOT NULL,
	[PVT_LAST_PMT] [numeric](12, 5) NOT NULL,
	[PVT_LAST_PAYMODE] [nvarchar](20) NOT NULL,
	[MOH_LAST_PMT_DATE] [datetime] NOT NULL,
	[MOH_LAST_PMT] [numeric](12, 5) NOT NULL,
	[Daily_PAC] [numeric](12, 5) NOT NULL,
	[Daily_Total_Subsidy] [numeric](12, 5) NOT NULL,
	[PVT_Licence] [numeric](38, 12) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Fact_ManualPay]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fact_ManualPay](
	[Date Submitted] [datetime] NULL,
	[Submitted By] [nvarchar](255) NULL,
	[Name of Requester] [nvarchar](255) NULL,
	[Facility Name] [nvarchar](255) NULL,
	[Employee Name] [nvarchar](255) NULL,
	[Employee Number] [int] NULL,
	[Estimated cost of Manual Pay] [nvarchar](255) NULL,
	[Pay Period error occured] [nvarchar](255) NULL,
	[Reason for Manual Pay] [nvarchar](255) NULL,
	[If reason is Other please specify] [nvarchar](255) NULL,
	[Details of Manual Pay] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Fact_OverWorkedHours]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Fact_OverWorkedHours](
	[EmployeeCode] [varchar](12) NULL,
	[PeriodStart] [datetime] NULL,
	[PeriodEnd] [datetime] NULL,
	[PayStartDate] [nvarchar](14) NULL,
	[PayEndDate] [nvarchar](14) NULL,
	[TotalHours] [numeric](38, 2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Fact_VendorSpending]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fact_VendorSpending](
	[Company_Code] [nvarchar](4) NOT NULL,
	[Facility_Code] [nvarchar](20) NOT NULL,
	[Vendor_Code] [nvarchar](50) NOT NULL,
	[documentdate] [datetime] NULL,
	[transdate] [datetime] NOT NULL,
	[amountmst] [numeric](28, 12) NULL,
	[Allocated_to_account] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FactResident_Balances1]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FactResident_Balances1](
	[ACCOUNTNUM] [nvarchar](50) NOT NULL,
	[Cust_RECID] [bigint] NOT NULL,
	[NAME] [nvarchar](60) NULL,
	[DIMENSION] [nvarchar](20) NULL,
	[RVREGIONID] [nvarchar](10) NULL,
	[FACILITY] [nvarchar](20) NULL,
	[ACCOMMODATIONID] [nvarchar](20) NULL,
	[ACCOMMODATIONTYPEID] [nvarchar](20) NULL,
	[ARCHIVED] [int] NULL,
	[PAYMMODE] [nvarchar](20) NULL,
	[CREDITRATING] [nvarchar](10) NULL,
	[Resident_Type] [nvarchar](20) NULL,
	[DOB] [datetime] NULL,
	[Age] [int] NULL,
	[NHI] [nvarchar](15) NULL,
	[Entry_Date] [datetime] NULL,
	[Departure_Date] [datetime] NULL,
	[BILLINGCEASEDATE] [datetime] NULL,
	[ACCOMMODATIONHISTORYID] [nvarchar](20) NULL,
	[Daily_Rate] [numeric](12, 5) NULL,
	[Daily_Subsidy_Text] [varchar](200) NULL,
	[Daily_Subsidy_MOH] [numeric](12, 5) NULL,
	[Daily_Subsidy_WINZ] [numeric](12, 5) NULL,
	[Outstanding_Private] [numeric](38, 12) NULL,
	[PVT_AGEING_0] [numeric](38, 12) NULL,
	[PVT_AGEING_1] [numeric](38, 12) NULL,
	[PVT_AGEING_2] [numeric](38, 12) NULL,
	[PVT_AGEING_3] [numeric](38, 12) NULL,
	[PVT_AGEING_4] [numeric](38, 12) NULL,
	[Outstanding_MOH] [numeric](38, 12) NULL,
	[MOH_AGEING_0] [numeric](38, 12) NULL,
	[MOH_AGEING_1] [numeric](38, 12) NULL,
	[MOH_AGEING_2] [numeric](38, 12) NULL,
	[MOH_AGEING_3] [numeric](38, 12) NULL,
	[MOH_AGEING_4] [numeric](38, 12) NULL,
	[Outstanding_WINZ] [numeric](38, 12) NULL,
	[WINZ_AGEING_0] [numeric](38, 12) NULL,
	[WINZ_AGEING_1] [numeric](38, 12) NULL,
	[WINZ_AGEING_2] [numeric](38, 12) NULL,
	[WINZ_AGEING_3] [numeric](38, 12) NULL,
	[WINZ_AGEING_4] [numeric](38, 12) NULL,
	[Outstanding_ACC] [numeric](38, 12) NULL,
	[ACC_AGEING_0] [numeric](38, 12) NULL,
	[ACC_AGEING_1] [numeric](38, 12) NULL,
	[ACC_AGEING_2] [numeric](38, 12) NULL,
	[ACC_AGEING_3] [numeric](38, 12) NULL,
	[ACC_AGEING_4] [numeric](38, 12) NULL,
	[Total_Balance] [numeric](38, 12) NULL,
	[NOTE] [nvarchar](max) NULL,
	[Record_Date] [date] NOT NULL,
	[Date_RUN] [date] NOT NULL,
	[DHB] [nvarchar](50) NULL,
	[CUSTGROUP] [nvarchar](20) NULL,
	[LAST_PVT_PAYMENT_DATE] [datetime] NULL,
	[PVT_LAST_PMT] [numeric](12, 5) NULL,
	[PVT_LAST_PAYMODE] [nvarchar](20) NULL,
	[MOH_LAST_PMT_DATE] [datetime] NULL,
	[MOH_LAST_PMT] [numeric](12, 5) NULL,
	[Balance_Type] [smallint] NULL,
	[Daily_Total_Fee_Text] [nvarchar](200) NULL,
	[Daily_PAC] [numeric](12, 5) NULL,
	[Daily_Total_Subsidy] [numeric](12, 5) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Images]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Images](
	[ImageID] [int] IDENTITY(1,1) NOT NULL,
	[ImageName] [nvarchar](50) NOT NULL,
	[ImageFile] [image] NOT NULL,
	[ProgramID] [nvarchar](50) NOT NULL,
	[ImageDesc] [nvarchar](250) NULL,
PRIMARY KEY NONCLUSTERED 
(
	[ImageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LeavingType]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeavingType](
	[LeavingID] [nvarchar](20) NOT NULL,
	[LeavingType] [nvarchar](20) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Medcall]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Medcall](
	[hospital_name] [nvarchar](50) NULL,
	[Facility] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[shift_type] [nvarchar](50) NULL,
	[split_shift_ind] [nvarchar](50) NULL,
	[start_time] [nvarchar](50) NULL,
	[end_time] [nvarchar](50) NULL,
	[nurse_name] [nvarchar](50) NULL,
	[nurse_type] [nvarchar](50) NULL,
	[department] [nvarchar](50) NULL,
	[allowance_type] [nvarchar](50) NULL,
	[Hours] [float] NULL,
	[charge_rate] [float] NULL,
	[Sales_GST_excl] [float] NULL,
	[invoice_date] [datetime] NULL,
	[invoice_number] [nvarchar](50) NULL,
	[our_reference] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MovementType]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MovementType](
	[MovementType] [tinyint] NULL,
	[MovementDescription] [nvarchar](20) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PG_Employee_Rate_Changes]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PG_Employee_Rate_Changes](
	[EmployeeCode] [varchar](12) NULL,
	[EffectStartDate] [datetime] NULL,
	[EffectEndDate] [datetime] NOT NULL,
	[Level] [varchar](20) NULL,
	[RateAmount] [numeric](11, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PG_Employee_Rates]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PG_Employee_Rates](
	[EmployeeCode] [varchar](12) NULL,
	[Date] [datetime] NULL,
	[Level] [varchar](20) NULL,
	[RateAmount] [numeric](11, 4) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PL_Account_Hierarchy]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PL_Account_Hierarchy](
	[Account_Description] [nvarchar](300) NULL,
	[Group_Code] [smallint] NULL,
	[Ordering] [int] NULL,
	[Group_Description] [nvarchar](50) NOT NULL,
	[Top_Group_Code] [int] NULL,
	[Top_Group_Code_DESC] [nvarchar](50) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PL_Accounts]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PL_Accounts](
	[Account_Description] [varchar](300) NULL,
	[Account_Details] [varchar](300) NULL,
	[Account_Code] [varchar](100) NULL,
	[Commodity_Code] [varchar](10) NULL,
	[Analysis_Code] [varchar](10) NULL,
	[Group_Code] [smallint] NULL,
	[Reverse_Sign] [bit] NULL,
	[Ordering] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PL_Trans]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PL_Trans](
	[Record_Type] [varchar](1) NOT NULL,
	[Facility_Code] [nvarchar](20) NOT NULL,
	[Company] [nvarchar](4) NOT NULL,
	[account_description] [nvarchar](300) NOT NULL,
	[Trans_Month] [datetime] NOT NULL,
	[Amount] [numeric](18, 2) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ResidentType]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResidentType](
	[ResidentType] [nvarchar](20) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ResidentType1]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResidentType1](
	[RESIDENTTYPEID] [nvarchar](20) NULL,
	[NewResidentType] [nvarchar](20) NULL,
	[LongTerm] [bit] NULL,
	[Aged] [bit] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_AccommodationHistory]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_AccommodationHistory](
	[FACILITYID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONID] [nvarchar](20) NOT NULL,
	[ENTRYDATE] [datetime] NOT NULL,
	[DEPARTUREDATE] [datetime] NOT NULL,
	[CUSTACCOUNT] [nvarchar](50) NOT NULL,
	[ACTIVE] [int] NOT NULL,
	[PREADMITDATE] [datetime] NOT NULL,
	[REASONFORLEAVINGID] [nvarchar](20) NOT NULL,
	[STATUSCODEID_DEL] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONHISTORYID] [nvarchar](20) NOT NULL,
	[BEDID] [nvarchar](20) NOT NULL,
	[VACANCYDATE] [datetime] NOT NULL,
	[RESIDENTTYPEID] [nvarchar](20) NOT NULL,
	[PENSIONERSTATUS_DEL] [int] NOT NULL,
	[RESIDENTBONDSID] [nvarchar](20) NOT NULL,
	[GOVERNMENTSUBSIDYTYPEID] [nvarchar](10) NOT NULL,
	[INITIALADMISSION] [int] NOT NULL,
	[DIMENSION] [nvarchar](20) NOT NULL,
	[DIMENSION2_] [nvarchar](20) NOT NULL,
	[DIMENSION3_] [nvarchar](20) NOT NULL,
	[APPLICATIONID] [nvarchar](20) NOT NULL,
	[MOVEMENTTYPE] [int] NOT NULL,
	[CATEGORYCODE] [nvarchar](10) NOT NULL,
	[CUSTGROUPID] [nvarchar](20) NOT NULL,
	[EXCLUDEFROMPROPOSALS] [int] NOT NULL,
	[ECL_DEPARTUREDATEOF] [datetime] NOT NULL,
	[ECL_FACILITYNAMEOF] [nvarchar](50) NOT NULL,
	[ISDEATHCERTIFICATEONFILE] [int] NOT NULL,
	[PPTCSCONTRACTTYPEID] [nvarchar](20) NOT NULL,
	[PPTCSCAREPLANVERSIONID] [nvarchar](20) NOT NULL,
	[PPTCSCASEMANAGERDIARY] [nvarchar](20) NOT NULL,
	[PPTCSEXPECTEDDEPARTUREDATE] [datetime] NOT NULL,
	[PPTCSINTERNALFUNDINGTYPE] [int] NOT NULL,
	[PPTCSINTERNALFUNDINGID] [nvarchar](50) NOT NULL,
	[PPTCSREVIEWDATE] [datetime] NOT NULL,
	[PPTCSREFERRALDATE] [datetime] NOT NULL,
	[BILLPREENTRY] [int] NOT NULL,
	[PPTCSSERVICESTARTDATE] [datetime] NOT NULL,
	[PPTCSHOSPITALADMISSIONDATE] [datetime] NOT NULL,
	[PPTCSENTRYBARTELSCORE] [numeric](28, 12) NOT NULL,
	[PPTCSEXITBARTELSCORE] [numeric](28, 12) NOT NULL,
	[PPTCSMBIEXITSCORE] [numeric](28, 12) NOT NULL,
	[PPTCSMBIENTRYSCORE] [numeric](28, 12) NOT NULL,
	[PPTCSDAYSSPENTINRESSETTING] [numeric](28, 12) NOT NULL,
	[PPTCSNOTES] [ntext] NULL,
	[PPTCSOUTDIDNOTCOMMENCE] [int] NOT NULL,
	[PPTCSOUTSHORTTERMONLY] [int] NOT NULL,
	[PPTCSOUTPRIVATEORCARER] [int] NOT NULL,
	[PPTCSSEWHACC] [int] NOT NULL,
	[PPTCSSEWCACP] [int] NOT NULL,
	[PPTCSSEWDVA] [int] NOT NULL,
	[PPTCSSEWCOPS] [int] NOT NULL,
	[PPTCSSEWHEALTH] [int] NOT NULL,
	[PPTCSSEWOTHER] [int] NOT NULL,
	[PPTCSSEWRACF] [int] NOT NULL,
	[PPTCSSEWDIED] [int] NOT NULL,
	[PPTCSDECHACC] [int] NOT NULL,
	[PPTCSDECCACP] [int] NOT NULL,
	[PPTCSDECDVA] [int] NOT NULL,
	[PPTCSDECCOPS] [int] NOT NULL,
	[PPTCSDECHEALTH] [int] NOT NULL,
	[PPTCSDECOTHER] [int] NOT NULL,
	[PPTCSWAITHACC] [int] NOT NULL,
	[PPTCSWAITCACP] [int] NOT NULL,
	[PPTCSWAITDVA] [int] NOT NULL,
	[PPTCSWAITCOPS] [int] NOT NULL,
	[PPTCSWAITHEALTH] [int] NOT NULL,
	[PPTCSWAITOTHER] [int] NOT NULL,
	[PPTCSHOSMEDICALREASON] [int] NOT NULL,
	[PPTCSHOSCCREASON] [int] NOT NULL,
	[PPTCSHOSOTHER] [int] NOT NULL,
	[PPTCSEXTRADIEDBEFOREDISCHARGE] [int] NOT NULL,
	[PPTCSEXTRADISCHARGENURSINGHOME] [int] NOT NULL,
	[PPTCSEXTRAREFERREDCOMPACKS] [int] NOT NULL,
	[PPTCSEXTRADECLINEDREFERRA20073] [int] NOT NULL,
	[PPTCSEXTRADONTKNOW] [int] NOT NULL,
	[PPTCSHACCFUNDINGSOURCE] [int] NOT NULL,
	[PPTCSSERVICEDELIVERYSETTING] [int] NOT NULL,
	[PPTCSPROGRAMID] [nvarchar](50) NOT NULL,
	[PPTCSPROJGROUPID] [nvarchar](10) NOT NULL,
	[ACCOMMODATIONTYPEID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONSTYLEID] [nvarchar](20) NOT NULL,
	[SALESTATUS] [int] NOT NULL,
	[PHASEID] [nvarchar](10) NOT NULL,
	[SALESPERSON] [nvarchar](20) NOT NULL,
	[PPTRVDATEKEYSRETURNED] [datetime] NOT NULL,
	[PPTRVDATENOTICETOVACATE] [datetime] NOT NULL,
	[PPTCSLIVEARRANGEMENTID] [nvarchar](20) NOT NULL,
	[ENQUIRYTYPE] [int] NOT NULL,
	[BILLPREENTRYFROMDATE] [datetime] NOT NULL,
	[MODIFIEDDATETIME] [datetime] NOT NULL,
	[CREATEDDATETIME] [datetime] NOT NULL,
	[DATAAREAID] [nvarchar](4) NOT NULL,
	[RECVERSION] [int] NOT NULL,
	[RECID] [bigint] NOT NULL,
	[BILLTODATE] [datetime] NOT NULL,
	[CONSENTTOMOVEOBTAINED] [int] NOT NULL,
	[PPTRVUNITCLEARED] [int] NOT NULL,
	[PPTRVUNITCLEANED] [int] NOT NULL,
	[PPTRVCONDITIONAUDITREPORT] [int] NOT NULL,
	[PPTRVKEYSRETURNED] [int] NOT NULL,
	[PPTRVVACANTPOSSESSIONDATE] [datetime] NOT NULL,
	[PARTNERED] [int] NOT NULL,
	[CUSTACCOUNTPARTNER] [nvarchar](50) NOT NULL,
	[PPTCSMAXHOURS] [numeric](28, 12) NOT NULL,
	[PPTCSHOURSFREQUENCY] [int] NOT NULL,
	[PPTRVBONDLODGEMENTNO] [nvarchar](15) NOT NULL,
	[SUBSIDYSTATUS] [int] NOT NULL,
	[OFFSETCOMPANY] [nvarchar](4) NOT NULL,
	[COMPANY] [nvarchar](4) NOT NULL,
	[INTERCODIMENSION] [nvarchar](20) NOT NULL,
	[INTERCODIMENSION2_] [nvarchar](20) NOT NULL,
	[INTERCODIMENSION3_] [nvarchar](20) NOT NULL,
	[DMFCEASEDATE] [datetime] NOT NULL,
	[SUBSIDYCEASEDATE] [datetime] NOT NULL,
	[BILLINGCEASEDATE] [datetime] NOT NULL,
	[SETTLEMENTDATE] [datetime] NOT NULL,
	[PPTARRIVED] [int] NOT NULL,
	[TRANSFERDATE] [datetime] NOT NULL,
	[OVERRIDESTDPROPOSALS] [int] NOT NULL,
	[TERMNOTIFYDATE] [datetime] NOT NULL,
	[ESTDEPARTUREDATE] [datetime] NOT NULL,
	[LICEXPIRYDATE] [datetime] NOT NULL,
	[RESIDENTTRANSFERDATE] [datetime] NOT NULL,
	[PPTALSREBATERESIDENT] [int] NOT NULL,
	[PPTCHECKLISTID] [nvarchar](20) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_Company]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_Company](
	[NAME] [nvarchar](60) NOT NULL,
	[ADDRESS] [nvarchar](250) NOT NULL,
	[PHONE] [nvarchar](20) NOT NULL,
	[TELEFAX] [nvarchar](20) NOT NULL,
	[BANK] [nvarchar](10) NOT NULL,
	[GIRO] [nvarchar](34) NOT NULL,
	[REGNUM] [nvarchar](15) NOT NULL,
	[COREGNUM] [nvarchar](15) NOT NULL,
	[VATNUM] [nvarchar](20) NOT NULL,
	[CURRENCYCODE] [nvarchar](3) NOT NULL,
	[IMPORTVATNUM] [nvarchar](20) NOT NULL,
	[ZIPCODE] [nvarchar](10) NOT NULL,
	[STATE] [nvarchar](20) NOT NULL,
	[COUNTY] [nvarchar](32) NOT NULL,
	[COUNTRYREGIONID] [nvarchar](20) NOT NULL,
	[TELEX] [nvarchar](20) NOT NULL,
	[URL] [nvarchar](255) NOT NULL,
	[EMAIL] [nvarchar](80) NOT NULL,
	[CELLULARPHONE] [nvarchar](20) NOT NULL,
	[PHONELOCAL] [nvarchar](10) NOT NULL,
	[UPSNUM] [nvarchar](20) NOT NULL,
	[NAMECONTROL] [nvarchar](4) NOT NULL,
	[EUROCURRENCYCODE] [nvarchar](3) NOT NULL,
	[KEY_] [int] NOT NULL,
	[SECONDARYCURRENCYCODE] [nvarchar](3) NOT NULL,
	[DVRID] [nvarchar](20) NOT NULL,
	[LANGUAGEID] [nvarchar](7) NOT NULL,
	[INTRASTATCODE] [nvarchar](10) NOT NULL,
	[GIROCONTRACT] [nvarchar](10) NOT NULL,
	[GIROCONTRACTACCOUNT] [nvarchar](11) NOT NULL,
	[BRANCHID] [nvarchar](10) NOT NULL,
	[VATNUMBRANCHID] [nvarchar](10) NOT NULL,
	[IMPORTVATNUMBRANCHID] [nvarchar](10) NOT NULL,
	[ACTIVITYCODE] [nvarchar](9) NOT NULL,
	[STREET] [nvarchar](250) NOT NULL,
	[CITY] [nvarchar](60) NOT NULL,
	[CONVERSIONDATE] [datetime] NOT NULL,
	[PAGER] [nvarchar](20) NOT NULL,
	[SMS] [nvarchar](80) NOT NULL,
	[ADDRFORMAT] [nvarchar](20) NOT NULL,
	[PACKMATERIALFEELICENSENUM] [nvarchar](20) NOT NULL,
	[BANKCENTRALBANKPURPOSECODE] [nvarchar](10) NOT NULL,
	[BANKCENTRALBANKPURPOSETEXT] [nvarchar](140) NOT NULL,
	[SHIPPINGCALENDARID] [nvarchar](10) NOT NULL,
	[PLANNINGCOMPANY] [int] NOT NULL,
	[TAXREPRESENTATIVE] [nvarchar](45) NOT NULL,
	[FALLBACKINVENTLOCATIONID] [nvarchar](20) NOT NULL,
	[BANKACCTUSEDFOR1099] [nvarchar](10) NOT NULL,
	[ECL_COMPANYCOLOR] [int] NOT NULL,
	[ECL_ACMPRIVACYINFORMATION] [ntext] NULL,
	[MODIFIEDDATETIME] [datetime] NOT NULL,
	[DEL_MODIFIEDTIME] [int] NOT NULL,
	[MODIFIEDBY] [nvarchar](5) NOT NULL,
	[DATAAREAID] [nvarchar](4) NOT NULL,
	[RECVERSION] [int] NOT NULL,
	[RECID] [bigint] NOT NULL,
	[SOFTWAREIDENTIFICATIONCODE_CA] [nvarchar](8) NOT NULL,
	[PPTCOUNTRYSPECIFICLOGIC] [int] NOT NULL,
	[PPTAUTOLANGUAGEPREF] [int] NOT NULL,
	[PPTRESIDENTSTATEMENT] [nvarchar](1500) NOT NULL,
	[PPTAPEFTREMITTANCE] [nvarchar](1500) NOT NULL,
	[PPTRESIDENTCREDITBLNTEXT] [nvarchar](1500) NOT NULL,
	[PPTNONDDRESIDENTTEXT] [nvarchar](1500) NOT NULL,
	[PPTDDRESIDENTTEXT] [nvarchar](1500) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_Customer]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_Customer](
	[ACCOUNTNUM] [nvarchar](50) NOT NULL,
	[NAME] [nvarchar](60) NOT NULL,
	[ADDRESS] [nvarchar](250) NOT NULL,
	[PHONE] [nvarchar](20) NOT NULL,
	[TELEFAX] [nvarchar](20) NOT NULL,
	[INVOICEACCOUNT] [nvarchar](50) NOT NULL,
	[CUSTGROUP] [nvarchar](20) NOT NULL,
	[LINEDISC] [nvarchar](20) NOT NULL,
	[PAYMTERMID] [nvarchar](20) NOT NULL,
	[CASHDISC] [nvarchar](20) NOT NULL,
	[CURRENCY] [nvarchar](3) NOT NULL,
	[SALESGROUP] [nvarchar](20) NOT NULL,
	[BLOCKED] [int] NOT NULL,
	[ONETIMECUSTOMER] [int] NOT NULL,
	[ACCOUNTSTATEMENT] [int] NOT NULL,
	[CREDITMAX] [numeric](28, 12) NOT NULL,
	[MANDATORYCREDITLIMIT] [int] NOT NULL,
	[DIMENSION] [nvarchar](20) NOT NULL,
	[DIMENSION2_] [nvarchar](20) NOT NULL,
	[DIMENSION3_] [nvarchar](20) NOT NULL,
	[VENDACCOUNT] [nvarchar](50) NOT NULL,
	[TELEX] [nvarchar](20) NOT NULL,
	[PRICEGROUP] [nvarchar](20) NOT NULL,
	[MULTILINEDISC] [nvarchar](20) NOT NULL,
	[ENDDISC] [nvarchar](20) NOT NULL,
	[VATNUM] [nvarchar](20) NOT NULL,
	[COUNTRYREGIONID] [nvarchar](20) NOT NULL,
	[INVENTLOCATION] [nvarchar](20) NOT NULL,
	[DLVTERM] [nvarchar](20) NOT NULL,
	[DLVMODE] [nvarchar](20) NOT NULL,
	[MARKUPGROUP] [nvarchar](20) NOT NULL,
	[CLEARINGPERIOD] [nvarchar](20) NOT NULL,
	[ZIPCODE] [nvarchar](10) NOT NULL,
	[STATE] [nvarchar](20) NOT NULL,
	[COUNTY] [nvarchar](32) NOT NULL,
	[URL] [nvarchar](255) NOT NULL,
	[EMAIL] [nvarchar](80) NOT NULL,
	[CELLULARPHONE] [nvarchar](20) NOT NULL,
	[PHONELOCAL] [nvarchar](10) NOT NULL,
	[FREIGHTZONE] [nvarchar](20) NOT NULL,
	[CREDITRATING] [nvarchar](10) NOT NULL,
	[TAXGROUP] [nvarchar](20) NOT NULL,
	[STATISTICSGROUP] [nvarchar](20) NOT NULL,
	[PAYMMODE] [nvarchar](20) NOT NULL,
	[COMMISSIONGROUP] [nvarchar](20) NOT NULL,
	[BANKACCOUNT] [nvarchar](10) NOT NULL,
	[PAYMSCHED] [nvarchar](30) NOT NULL,
	[NAMEALIAS] [nvarchar](20) NOT NULL,
	[CONTACTPERSONID] [nvarchar](20) NOT NULL,
	[INVOICEADDRESS] [int] NOT NULL,
	[OURACCOUNTNUM] [nvarchar](20) NOT NULL,
	[SALESPOOLID] [nvarchar](20) NOT NULL,
	[INCLTAX] [int] NOT NULL,
	[CUSTITEMGROUPID] [nvarchar](20) NOT NULL,
	[NUMBERSEQUENCEGROUP] [nvarchar](20) NOT NULL,
	[LANGUAGEID] [nvarchar](7) NOT NULL,
	[PAYMDAYID] [nvarchar](20) NOT NULL,
	[LINEOFBUSINESSID] [nvarchar](20) NOT NULL,
	[DESTINATIONCODEID] [nvarchar](20) NOT NULL,
	[GIROTYPE] [int] NOT NULL,
	[SUPPITEMGROUPID] [nvarchar](20) NOT NULL,
	[GIROTYPEINTERESTNOTE] [int] NOT NULL,
	[TAXLICENSENUM] [nvarchar](20) NOT NULL,
	[PAYMSPEC] [nvarchar](20) NOT NULL,
	[BANKCENTRALBANKPURPOSETEXT] [nvarchar](140) NOT NULL,
	[BANKCENTRALBANKPURPOSECODE] [nvarchar](10) NOT NULL,
	[CITY] [nvarchar](60) NOT NULL,
	[STREET] [nvarchar](250) NOT NULL,
	[PAGER] [nvarchar](20) NOT NULL,
	[SMS] [nvarchar](80) NOT NULL,
	[PACKMATERIALFEELICENSENUM] [nvarchar](20) NOT NULL,
	[DLVREASON] [nvarchar](20) NOT NULL,
	[GIROTYPECOLLECTIONLETTER] [int] NOT NULL,
	[SALESCALENDARID] [nvarchar](10) NOT NULL,
	[CUSTCLASSIFICATIONID] [nvarchar](20) NOT NULL,
	[SHIPCARRIERACCOUNT] [nvarchar](25) NOT NULL,
	[GIROTYPEPROJINVOICE] [int] NOT NULL,
	[INVENTSITEID] [nvarchar](10) NOT NULL,
	[ORDERENTRYDEADLINEGROUPID] [nvarchar](20) NOT NULL,
	[SHIPCARRIERID] [nvarchar](10) NOT NULL,
	[SHIPCARRIERFUELSURCHARGE] [int] NOT NULL,
	[SHIPCARRIERBLINDSHIPMENT] [int] NOT NULL,
	[PARTYTYPE] [int] NOT NULL,
	[PARTYID] [nvarchar](20) NOT NULL,
	[SHIPCARRIERACCOUNTCODE] [nvarchar](20) NOT NULL,
	[PROJPRICEGROUP] [nvarchar](20) NOT NULL,
	[GIROTYPEFREETEXTINVOICE] [int] NOT NULL,
	[SYNCENTITYID] [uniqueidentifier] NOT NULL,
	[SYNCVERSION] [bigint] NOT NULL,
	[MEMO] [ntext] NULL,
	[SALESDISTRICTID] [nvarchar](20) NOT NULL,
	[SEGMENTID] [nvarchar](20) NOT NULL,
	[SUBSEGMENTID] [nvarchar](20) NOT NULL,
	[RFIDITEMTAGGING] [int] NOT NULL,
	[RFIDCASETAGGING] [int] NOT NULL,
	[RFIDPALLETTAGGING] [int] NOT NULL,
	[COMPANYCHAINID] [nvarchar](20) NOT NULL,
	[MAINCONTACTID] [nvarchar](20) NOT NULL,
	[IDENTIFICATIONNUMBER] [nvarchar](50) NOT NULL,
	[PARTYCOUNTRY] [nvarchar](20) NOT NULL,
	[PARTYSTATE] [nvarchar](20) NOT NULL,
	[ECL_PREFERREDCONTACTMETHOD] [int] NOT NULL,
	[ECL_PREFERREDPRINTFORMAT] [int] NOT NULL,
	[ECL_ACMSPEECHID] [nvarchar](20) NOT NULL,
	[ECL_ACMCOMPREHENSIONID] [nvarchar](20) NOT NULL,
	[ECL_ACMHEARINGID] [nvarchar](20) NOT NULL,
	[ECL_ACMDENTURESID] [nvarchar](20) NOT NULL,
	[ECL_ACMORIENTATIONID] [nvarchar](20) NOT NULL,
	[ECL_ACMMEMORYID] [nvarchar](20) NOT NULL,
	[ECL_ACMPROSTHETICSID] [nvarchar](20) NOT NULL,
	[ECL_ACMMOBILITYID] [nvarchar](10) NOT NULL,
	[ECL_ACMSIGHTID] [nvarchar](20) NOT NULL,
	[PPTCURRENTFACILITYID] [nvarchar](250) NOT NULL,
	[ECL_ACMFACILITYID] [nvarchar](20) NOT NULL,
	[ECL_ACMACCOMMODATIONID] [nvarchar](20) NOT NULL,
	[ECL_ACMARCHIVED] [int] NOT NULL,
	[ECL_ACMPERMANENTRESPITE] [int] NOT NULL,
	[ECL_ACMRESIDENTDEPARTMENTID] [nvarchar](20) NOT NULL,
	[PPTNOCURRENTFACILITYID] [int] NOT NULL,
	[ECL_ACMGENDER] [int] NOT NULL,
	[ECL_ACMMARITALSTATUS] [int] NOT NULL,
	[ECL_ACMRELIGIONID] [nvarchar](20) NOT NULL,
	[ECL_ACMRESIDENTTYPEID] [nvarchar](20) NOT NULL,
	[ECL_ACMSPECIALNEEDSID] [nvarchar](20) NOT NULL,
	[ECL_ACMSPOKENLANGUAGEID] [nvarchar](20) NOT NULL,
	[ECL_ACMCOUNTRYOFBIRTH] [nvarchar](20) NOT NULL,
	[ECL_ACMDATEOFBIRTH] [datetime] NOT NULL,
	[ECL_ACMDATEOFBIRTHESTIMATE] [int] NOT NULL,
	[ECL_ACMDATEOFDEATH] [datetime] NOT NULL,
	[ECL_ACMPENSIONERNO] [nvarchar](15) NOT NULL,
	[ECL_ACMMEDICARENO] [nvarchar](15) NOT NULL,
	[ECL_ACMVETAFFAIRSDISABILITY] [int] NOT NULL,
	[ECL_ACMMEDICAREEXPIRYDATE] [datetime] NOT NULL,
	[ECL_ACMDVACARDSTATUS] [int] NOT NULL,
	[ECL_ACMDVASTATUS] [int] NOT NULL,
	[ECL_ACMAMBULANCENO] [nvarchar](15) NOT NULL,
	[ECL_ACMAMBULANCEEXPIRYDATE] [datetime] NOT NULL,
	[ECL_ACMACATASSESSMENT] [int] NOT NULL,
	[ECL_ACMDATELASTASSESSMENT] [datetime] NOT NULL,
	[ECL_ACMEXTRASEVICES] [int] NOT NULL,
	[ECL_ACMASSETSNOTDISCLOSED] [int] NOT NULL,
	[ECL_ACMCOMMONLAWSETTLEMENT] [int] NOT NULL,
	[ECL_ACMTHIRDPARTYINSURANCE] [int] NOT NULL,
	[ECL_ACMFINDETAILSRECEIVED] [int] NOT NULL,
	[ECL_ACMWORKERSCOMPOUTSTANDING] [int] NOT NULL,
	[ECL_ACMPREENTRYLEAVE] [int] NOT NULL,
	[ECL_ACMLEAVEFROM] [datetime] NOT NULL,
	[ECL_ACMLEAVETO] [datetime] NOT NULL,
	[ECL_ACMHIGHDEPENDENCYCARELEAVE] [int] NOT NULL,
	[ECL_ACMEXPECTEDCOMPLETIONDATE] [datetime] NOT NULL,
	[ECL_ACMNAMEOFOTHERRACS] [nvarchar](50) NOT NULL,
	[ECL_ACMAPPLICATIONRECEIVED] [int] NOT NULL,
	[ECL_ACMFIRSTNAME] [nvarchar](20) NOT NULL,
	[ECL_ACMMIDDLENAME] [nvarchar](20) NOT NULL,
	[ECL_ACMLASTNAME] [nvarchar](20) NOT NULL,
	[ECL_ACMPREFERREDNAME] [nvarchar](60) NOT NULL,
	[ECL_ACMSALUTATION] [int] NOT NULL,
	[ECL_ACMNAMESUFFIX] [int] NOT NULL,
	[ECL_ACMRESIDENTTITEL] [nvarchar](30) NOT NULL,
	[ECL_ACMEMPLID] [nvarchar](20) NOT NULL,
	[ECL_ACMCENTRELINKPENSIONEDATE] [datetime] NOT NULL,
	[ECL_ACMDVAPENSIONEXPIRYDATE] [datetime] NOT NULL,
	[ECL_ACMDVAPENSIONNO] [nvarchar](11) NOT NULL,
	[ECL_ACMACATASSESSVALIDTO] [datetime] NOT NULL,
	[ECL_ACMFAMILYHOMEEXEMPTED] [int] NOT NULL,
	[ECL_ACMASSETVALUE] [numeric](28, 12) NOT NULL,
	[ECL_ACMAGREEDINTERESTRATE] [numeric](28, 12) NOT NULL,
	[ECL_ACMACCPAYMSTATUS] [int] NOT NULL,
	[ECL_ACMPENSIONERSTATUS] [int] NOT NULL,
	[ECL_ACMBEDID] [nvarchar](20) NOT NULL,
	[ECL_ACMPRIVACYRESTRICTIONS] [int] NOT NULL,
	[ECL_ACMDVAPENSIONERSTATUS] [int] NOT NULL,
	[ECL_ACMPOW] [int] NOT NULL,
	[ECL_ACMPRIVMEDICALINSURANCE] [int] NOT NULL,
	[ECL_ACMPRIVMEDICALINSNAME] [nvarchar](30) NOT NULL,
	[ECL_ACMETHNICITYID] [nvarchar](20) NOT NULL,
	[ECL_ACMDEMENTIA] [int] NOT NULL,
	[ECL_ACMWANDERER] [int] NOT NULL,
	[ECL_ACMPICTUREDATE] [datetime] NOT NULL,
	[ECL_ACMCONSENTTOTAKEPICTURE] [int] NOT NULL,
	[ECL_ACMPICTURENOTES] [nvarchar](254) NOT NULL,
	[ECL_ACMDROPPEDBY2CATEGORIES] [int] NOT NULL,
	[ECL_ACMENTRYDATE] [datetime] NOT NULL,
	[ECL_ACMDEPARTUREDATE] [datetime] NOT NULL,
	[ECL_ACMFUNDSPAYCAREFEES] [int] NOT NULL,
	[ECL_ACMFUNDSPAYFEES] [int] NOT NULL,
	[ECL_ACMFUNDSPAYBONDSINTEREST] [int] NOT NULL,
	[ECL_ACMFUNDSPAYBONDSRETENTION] [int] NOT NULL,
	[ECL_ACMRESFUNDSCONTACTPERSONID] [nvarchar](20) NOT NULL,
	[ECL_ACMRESFUNDSCREDITMAX] [numeric](28, 12) NOT NULL,
	[ECL_ACMRESFUNDSPARTPENSIONAMT] [numeric](28, 12) NOT NULL,
	[ECL_ACMRESFUNDSGROUPSCHEDULE] [int] NOT NULL,
	[ECL_ACMRESIDENT] [int] NOT NULL,
	[ECL_ACMRESIDENTFUNDS] [int] NOT NULL,
	[ECL_ACMSELFFUNDEDRETIREE] [int] NOT NULL,
	[ECL_ACMACATRESPITE] [int] NOT NULL,
	[ECL_ACMACATPERMANENT] [int] NOT NULL,
	[ECL_ACMACATCOMMSERV] [int] NOT NULL,
	[ECL_ACMYEAROFBIRTH] [int] NOT NULL,
	[ECL_ACMRCSCATEGORYCODE] [nvarchar](10) NOT NULL,
	[ECL_ACMRCSEXPIRYDATE] [datetime] NOT NULL,
	[ECL_ACMNEXTRCSREVIEW] [datetime] NOT NULL,
	[ECL_ACMLASTRCSREVIEW] [datetime] NOT NULL,
	[ECL_ACMESTIMATEDCARECATEGORY] [nvarchar](10) NOT NULL,
	[ECL_ACMDATEOFBIRTHMONTH] [int] NOT NULL,
	[ECL_ACMDATEOFBIRTHDAY] [int] NOT NULL,
	[ECL_ACMDEEMINGEXEMPTFUNDS] [int] NOT NULL,
	[ECL_ACMRESSTATUSASSESSEDBY] [int] NOT NULL,
	[ECL_ACMCOMPLEXWOUNDMANAGEMENT] [int] NOT NULL,
	[ECL_ACMSWALLOWINGPROBLEMS] [int] NOT NULL,
	[ECL_ACMCATHETERMANAGEMENT] [int] NOT NULL,
	[ECL_ACMTUBEFEEDING] [int] NOT NULL,
	[ECL_ACMINSULINADMINISTRATION] [int] NOT NULL,
	[ECL_ACMINTERPRETERREQUIRED] [int] NOT NULL,
	[ECL_ACMDONOR] [int] NOT NULL,
	[ECL_ACMENROLLEDTOVOTE] [int] NOT NULL,
	[ECL_ACMNUMOFRESPITEDAYSUSED] [int] NOT NULL,
	[ECL_ACMDATEOFCONFIRM] [datetime] NOT NULL,
	[ECL_ACMCONFIRMFROMDEPT] [int] NOT NULL,
	[ECL_ACMRESPITEBOOKINGAMOUNT] [numeric](28, 12) NOT NULL,
	[ECL_ACMPERIODICBILLINGPERIOD] [int] NOT NULL,
	[ECL_ACMOCCUPANCYDATE] [datetime] NOT NULL,
	[ECL_ACMAGREEDOCCUPANCYDATE] [datetime] NOT NULL,
	[ECL_ACMAGREEMENTDATE] [datetime] NOT NULL,
	[ECL_ACMPROPOSEDACCCHARGE] [numeric](28, 12) NOT NULL,
	[ECL_ACMACCCHARGEINTERESTRATE] [numeric](28, 12) NOT NULL,
	[ECL_ACMADMINFEE] [numeric](28, 12) NOT NULL,
	[ECL_ACMPROPACCCHARGEPERPERIOD] [numeric](28, 12) NOT NULL,
	[ECL_ACMPRIVMEDICALINSNO] [nvarchar](20) NOT NULL,
	[ECL_ACMDATEOFBONDREPAYMENT] [datetime] NOT NULL,
	[ECL_ACMBALANCEHELDINSEPACC] [int] NOT NULL,
	[ECL_ACMOTHERREASONSFORDELAY] [nvarchar](50) NOT NULL,
	[ECL_ACMDATEADVPROBATEGRANTED] [datetime] NOT NULL,
	[ECL_ACMPROBATEINVOLVED] [int] NOT NULL,
	[ECL_ACMDATEOFNOTIFTODEPART] [datetime] NOT NULL,
	[ECL_ACMWEIGHTLOSS] [numeric](28, 12) NOT NULL,
	[ECL_ACMPERIOD] [int] NOT NULL,
	[ECL_ACMNOOFPERIOD] [numeric](28, 12) NOT NULL,
	[ECL_ACMWEIGHTUNITID] [nvarchar](20) NOT NULL,
	[ECL_ACMMINALERTWEIGHT] [numeric](28, 12) NOT NULL,
	[ECL_ACMMAXALERTWEIGHT] [numeric](28, 12) NOT NULL,
	[ECL_ACMTEMPERATUREMAX] [numeric](28, 12) NOT NULL,
	[ECL_ACMTEMPERATUREMIN] [numeric](28, 12) NOT NULL,
	[ECL_ACMTEMPERATUREUNITID] [nvarchar](20) NOT NULL,
	[ECL_ACMTEMPROUTE] [int] NOT NULL,
	[ECL_ACMBLOODPRESSURESYSMIN] [numeric](28, 12) NOT NULL,
	[ECL_ACMBLOODPRESSURESYSMAX] [numeric](28, 12) NOT NULL,
	[ECL_ACMBLOODPRESSUREDIAMIN] [numeric](28, 12) NOT NULL,
	[ECL_ACMBLOODPRESSUREDIAMAX] [numeric](28, 12) NOT NULL,
	[ECL_ACMBLOODPRESSUREUNITID] [nvarchar](20) NOT NULL,
	[ECL_ACMPULSEMIN] [numeric](28, 12) NOT NULL,
	[ECL_ACMPULSEMAX] [numeric](28, 12) NOT NULL,
	[ECL_ACMPULSEUNITID] [nvarchar](20) NOT NULL,
	[ECL_ACMPULSEROUTE] [int] NOT NULL,
	[ECL_ACMRESPIRATIONMIN] [numeric](28, 12) NOT NULL,
	[ECL_ACMRESPIRATIONMAX] [numeric](28, 12) NOT NULL,
	[ECL_ACMRESPIRATIONUNITID] [nvarchar](20) NOT NULL,
	[ECL_ACMBGLMIN] [numeric](28, 12) NOT NULL,
	[ECL_ACMBGLMAX] [numeric](28, 12) NOT NULL,
	[ECL_ACMBGLUNITID] [nvarchar](20) NOT NULL,
	[ECL_ACMEXPECTEDDEPARTUREDATE] [datetime] NOT NULL,
	[ECL_ACMEXPECTEDBONDREPAYDATE] [datetime] NOT NULL,
	[ECL_OLDCUSTOMERNUM] [nvarchar](50) NOT NULL,
	[ECL_ACMLETTEROFADMINVOLVED] [int] NOT NULL,
	[ECL_ACMLETTEROFADMRECEIVED] [datetime] NOT NULL,
	[ECL_ACMRESIDENTSELFMEDICATE] [int] NOT NULL,
	[ECL_ACMHEIGHT] [numeric](28, 12) NOT NULL,
	[ECL_ACMHEIGHTUNITID] [nvarchar](20) NOT NULL,
	[ECL_FUNDINGTYPE] [int] NOT NULL,
	[ECL_MHACCHECK1] [int] NOT NULL,
	[ECL_MHACCHECK2] [int] NOT NULL,
	[ECL_MHACCHECK3] [int] NOT NULL,
	[ECL_MHACCHECK4] [int] NOT NULL,
	[ECL_MHACCHECK5] [int] NOT NULL,
	[ECL_MHACTEXT1] [nvarchar](60) NOT NULL,
	[ECL_MHACTEXT2] [nvarchar](60) NOT NULL,
	[ECL_MHACTEXT3] [nvarchar](60) NOT NULL,
	[ECL_MHACTEXT4] [nvarchar](60) NOT NULL,
	[ECL_MHACTEXT5] [nvarchar](60) NOT NULL,
	[ECL_DIRECTDEBITAMOUNT] [numeric](28, 12) NOT NULL,
	[ECL_DIRECTDEBIT] [int] NOT NULL,
	[ECL_ADDITIONALDDAMOUNT] [numeric](28, 12) NOT NULL,
	[ECL_ACMDATEENTEREDORIGSERVICE] [datetime] NOT NULL,
	[ECL_ACMMEDICARECARDPOSITION] [nvarchar](10) NOT NULL,
	[ECL_ACMDIABETICCARDNO] [nvarchar](20) NOT NULL,
	[ECL_ACMINSULINDEPENDENT] [int] NOT NULL,
	[ECL_ACMOSTOMYMEMBERSHIPNO] [nvarchar](20) NOT NULL,
	[ECL_IMAGE] [image] NULL,
	[ECL_ACMHASALLERGY] [int] NOT NULL,
	[EBUSCOMMUNITYRECIPIENTID] [nvarchar](15) NOT NULL,
	[ECL_ACMEBUSLIABILITYSTARTDATE] [datetime] NOT NULL,
	[ECL_ACMFREETEXTINVOICE] [int] NOT NULL,
	[ECL_ACMFIRSTSTATEMENTADRLINE] [nvarchar](60) NOT NULL,
	[ECL_ACMRESIDENTFIRSTENTRYDATE] [datetime] NOT NULL,
	[ECL_ACMCHARGEEXEMPT] [int] NOT NULL,
	[PPTWORKPHONE] [nvarchar](20) NOT NULL,
	[ECL_ACMCHECKLISTID] [nvarchar](20) NOT NULL,
	[PPTCSCLIENT] [int] NOT NULL,
	[MODIFIEDDATETIME] [datetime] NOT NULL,
	[CREATEDDATETIME] [datetime] NOT NULL,
	[DATAAREAID] [nvarchar](4) NOT NULL,
	[RECVERSION] [int] NOT NULL,
	[RECID] [bigint] NOT NULL,
	[PPTBONDINTERESTPAYMMODE] [nvarchar](20) NOT NULL,
	[ECL_ACMDIRECTDEBITUPTOAMT] [int] NOT NULL,
	[ECL_ACMMAXAMOUNT] [numeric](28, 12) NOT NULL,
	[ECL_ACMACATTRANS] [int] NOT NULL,
	[ECL_ACMBONDCONTPAYMENTTRANS] [int] NOT NULL,
	[ECL_ACMRETDRAWNTODATE] [datetime] NOT NULL,
	[ECL_ACMNUMRETENTIONS] [int] NOT NULL,
	[ECL_ACMMTHLYRETAMTTRANS] [numeric](28, 12) NOT NULL,
	[ECL_ACMLUMPSUMAMTTRANS] [numeric](28, 12) NOT NULL,
	[ECL_ACMAGREEBONDAMTTRANS] [numeric](28, 12) NOT NULL,
	[ECL_ACMADMINTRANSDATE] [datetime] NOT NULL,
	[ECL_ACMFACILITYTRANSTO] [nvarchar](60) NOT NULL,
	[PPTCCMININR] [numeric](28, 12) NOT NULL,
	[PPTCCMAXINR] [numeric](28, 12) NOT NULL,
	[PPTCCAGGRESSIVEBEHAVIOUR] [int] NOT NULL,
	[GIROTYPEACCOUNTSTATEMENT] [int] NOT NULL,
	[PPTRVBONDLODGEMENTNO] [nvarchar](15) NOT NULL,
	[MODIFIEDBY] [nvarchar](5) NOT NULL,
	[CREATEDBY] [nvarchar](5) NOT NULL,
	[EINVOICE] [int] NOT NULL,
	[CREDITCARDADDRESSVERIFICATION] [int] NOT NULL,
	[CREDITCARDCVC] [int] NOT NULL,
	[CREDITCARDADDRESSVERIFICATI292] [int] NOT NULL,
	[CREDITCARDADDRESSVERIFICATI293] [int] NOT NULL,
	[USECASHDISC] [int] NOT NULL,
	[CASHDISCBASEDAYS] [int] NOT NULL,
	[PPTIHI] [nvarchar](16) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_Dimensions]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_Dimensions](
	[DESCRIPTION] [nvarchar](60) NOT NULL,
	[NUM] [nvarchar](20) NOT NULL,
	[DIMENSIONCODE] [int] NOT NULL,
	[INCHARGE] [nvarchar](20) NOT NULL,
	[COMPANYGROUP] [nvarchar](10) NOT NULL,
	[CLOSED] [int] NOT NULL,
	[REVERSESIGN] [int] NOT NULL,
	[COLUMN_] [int] NOT NULL,
	[BOLDTYPEFACE] [int] NOT NULL,
	[ITALIC] [int] NOT NULL,
	[LINEEXCEED] [int] NOT NULL,
	[LINESUB] [int] NOT NULL,
	[UNDERLINETXT] [int] NOT NULL,
	[UNDERLINENUMERALS] [int] NOT NULL,
	[COSBLOCKPOSTCOST] [int] NOT NULL,
	[COSBLOCKPOSTWORK] [int] NOT NULL,
	[COSBLOCKDISTRIBUTION] [int] NOT NULL,
	[COSBLOCKALLOCATION] [int] NOT NULL,
	[ECL_DISABLEDDIMENSION] [int] NOT NULL,
	[ECL_APPROVALACTIVE] [int] NOT NULL,
	[ECL_DIMINACTIVE] [int] NOT NULL,
	[DATAAREAID] [nvarchar](4) NOT NULL,
	[RECVERSION] [int] NOT NULL,
	[RECID] [bigint] NOT NULL,
	[ECL_BANKSERIALNUMBER] [nvarchar](10) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_ECL_Accommodation]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_ECL_Accommodation](
	[FACILITYID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONID] [nvarchar](20) NOT NULL,
	[DESCRIPTION] [nvarchar](50) NOT NULL,
	[ACCOMMODATIONSTATUSID] [nvarchar](20) NOT NULL,
	[BLOCKED] [int] NOT NULL,
	[ACCOMMODATIONTYPEID] [nvarchar](20) NOT NULL,
	[ACCOMMODATIONSTYLEID] [nvarchar](20) NOT NULL,
	[SQUAREMETERS] [numeric](28, 12) NOT NULL,
	[RESPITE_DEL] [int] NOT NULL,
	[ACCOMMODATIONNAME] [nvarchar](50) NOT NULL,
	[OPENTIME] [int] NOT NULL,
	[CLOSETIME] [int] NOT NULL,
	[MAXCAPACITY] [int] NOT NULL,
	[MINCAPACITY] [int] NOT NULL,
	[RVSTATUS] [int] NOT NULL,
	[CURRENTTYPE] [int] NOT NULL,
	[SALEABLEDATE] [datetime] NOT NULL,
	[NOTES] [ntext] NULL,
	[SALESTATUS] [int] NOT NULL,
	[PHASEID] [nvarchar](10) NOT NULL,
	[SALESPERSON] [nvarchar](20) NOT NULL,
	[MARKETPRICE] [numeric](28, 12) NOT NULL,
	[ACTIVE] [int] NOT NULL,
	[ACTUALSALEABLEDATE] [datetime] NOT NULL,
	[VALUATIONDATE] [datetime] NOT NULL,
	[APPLICATIONID] [nvarchar](20) NOT NULL,
	[DATAAREAID] [nvarchar](4) NOT NULL,
	[RECVERSION] [int] NOT NULL,
	[RECID] [bigint] NOT NULL,
	[RVCONTRACTDATE] [datetime] NOT NULL,
	[RVCONTRACTTYPEID] [nvarchar](10) NOT NULL,
	[RVUNITCONTRACTGROUP] [nvarchar](75) NOT NULL,
	[RVEXPECTEDSETTLEMENTDATE] [datetime] NOT NULL,
	[RVACTUALSETTLEMENTDATE] [datetime] NOT NULL,
	[RVCANCELLEDDATE] [datetime] NOT NULL,
	[RVESTIMATEDVALUE] [numeric](28, 12) NOT NULL,
	[RVCONTRACTPRICE1] [numeric](28, 12) NOT NULL,
	[RVCONTRACTPRICE1ACTIVATE] [datetime] NOT NULL,
	[RVCONTRACTPRICE1DEACTIVATE] [datetime] NOT NULL,
	[RVCONTRACTPRICE2] [numeric](28, 12) NOT NULL,
	[RVCONTRACTPRICE2ACTIVATE] [datetime] NOT NULL,
	[RVCONTRACTPRICE2DEACTIVATE] [datetime] NOT NULL,
	[RVCONTRACTPRICE3] [numeric](28, 12) NOT NULL,
	[RVCONTRACTPRICE3ACTIVATE] [datetime] NOT NULL,
	[RVCONTRACTPRICE3DEACTIVATE] [datetime] NOT NULL,
	[CURRENTCONTRACTSTATUS] [nvarchar](10) NOT NULL,
	[DEPOSITAMOUNT] [numeric](28, 12) NOT NULL,
	[DEPOSITCONFIRMEDDATE] [datetime] NOT NULL,
	[PAYMENTDETAILS] [nvarchar](20) NOT NULL,
	[RVPURCHASEPRICE] [numeric](28, 12) NOT NULL,
	[RVCOSTOFSALE] [numeric](28, 12) NOT NULL,
	[RVMINSELLINGPRICE1] [numeric](28, 12) NOT NULL,
	[RVMINSELLINGPRICE1DEACTIVATE] [datetime] NOT NULL,
	[RVMINSELLINGPRICE2] [numeric](28, 12) NOT NULL,
	[RVMINSELLINGPRICE2ACTIVATE] [datetime] NOT NULL,
	[RVMINSELLINGPRICE2DEACTIVATE] [datetime] NOT NULL,
	[RVACTUALSALEABLEDATE] [datetime] NOT NULL,
	[RVEXPECTEDPOSSESSIONDATE] [datetime] NOT NULL,
	[RVCONFIRMEDPOSSESSIONDATE] [datetime] NOT NULL,
	[RVACTUALPOSSESSIONDATE] [datetime] NOT NULL,
	[RVVACANTPOSSESSIONDATE] [datetime] NOT NULL,
	[RVUNITCLEARED] [int] NOT NULL,
	[RVUNITCLEANED] [int] NOT NULL,
	[RVCONDITIONAUDITREPORT] [int] NOT NULL,
	[RVKEYSRETURNED] [int] NOT NULL,
	[RVVALUATIONPRICE1] [numeric](28, 12) NOT NULL,
	[RVVALUATIONPRICE1DEACTIVATE] [datetime] NOT NULL,
	[RVVALUATIONPRICE2] [numeric](28, 12) NOT NULL,
	[RVVALUATIONPRICE2ACTIVATE] [datetime] NOT NULL,
	[RVVALUATIONPRICE2DEACTIVATE] [datetime] NOT NULL,
	[RVACTIVATEDATE] [datetime] NOT NULL,
	[RVDEACTIVATEDATE] [datetime] NOT NULL,
	[RVCOMPLETIONDATE] [datetime] NOT NULL,
	[RVAVAILABILITYDATE] [datetime] NOT NULL,
	[RVOWNERSHIPTYPE] [nvarchar](10) NOT NULL,
	[RVTENURE] [nvarchar](20) NOT NULL,
	[RVSTAGE] [nvarchar](10) NOT NULL,
	[RVCONDITIONOFUNIT] [nvarchar](10) NOT NULL,
	[RVSERVICETYPE] [nvarchar](20) NOT NULL,
	[RVUNITTYPE] [nvarchar](10) NOT NULL,
	[RVNOOFLEVELS] [nvarchar](20) NOT NULL,
	[RVNOOFBEDROOMS] [nvarchar](20) NOT NULL,
	[RVNOOFBATHROOMS] [nvarchar](20) NOT NULL,
	[RVLIVINGAREA] [nvarchar](20) NOT NULL,
	[RVCONSERVATORYAREA] [int] NOT NULL,
	[RVLOCATIONWITHBUILDING] [nvarchar](20) NOT NULL,
	[RVGARAGEAREA] [int] NOT NULL,
	[RVPATIODECKAREA] [int] NOT NULL,
	[RVCERTIFICATIONFORHOSPITAL] [int] NOT NULL,
	[RVCERTIFICATIONFORDEMENTIA] [int] NOT NULL,
	[RVSTEPSINOUTOFUNIT] [nvarchar](20) NOT NULL,
	[RVOWNGARDEN] [int] NOT NULL,
	[RVFENCEDYARD] [int] NOT NULL,
	[RVCARPARKCARPORTATTACHED] [int] NOT NULL,
	[RVPRIVACY] [int] NOT NULL,
	[RVASPECT] [nvarchar](10) NOT NULL,
	[RVOUTDOORLIVING] [nvarchar](10) NOT NULL,
	[RVACCESSTOUNIT] [nvarchar](10) NOT NULL,
	[RVACCESSTOFACILITIES] [nvarchar](10) NOT NULL,
	[RVUNITOUTLOOK] [nvarchar](10) NOT NULL,
	[RVSPECIALFEATURES] [nvarchar](255) NOT NULL,
	[RVCONSTRUCTIONCOST] [numeric](28, 12) NOT NULL,
	[RVREFURBISHMENTQUOTEAMOUNT] [numeric](28, 12) NOT NULL,
	[RVREFURBISHMENTCOMMENT] [nvarchar](255) NOT NULL,
	[RVCONTRACTOR] [nvarchar](50) NOT NULL,
	[RVREFURBISHMENTSTATUS] [nvarchar](10) NOT NULL,
	[RVLASTREFURBISHEDDATE] [datetime] NOT NULL,
	[RVINSPECTEDBY] [nvarchar](20) NOT NULL,
	[RVINSPECTEDDATE] [datetime] NOT NULL,
	[RVINSPECTEDTIME] [int] NOT NULL,
	[RVINSPECTIONCOMMENT] [nvarchar](255) NOT NULL,
	[RVOCCUPIEDSTATUSID] [nvarchar](10) NOT NULL,
	[RVLISTINGSTATUSID] [nvarchar](10) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_Facility]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_Facility](
	[FACILITYID] [nvarchar](20) NOT NULL,
	[NAME] [nvarchar](50) NOT NULL,
	[FACILITYTYPEID] [nvarchar](20) NOT NULL,
	[RACSNO] [nvarchar](6) NOT NULL,
	[CERTIFIED] [int] NOT NULL,
	[RESIDENTFUNDSLIABILITYACCOUNT] [nvarchar](50) NOT NULL,
	[DIMENSION] [nvarchar](20) NOT NULL,
	[DIMENSION2_] [nvarchar](20) NOT NULL,
	[DIMENSION3_] [nvarchar](20) NOT NULL,
	[ADDRESS] [nvarchar](250) NOT NULL,
	[STREET] [nvarchar](250) NOT NULL,
	[ZIPCODE] [nvarchar](10) NOT NULL,
	[CITY] [nvarchar](60) NOT NULL,
	[COUNTY] [nvarchar](32) NOT NULL,
	[STATE] [nvarchar](20) NOT NULL,
	[COUNTRY] [nvarchar](20) NOT NULL,
	[DEL_REFZIPCODE] [bigint] NOT NULL,
	[PHONE] [nvarchar](20) NOT NULL,
	[PHONELOCAL] [nvarchar](10) NOT NULL,
	[PHONEMOBILE] [nvarchar](20) NOT NULL,
	[PAGER] [nvarchar](20) NOT NULL,
	[TELEFAX] [nvarchar](20) NOT NULL,
	[EMAIL] [nvarchar](80) NOT NULL,
	[SMS] [nvarchar](80) NOT NULL,
	[URL] [nvarchar](255) NOT NULL,
	[TELEX] [nvarchar](20) NOT NULL,
	[CONTACTPERSONID] [nvarchar](20) NOT NULL,
	[CERTIFIEDDATE] [datetime] NOT NULL,
	[INGOINGCONTRIBUTIONACCOUNT] [nvarchar](50) NOT NULL,
	[INGOINGCONTRIBUTIONBANKACCOUNT] [nvarchar](10) NOT NULL,
	[RACSNAME] [nvarchar](50) NOT NULL,
	[DEFAULTOPERATINGBANKACCOUNT] [nvarchar](10) NOT NULL,
	[RESIDENTFUNDSBANKACCOUNT] [nvarchar](10) NOT NULL,
	[SERVICETYPEID] [nvarchar](20) NOT NULL,
	[RESPITECALENDARID] [nvarchar](20) NOT NULL,
	[REGIONALCONCESASSISTPCT] [numeric](28, 12) NOT NULL,
	[USERGROUPID] [nvarchar](10) NOT NULL,
	[ADMINISTRATOR] [nvarchar](20) NOT NULL,
	[DEL_INITIALASSESMENTCAREPLANID] [nvarchar](10) NOT NULL,
	[DEL_SHORTTERMCAREPLANID] [nvarchar](10) NOT NULL,
	[DEL_INITIALCAREPLANVERSIONID] [nvarchar](20) NOT NULL,
	[ECL_ACMESCALATIONSEQUENCE] [nvarchar](10) NOT NULL,
	[DIFFERENCEINHOURSFROMSERVER] [int] NOT NULL,
	[ECL_ACMESCALATIONACTIVE] [int] NOT NULL,
	[ECL_CITYOF] [nvarchar](60) NOT NULL,
	[ECL_STATEOF] [nvarchar](20) NOT NULL,
	[ECL_ZIPCODEOF] [nvarchar](10) NOT NULL,
	[ECL_ACMDIFFINHOURSFROMSERVER] [numeric](28, 12) NOT NULL,
	[INTERFACEPOSTINGCODE] [nvarchar](8) NOT NULL,
	[CLINICALCAREALERTEMPLOYEE] [nvarchar](20) NOT NULL,
	[ECL_ACMEBUSAGEDCARESERVICECODE] [int] NOT NULL,
	[ECL_ACMEBUSORGANISATIONTYPE] [int] NOT NULL,
	[EBPROXYUSERNAME] [nvarchar](30) NOT NULL,
	[ECL_ACMEBUSSERVICEID] [nvarchar](6) NOT NULL,
	[ECL_ACMEBUSEDIMINORID] [nvarchar](8) NOT NULL,
	[RESIDENTFUNDSBANKLEDGERACCOUNT] [nvarchar](50) NOT NULL,
	[FIRESAFETY1999] [int] NOT NULL,
	[FIRESAFETY1999DATE] [datetime] NOT NULL,
	[PRIVACYSPACE2008] [int] NOT NULL,
	[PRIVACYSPACE2008DATE] [datetime] NOT NULL,
	[EBUSCRYPTOSTOREFILE] [nvarchar](259) NOT NULL,
	[EBUSPKIPASSWORDBLOB] [image] NULL,
	[PARTYID] [nvarchar](20) NOT NULL,
	[WORKPHONE] [nvarchar](20) NOT NULL,
	[EMAILONHOLD] [nvarchar](80) NOT NULL,
	[EMAILONRESERVE] [nvarchar](80) NOT NULL,
	[EMAILONCANCELLATION] [nvarchar](80) NOT NULL,
	[EBPROXYPASSWORDBLOB] [image] NULL,
	[EBRUNON] [int] NOT NULL,
	[DATAAREAID] [nvarchar](4) NOT NULL,
	[RECVERSION] [int] NOT NULL,
	[RECID] [bigint] NOT NULL,
	[RVACTIVATIONDATE] [datetime] NOT NULL,
	[RVREGIONID] [nvarchar](10) NOT NULL,
	[RVCOUNCILAREAID] [nvarchar](10) NOT NULL,
	[RVSWIMMINGPOOL] [int] NOT NULL,
	[RVCOMMUNITYAREA] [int] NOT NULL,
	[RVCLOSETOSHOPS] [int] NOT NULL,
	[RVVILLAGEBUS] [int] NOT NULL,
	[RVPUBLICTRANSPORT] [int] NOT NULL,
	[RVSPECIALFEATURES] [nvarchar](255) NOT NULL,
	[PPTRVSTATUTORYSUPERVISORID] [nvarchar](20) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_Fee]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_Fee](
	[DIMENSION] [nvarchar](20) NOT NULL,
	[RESIDENTTYPE] [nvarchar](10) NOT NULL,
	[STARTDATE] [datetime] NOT NULL,
	[Fee] [numeric](28, 12) NOT NULL,
	[GSTRate] [numeric](33, 16) NULL,
	[FeeExGST] [numeric](38, 6) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_AX_LedgerTable]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SOURCE_AX_LedgerTable](
	[ACCOUNTNUM] [nvarchar](50) NOT NULL,
	[ACCOUNTNAME] [nvarchar](60) NOT NULL,
	[ACCOUNTPLTYPE] [int] NOT NULL,
	[OFFSETACCOUNT] [nvarchar](50) NOT NULL,
	[LEDGERCLOSING] [int] NOT NULL,
	[TAXGROUP] [nvarchar](20) NOT NULL,
	[BLOCKEDINJOURNAL] [int] NOT NULL,
	[DEBCREDPROPOSAL] [int] NOT NULL,
	[DIMENSION] [nvarchar](20) NOT NULL,
	[DIMENSION2_] [nvarchar](20) NOT NULL,
	[DIMENSION3_] [nvarchar](20) NOT NULL,
	[CONVERSIONPRINCIPLE] [int] NOT NULL,
	[OPENINGACCOUNT] [nvarchar](50) NOT NULL,
	[COMPANYGROUPACCOUNT] [nvarchar](10) NOT NULL,
	[DIMSPEC] [int] NOT NULL,
	[TAXCODE] [nvarchar](20) NOT NULL,
	[MANDATORYTAXCODE] [int] NOT NULL,
	[CURRENCYCODE] [nvarchar](3) NOT NULL,
	[MANDATORYCURRENCY] [int] NOT NULL,
	[AUTOALLOCATE] [int] NOT NULL,
	[POSTING] [int] NOT NULL,
	[MANDATORYPOSTING] [int] NOT NULL,
	[USER_] [nvarchar](5) NOT NULL,
	[MANDATORYUSER] [int] NOT NULL,
	[DEBCREDCHECK] [int] NOT NULL,
	[REVERSESIGN] [int] NOT NULL,
	[MANDATORYDIMENSION] [int] NOT NULL,
	[MANDATORYDIMENSION2_] [int] NOT NULL,
	[MANDATORYDIMENSION3_] [int] NOT NULL,
	[COLUMN_] [int] NOT NULL,
	[TAXDIRECTION] [int] NOT NULL,
	[LINESUB] [int] NOT NULL,
	[LINEEXCEED] [int] NOT NULL,
	[UNDERLINENUMERALS] [int] NOT NULL,
	[UNDERLINETXT] [int] NOT NULL,
	[ITALIC] [int] NOT NULL,
	[BOLDTYPEFACE] [int] NOT NULL,
	[EXCHADJUSTED] [int] NOT NULL,
	[ACCOUNTNAMEALIAS] [nvarchar](60) NOT NULL,
	[CLOSED] [int] NOT NULL,
	[DEBCREDBALANCEDEMAND] [int] NOT NULL,
	[TAXFREE] [int] NOT NULL,
	[TAXITEMGROUP] [nvarchar](20) NOT NULL,
	[MONETARY] [int] NOT NULL,
	[ACCOUNTCATEGORYREF] [int] NOT NULL,
	[ECL_LEDGERGROUPID] [nvarchar](10) NOT NULL,
	[DATAAREAID] [nvarchar](4) NOT NULL,
	[RECVERSION] [int] NOT NULL,
	[RECID] [bigint] NOT NULL,
	[MODIFIEDDATETIME] [datetime] NOT NULL,
	[MODIFIEDBY] [nvarchar](5) NOT NULL,
	[CREATEDDATETIME] [datetime] NOT NULL,
	[CREATEDBY] [nvarchar](5) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SOURCE_PG_Allowance]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Allowance](
	[AllowanceCode] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[Type] [varchar](30) NULL,
	[Paying] [bit] NULL,
	[Penalty] [bit] NULL,
	[Taxable] [bit] NULL,
	[NIExempt] [bit] NULL,
	[TaxOverride] [bit] NULL,
	[TaxOverrideType] [varchar](24) NULL,
	[RateCode] [varchar](12) NULL,
	[Rate] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[MaxQuantity] [numeric](6, 2) NULL,
	[Calc] [varchar](50) NULL,
	[Rank] [varchar](2) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[Ordinary] [bit] NULL,
	[ReasonCode] [varchar](12) NULL,
	[Hidden] [bit] NULL,
	[Suspended] [bit] NULL,
	[AllowProportional] [bit] NULL,
	[CostAllowanceGroupCode] [varchar](12) NULL,
	[HPInclude] [bit] NULL,
	[SuperInclude] [bit] NULL,
	[StatReport] [bit] NULL,
	[FTECalc] [bit] NULL,
	[Expense] [bit] NULL,
	[LeaveCreditCode] [varchar](12) NULL,
	[TaxOverrideRate] [numeric](5, 2) NULL,
	[GeneralLedgerCode] [varchar](24) NULL,
	[GeneralLedgerDesc] [varchar](30) NULL,
	[AllowanceGroupCode] [varchar](12) NULL,
	[PercentOfAllowanceGroup] [numeric](6, 2) NULL,
	[AdvanceRateCode] [varchar](12) NULL,
	[Breaks] [varchar](200) NULL,
	[RateCalculation] [varchar](12) NULL,
	[RateFormula] [varchar](255) NULL,
	[FactorCalculation] [varchar](12) NULL,
	[FactorFormula] [varchar](255) NULL,
	[CostCentreCalculation] [varchar](12) NULL,
	[PayPeriodCode] [varchar](12) NULL,
	[Consolidate] [bit] NULL,
	[PayrollAllowanceCode] [varchar](12) NULL,
	[PayrollConsolidate] [bit] NULL,
	[PayrollRecalculate] [bit] NULL,
	[PayrollClass] [varchar](12) NULL,
	[PayrollType] [varchar](20) NULL,
	[PayrollExport] [bit] NULL,
	[JobCostingExport] [bit] NULL,
	[Accumulator] [int] NULL,
	[ExtraQuantity] [bit] NULL,
	[ProvidentFundClass] [varchar](30) NULL,
	[WeeksAbsent] [bit] NULL,
	[ShowHistAnalysis] [bit] NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[AllowanceID] [int] NOT NULL,
	[DirectCredit] [bit] NULL,
	[ConsolidateDC] [bit] NULL,
	[BankAccount] [varchar](16) NULL,
	[BankReference] [varchar](18) NULL,
	[BankCode] [varchar](12) NULL,
	[BankParticulars] [varchar](12) NULL,
	[AcName] [varchar](30) NULL,
	[NetGrossAllowance] [bit] NULL,
	[AcceptanceRange] [int] NULL,
	[MaxIterations] [int] NULL,
	[SummaryType] [varchar](18) NULL,
	[SuperTransaction] [bit] NULL,
	[AusSuperSalaryWagesInclude] [bit] NULL,
	[LoadingCashoutAllowanceCode] [varchar](12) NULL,
	[XALLEXP] [datetime] NULL,
	[PayoutType] [varchar](16) NULL,
	[SubType] [varchar](30) NULL,
	[BackPayAllowanceCode] [varchar](12) NULL,
	[NonTaxDeductionsReduceNett] [bit] NULL,
	[ReportingCategory] [varchar](30) NULL,
	[ReportingSubcategory] [varchar](30) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_CostCentre]    Script Date: 16/07/2018 11:49:36 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_CostCentre](
	[CostCentreCode] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[GeneralLedgerCode] [varchar](24) NULL,
	[GeneralLedgerDesc] [varchar](30) NULL,
	[ExpiryDate] [datetime] NULL,
	[ManagerEmployeeCode] [varchar](12) NULL,
	[AssistantEmployeeCode] [varchar](12) NULL,
	[ManagerName] [varchar](30) NULL,
	[ManagerPhone] [varchar](15) NULL,
	[ManagerFax] [varchar](20) NULL,
	[ManagerEmail] [varchar](60) NULL,
	[LocationCode] [varchar](12) NULL,
	[DepartmentCode] [varchar](12) NULL,
	[UserProfileCode] [varchar](12) NULL,
	[BudgetCentreCode] [varchar](12) NULL,
	[TotalAmount] [numeric](13, 2) NULL,
	[BudgetedAmount] [numeric](13, 2) NULL,
	[TotalFTEHours] [numeric](11, 2) NULL,
	[BudgetedFTEHours] [numeric](11, 2) NULL,
	[OperatingCost] [bit] NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[CostCentreID] [int] NOT NULL,
	[XCCDIM1CODE] [varchar](12) NULL,
	[XCCACTIVE] [bit] NULL,
	[XCCDIM2CODE] [varchar](12) NULL,
	[XCCDIM3CODE] [varchar](12) NULL,
	[XCCDIM4CODE] [varchar](12) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Department]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Department](
	[DepartmentCode] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[ManagerEmployeeCode] [varchar](12) NULL,
	[AssistantEmployeeCode] [varchar](12) NULL,
	[ManagerName] [varchar](30) NULL,
	[ManagerPhone] [varchar](15) NULL,
	[ManagerMobilePhone] [varchar](15) NULL,
	[ManagerPager] [varchar](15) NULL,
	[ManagerFax] [varchar](20) NULL,
	[ManagerEmail] [varchar](60) NULL,
	[Filename] [varchar](60) NULL,
	[CashAreaCode] [varchar](12) NULL,
	[UserProfileCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[BudgetCentreCode] [varchar](12) NULL,
	[JobCode] [varchar](12) NULL,
	[AwardCode] [varchar](12) NULL,
	[RateCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[DepartmentID] [int] NOT NULL,
	[XDEPTACTIVE] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Dim1]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Dim1](
	[Dim1Code] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[ManagerEmployeeCode] [varchar](12) NULL,
	[AssistantEmployeeCode] [varchar](12) NULL,
	[ManagerName] [varchar](30) NULL,
	[ManagerPhone] [varchar](15) NULL,
	[ManagerFax] [varchar](20) NULL,
	[ManagerEmail] [varchar](60) NULL,
	[Filename] [varchar](60) NULL,
	[CashAreaCode] [varchar](12) NULL,
	[UserProfileCode] [varchar](12) NULL,
	[BudgetCentreCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[JobCode] [varchar](12) NULL,
	[AwardCode] [varchar](12) NULL,
	[RateCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[Dim1ID] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Dim2]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Dim2](
	[Dim2Code] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[ManagerEmployeeCode] [varchar](12) NULL,
	[AssistantEmployeeCode] [varchar](12) NULL,
	[ManagerName] [varchar](30) NULL,
	[ManagerPhone] [varchar](15) NULL,
	[ManagerFax] [varchar](20) NULL,
	[ManagerEmail] [varchar](60) NULL,
	[Filename] [varchar](60) NULL,
	[CashAreaCode] [varchar](12) NULL,
	[UserProfileCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[BudgetCentreCode] [varchar](12) NULL,
	[JobCode] [varchar](12) NULL,
	[AwardCode] [varchar](12) NULL,
	[RateCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[Dim2ID] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Dim3]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Dim3](
	[Dim3Code] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[ManagerEmployeeCode] [varchar](12) NULL,
	[AssistantEmployeeCode] [varchar](12) NULL,
	[ManagerName] [varchar](30) NULL,
	[ManagerPhone] [varchar](15) NULL,
	[ManagerFax] [varchar](20) NULL,
	[ManagerEmail] [varchar](60) NULL,
	[Filename] [varchar](60) NULL,
	[CashAreaCode] [varchar](12) NULL,
	[UserProfileCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[BudgetCentreCode] [varchar](12) NULL,
	[JobCode] [varchar](12) NULL,
	[AwardCode] [varchar](12) NULL,
	[RateCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[Dim3ID] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Employee]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Employee](
	[EmployeeCode] [varchar](12) NULL,
	[LastName] [varchar](100) NULL,
	[FirstNames] [varchar](100) NULL,
	[Gender] [varchar](6) NULL,
	[BirthDate] [datetime] NULL,
	[BirthCertSighted] [bit] NULL,
	[PreferredName] [varchar](30) NULL,
	[PreviousName] [varchar](30) NULL,
	[Title] [varchar](12) NULL,
	[MaritalStatus] [varchar](8) NULL,
	[NationalityCode] [varchar](12) NULL,
	[EthnicityCode] [varchar](12) NULL,
	[SubEthnicGroupCode] [varchar](12) NULL,
	[Sort] [varchar](6) NULL,
	[Address1] [varchar](30) NULL,
	[Address2] [varchar](30) NULL,
	[Address3] [varchar](30) NULL,
	[Address4] [varchar](30) NULL,
	[PostCode] [varchar](8) NULL,
	[State] [varchar](3) NULL,
	[CountryCode] [varchar](12) NULL,
	[LicenceClass] [varchar](15) NULL,
	[LicenceCountry] [varchar](12) NULL,
	[HomePhone] [varchar](16) NULL,
	[WorkPhone] [varchar](16) NULL,
	[MobilePhone] [varchar](16) NULL,
	[Fax] [varchar](16) NULL,
	[Email] [varchar](60) NULL,
	[WorkEmail] [varchar](60) NULL,
	[Pager] [varchar](16) NULL,
	[PositionCode] [varchar](12) NULL,
	[WorkAreaCode] [varchar](12) NULL,
	[LocationCode] [varchar](12) NULL,
	[DepartmentCode] [varchar](12) NULL,
	[PayPeriodCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[Dim1Code] [varchar](12) NULL,
	[Dim2Code] [varchar](12) NULL,
	[Dim3Code] [varchar](12) NULL,
	[Dim4Code] [varchar](12) NULL,
	[RosterPeriodCode] [varchar](12) NULL,
	[HolidayGroupCode] [varchar](12) NULL,
	[ShiftCode] [varchar](12) NULL,
	[BreakCode] [varchar](12) NULL,
	[AvailabilityGroupCode] [varchar](12) NULL,
	[ClockCard1] [varchar](25) NULL,
	[ClockCard2] [varchar](25) NULL,
	[ClockCard3] [varchar](25) NULL,
	[UsesClocks] [bit] NULL,
	[ClockProcessedDate] [datetime] NULL,
	[PIN] [varchar](4) NULL,
	[AnchorGroupCode] [varchar](12) NULL,
	[PRExport] [bit] NULL,
	[ContractCode] [varchar](12) NULL,
	[AwardCode] [varchar](12) NULL,
	[AwardStartDate] [datetime] NULL,
	[AwardEndDate] [datetime] NULL,
	[AwardUnits] [numeric](12, 2) NULL,
	[MaximumAwardCode] [varchar](12) NULL,
	[UnionCode] [varchar](12) NULL,
	[EmployeeStatusCode] [varchar](12) NULL,
	[EmployeeClass] [varchar](20) NULL,
	[Apprentice] [bit] NULL,
	[Salary] [numeric](11, 2) NULL,
	[RateCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[StartDate] [datetime] NULL,
	[CommencementDate] [datetime] NULL,
	[AnniversaryDate] [datetime] NULL,
	[ReviewDate] [datetime] NULL,
	[TerminationDate] [datetime] NULL,
	[TermReasonCode] [varchar](12) NULL,
	[PlannedTerminationDate] [datetime] NULL,
	[ParentLeave] [bit] NULL,
	[ParentLvStartDate] [datetime] NULL,
	[ParentLvEndDate] [datetime] NULL,
	[RetirementDate] [datetime] NULL,
	[ReplacementRequired] [bit] NULL,
	[WouldReEmploy] [bit] NULL,
	[ExitIntSent] [bit] NULL,
	[ExitIntRcvd] [bit] NULL,
	[CertificateOfService] [bit] NULL,
	[RecruitmentCentreCode] [varchar](12) NULL,
	[RedundancyAgreementCode] [varchar](12) NULL,
	[HoursSunday] [numeric](5, 2) NULL,
	[HoursMonday] [numeric](5, 2) NULL,
	[HoursTuesday] [numeric](5, 2) NULL,
	[HoursWednesday] [numeric](5, 2) NULL,
	[HoursThursday] [numeric](5, 2) NULL,
	[HoursFriday] [numeric](5, 2) NULL,
	[HoursSaturday] [numeric](5, 2) NULL,
	[TotalProfiledHours] [numeric](11, 2) NULL,
	[TotalNonZeroDays] [int] NULL,
	[PayType] [varchar](8) NULL,
	[PayMethod] [varchar](13) NULL,
	[RoundPayments] [bit] NULL,
	[AutoPay] [bit] NULL,
	[AutoPaySuppDate] [datetime] NULL,
	[CashAmount] [numeric](11, 2) NULL,
	[PrintPayFlag] [bit] NULL,
	[LastOverpayment] [numeric](11, 2) NULL,
	[BankAccount] [varchar](16) NULL,
	[BankReference] [varchar](18) NULL,
	[BankCode] [varchar](12) NULL,
	[BankParticulars] [varchar](12) NULL,
	[YTDTaxableA] [numeric](11, 2) NULL,
	[YTDPreTaxD] [numeric](11, 2) NULL,
	[YTDPAYE] [numeric](11, 2) NULL,
	[YTDNonTaxableA] [numeric](11, 2) NULL,
	[YTDAfterTaxDisb] [numeric](11, 2) NULL,
	[YTDNonPayingA] [numeric](11, 2) NULL,
	[YTDEmployeeSuper] [numeric](11, 2) NULL,
	[YTDEmployerSuper] [numeric](11, 2) NULL,
	[YTDLumpSumA] [numeric](11, 2) NULL,
	[YTDLumpSumB] [numeric](11, 2) NULL,
	[YTDLumpSumC] [numeric](11, 2) NULL,
	[YTDLumpSumD] [numeric](11, 2) NULL,
	[YTDLumpSumE] [numeric](11, 2) NULL,
	[YTDLumpSumN] [numeric](11, 2) NULL,
	[YTDLumpSumP] [numeric](11, 2) NULL,
	[YTDPre83] [numeric](11, 2) NULL,
	[YTDPost83] [numeric](11, 2) NULL,
	[YTDPostJune94] [numeric](11, 2) NULL,
	[PayDate] [datetime] NULL,
	[DeathBenefit] [bit] NULL,
	[DeathBenefitType] [varchar](1) NULL,
	[YTDLeaveLoading] [numeric](11, 2) NULL,
	[YTDFBT] [numeric](11, 2) NULL,
	[LastPaid] [datetime] NULL,
	[LastNettAmount] [numeric](11, 2) NULL,
	[LastALPaid] [datetime] NULL,
	[LastSLPaid] [datetime] NULL,
	[ApprenticeHours] [numeric](8, 2) NULL,
	[CareerHours] [numeric](8, 2) NULL,
	[CompanyHours] [numeric](8, 2) NULL,
	[TaxNumber] [varchar](16) NULL,
	[TaxCode] [varchar](7) NULL,
	[TaxRate] [numeric](6, 2) NULL,
	[PrintEMS] [bit] NULL,
	[ExemptEP] [bit] NULL,
	[ACCCode] [varchar](12) NULL,
	[DependentRebate] [bit] NULL,
	[ZoneRebate] [varchar](1) NULL,
	[HECSDebt] [bit] NULL,
	[StudentDebt] [varchar](7) NULL,
	[RebateTotals] [numeric](9, 2) NULL,
	[GroupCertPrinted] [bit] NULL,
	[SuperAuthorised] [bit] NULL,
	[DeclarationDate] [datetime] NULL,
	[QuestionSpouse] [bit] NULL,
	[QuestionWeeklyIncome] [bit] NULL,
	[QuestionDependentChildren] [bit] NULL,
	[DependentChildren] [int] NULL,
	[ALTableCode] [varchar](12) NULL,
	[ALStartDate] [datetime] NULL,
	[ALEndDate] [datetime] NULL,
	[SLTableCode] [varchar](12) NULL,
	[SLStartDate] [datetime] NULL,
	[SLEndDate] [datetime] NULL,
	[LSTableCode] [varchar](12) NULL,
	[LSStartDate] [datetime] NULL,
	[LSEndDate] [datetime] NULL,
	[LSDaysAdjusted] [int] NULL,
	[LCTableCode] [varchar](12) NULL,
	[LCStartDate] [datetime] NULL,
	[LCEndDate] [datetime] NULL,
	[ALTotalUnits] [numeric](11, 4) NULL,
	[ALHoursYTD] [numeric](9, 2) NULL,
	[ALDaysYTD] [numeric](9, 2) NULL,
	[ALWeeksYTD] [numeric](9, 2) NULL,
	[ALQualHours] [numeric](9, 2) NULL,
	[ALFTEHours] [numeric](9, 2) NULL,
	[ALGross] [numeric](11, 2) NULL,
	[ALGrossAccrued] [numeric](11, 2) NULL,
	[ALPaidAdvance] [numeric](11, 2) NULL,
	[ALOverdue] [numeric](11, 2) NULL,
	[ALLoading] [numeric](11, 2) NULL,
	[ALAbsentWeeks] [numeric](6, 2) NULL,
	[ALAbsentValue] [numeric](11, 2) NULL,
	[ALOutstand] [numeric](11, 2) NULL,
	[ALAccrued] [numeric](11, 4) NULL,
	[ALAccruedPerPay] [numeric](11, 4) NULL,
	[ALAdvance] [numeric](11, 2) NULL,
	[ALOutstandLiable] [numeric](11, 2) NULL,
	[ALAccruedLiable] [numeric](11, 2) NULL,
	[ALLiability] [numeric](11, 2) NULL,
	[ALOutstandRateCode] [varchar](12) NULL,
	[ALAccruedRateCode] [varchar](12) NULL,
	[ALOutstandRate] [numeric](11, 4) NULL,
	[ALAccruedRate] [numeric](11, 4) NULL,
	[ALOutstandPre93] [numeric](11, 2) NULL,
	[ALOutstand1Rate] [numeric](11, 4) NULL,
	[ALOutstand1Units] [numeric](11, 2) NULL,
	[ALOutstand1UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand2Rate] [numeric](11, 4) NULL,
	[ALOutstand2Units] [numeric](11, 2) NULL,
	[ALOutstand2UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand3Rate] [numeric](11, 4) NULL,
	[ALOutstand3Units] [numeric](11, 2) NULL,
	[ALOutstand3UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand4Rate] [numeric](11, 4) NULL,
	[ALOutstand4Units] [numeric](11, 2) NULL,
	[ALOutstand4UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand5Rate] [numeric](11, 4) NULL,
	[ALOutstand5Units] [numeric](11, 2) NULL,
	[ALOutstand5UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand6Rate] [numeric](11, 4) NULL,
	[ALOutstand6Units] [numeric](11, 2) NULL,
	[ALOutstand6UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand7Rate] [numeric](11, 4) NULL,
	[ALOutstand7Units] [numeric](11, 2) NULL,
	[ALOutstand7UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand8Rate] [numeric](11, 4) NULL,
	[ALOutstand8Units] [numeric](11, 2) NULL,
	[ALOutstand8UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstand9Rate] [numeric](11, 4) NULL,
	[ALOutstand9Units] [numeric](11, 2) NULL,
	[ALOutstand9UnitsUsed] [numeric](11, 2) NULL,
	[ALOutstandARate] [numeric](11, 4) NULL,
	[ALOutstandAUnits] [numeric](11, 2) NULL,
	[ALOutstandAUnitsUsed] [numeric](11, 2) NULL,
	[ALOutstandBRate] [numeric](11, 4) NULL,
	[ALOutstandBUnits] [numeric](11, 2) NULL,
	[ALOutstandBUnitsUsed] [numeric](11, 2) NULL,
	[ALOutstandCRate] [numeric](11, 4) NULL,
	[ALOutstandCUnits] [numeric](11, 2) NULL,
	[ALOutstandCUnitsUsed] [numeric](11, 2) NULL,
	[ALLastYearAvgHourlyRate] [numeric](11, 4) NULL,
	[ALLastYearAvgDailyRate] [numeric](11, 4) NULL,
	[ALLastYearAvgWeeklyRate] [numeric](11, 4) NULL,
	[FourthWeek] [bit] NULL,
	[ALFGrossAccrued] [numeric](11, 2) NULL,
	[ALFPaidAdvance] [numeric](11, 2) NULL,
	[ALFOverdue] [numeric](11, 2) NULL,
	[ALFOutstand] [numeric](11, 2) NULL,
	[ALFTotalUnits] [numeric](11, 4) NULL,
	[ALFAccrued] [numeric](11, 4) NULL,
	[ALFAccruedPerPay] [numeric](11, 4) NULL,
	[ALFAdvance] [numeric](11, 2) NULL,
	[ALFOutstandLiable] [numeric](11, 2) NULL,
	[ALFAccruedLiable] [numeric](11, 2) NULL,
	[ALFLiability] [numeric](11, 2) NULL,
	[ALFOutstandRateCode] [varchar](12) NULL,
	[ALFAccruedRateCode] [varchar](12) NULL,
	[ALFOutstandRate] [numeric](11, 4) NULL,
	[ALFAccruedRate] [numeric](11, 4) NULL,
	[ALFOutstand1Rate] [numeric](11, 4) NULL,
	[ALFOutstand1Units] [numeric](11, 2) NULL,
	[ALFOutstand1UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand2Rate] [numeric](11, 4) NULL,
	[ALFOutstand2Units] [numeric](11, 2) NULL,
	[ALFOutstand2UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand3Rate] [numeric](11, 4) NULL,
	[ALFOutstand3Units] [numeric](11, 2) NULL,
	[ALFOutstand3UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand4Rate] [numeric](11, 4) NULL,
	[ALFOutstand4Units] [numeric](11, 2) NULL,
	[ALFOutstand4UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand5Rate] [numeric](11, 4) NULL,
	[ALFOutstand5Units] [numeric](11, 2) NULL,
	[ALFOutstand5UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand6Rate] [numeric](11, 4) NULL,
	[ALFOutstand6Units] [numeric](11, 2) NULL,
	[ALFOutstand6UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand7Rate] [numeric](11, 4) NULL,
	[ALFOutstand7Units] [numeric](11, 2) NULL,
	[ALFOutstand7UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand8Rate] [numeric](11, 4) NULL,
	[ALFOutstand8Units] [numeric](11, 2) NULL,
	[ALFOutstand8UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstand9Rate] [numeric](11, 4) NULL,
	[ALFOutstand9Units] [numeric](11, 2) NULL,
	[ALFOutstand9UnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstandARate] [numeric](11, 4) NULL,
	[ALFOutstandAUnits] [numeric](11, 2) NULL,
	[ALFOutstandAUnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstandBRate] [numeric](11, 4) NULL,
	[ALFOutstandBUnits] [numeric](11, 2) NULL,
	[ALFOutstandBUnitsUsed] [numeric](11, 2) NULL,
	[ALFOutstandCRate] [numeric](11, 4) NULL,
	[ALFOutstandCUnits] [numeric](11, 2) NULL,
	[ALFOutstandCUnitsUsed] [numeric](11, 2) NULL,
	[ALAccruedParental] [bit] NULL,
	[ALOutstand1Parental] [bit] NULL,
	[ALOutstand2Parental] [bit] NULL,
	[ALOutstand3Parental] [bit] NULL,
	[ALOutstand4Parental] [bit] NULL,
	[ALOutstand5Parental] [bit] NULL,
	[ALOutstand6Parental] [bit] NULL,
	[ALOutstand7Parental] [bit] NULL,
	[ALOutstand8Parental] [bit] NULL,
	[ALOutstand9Parental] [bit] NULL,
	[ALOutstandAParental] [bit] NULL,
	[ALOutstandBParental] [bit] NULL,
	[ALOutstandCParental] [bit] NULL,
	[ALFOutstand1Parental] [bit] NULL,
	[ALFOutstand2Parental] [bit] NULL,
	[ALFOutstand3Parental] [bit] NULL,
	[ALFOutstand4Parental] [bit] NULL,
	[ALFOutstand5Parental] [bit] NULL,
	[ALFOutstand6Parental] [bit] NULL,
	[ALFOutstand7Parental] [bit] NULL,
	[ALFOutstand8Parental] [bit] NULL,
	[ALFOutstand9Parental] [bit] NULL,
	[ALFOutstandAParental] [bit] NULL,
	[ALFOutstandBParental] [bit] NULL,
	[ALFOutstandCParental] [bit] NULL,
	[SLCycleEndDate] [datetime] NULL,
	[SLHoursCTD] [numeric](9, 2) NULL,
	[SLHoursYTD] [numeric](9, 2) NULL,
	[SLDaysYTD] [numeric](9, 2) NULL,
	[SLWeeksYTD] [numeric](9, 2) NULL,
	[SLOutstand] [numeric](11, 4) NULL,
	[SLAccrued] [numeric](11, 4) NULL,
	[SLOutstandLiable] [numeric](11, 2) NULL,
	[SLAccruedLiable] [numeric](11, 2) NULL,
	[SLLiability] [numeric](11, 2) NULL,
	[SLTotalUnits] [numeric](11, 4) NULL,
	[SLAdvance] [numeric](11, 4) NULL,
	[SLOutstandRateCode] [varchar](12) NULL,
	[SLAccruedRateCode] [varchar](12) NULL,
	[SLOutstandRate] [numeric](11, 4) NULL,
	[SLAccruedRate] [numeric](11, 4) NULL,
	[LSTotalUnits] [numeric](11, 4) NULL,
	[LSAccruedMtd] [numeric](11, 4) NULL,
	[LSHoursMtd] [numeric](11, 4) NULL,
	[LSMtdDate] [datetime] NULL,
	[LSOutstand] [numeric](11, 4) NULL,
	[LSOutstandPre78] [numeric](11, 4) NULL,
	[LSOutstandPre93] [numeric](11, 4) NULL,
	[LSAccrued] [numeric](11, 4) NULL,
	[LSAccruedReversed] [numeric](11, 4) NULL,
	[LSAccruedToBeReversed] [numeric](11, 4) NULL,
	[LastEligiblePay] [datetime] NULL,
	[LSAccruedPre78] [numeric](11, 4) NULL,
	[LSAccruedPre93] [numeric](11, 4) NULL,
	[LSAdvance] [numeric](11, 4) NULL,
	[LSOutstandLiable] [numeric](11, 2) NULL,
	[LSAccruedLiable] [numeric](11, 2) NULL,
	[LSLiability] [numeric](11, 2) NULL,
	[PrevYear] [int] NULL,
	[PrevMonth] [int] NULL,
	[PrevHrsWk] [numeric](8, 4) NULL,
	[LSOutstandRateCode] [varchar](12) NULL,
	[LSAccruedRateCode] [varchar](12) NULL,
	[LSOutstandRate] [numeric](11, 4) NULL,
	[LSAccruedRate] [numeric](11, 4) NULL,
	[AvgWorkedHoursPerWeek] [numeric](11, 4) NULL,
	[LeaveCreditLiable] [numeric](11, 2) NULL,
	[ORD] [datetime] NULL,
	[NSRank] [varchar](10) NULL,
	[NSStatus] [varchar](10) NULL,
	[NSServiceType] [varchar](10) NULL,
	[SAFAwards] [text] NULL,
	[ReligionCode] [varchar](12) NULL,
	[MarriageDate] [datetime] NULL,
	[SecurityNumber] [varchar](12) NULL,
	[CountryOfBirthCode] [varchar](12) NULL,
	[BloodType] [varchar](5) NULL,
	[NRICType] [varchar](20) NULL,
	[IdentityCardNumber] [varchar](12) NULL,
	[PassportNumber] [varchar](12) NULL,
	[ProvidentFundAccountNumber] [varchar](12) NULL,
	[PassportCountryCode] [varchar](12) NULL,
	[PassportIssueDate] [datetime] NULL,
	[PassportExpiryDate] [datetime] NULL,
	[ForeignID] [varchar](12) NULL,
	[EmploymentPassNumber] [varchar](12) NULL,
	[EmploymentPassIssueDate] [datetime] NULL,
	[EmploymentPassExpiryDate] [datetime] NULL,
	[WorkPermitNumber] [varchar](25) NULL,
	[WorkPermitIssueDate] [datetime] NULL,
	[WorkPermitExpiryDate] [datetime] NULL,
	[PRApprovalDate] [datetime] NULL,
	[ForeignWorkerType] [varchar](40) NULL,
	[ProvidentFundCode] [varchar](12) NULL,
	[OverrideFundContribution] [bit] NULL,
	[OvertimeFlag] [bit] NULL,
	[PermAddress1] [varchar](30) NULL,
	[PermAddress2] [varchar](30) NULL,
	[PermAddress3] [varchar](30) NULL,
	[PermAddress4] [varchar](30) NULL,
	[PermPostCode] [varchar](6) NULL,
	[PermCountryCode] [varchar](12) NULL,
	[BenefitsInKindFlag] [bit] NULL,
	[WebPassword] [varchar](60) NULL,
	[MyPayGlobalProfileCode] [varchar](12) NULL,
	[NICTableLetter] [varchar](1) NULL,
	[Director] [bit] NULL,
	[DeductStudentLoan] [bit] NULL,
	[Week1Month1] [bit] NULL,
	[TradeDispute] [bit] NULL,
	[StopTaxRefund] [bit] NULL,
	[Week53] [varchar](2) NULL,
	[TaxWeekDirectorAppointed] [int] NULL,
	[PreviousEmploymentGrossPay] [numeric](11, 2) NULL,
	[PreviousEmploymentTax] [numeric](11, 2) NULL,
	[LastPaidPeriodNumber] [int] NULL,
	[AppropriatePensionScheme] [bit] NULL,
	[CalculateNIAnnualBasis] [bit] NULL,
	[PensionSchemeCode] [varchar](12) NULL,
	[EQQnrCode] [varchar](12) NULL,
	[EQReasonCode] [varchar](12) NULL,
	[RecordVersion] [int] NULL,
	[ExportEmployeeCode] [varchar](12) NULL,
	[EmployeeNIOnlyScheme] [bit] NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[XACECER] [bit] NULL,
	[XPOST2CODE] [varchar](12) NULL,
	[XPOST3CODE] [varchar](12) NULL,
	[EmployeeID] [int] NOT NULL,
	[ACName] [varchar](30) NULL,
	[YTDNonPayingANotTaxed] [numeric](11, 2) NULL,
	[YTDOLDNonPayingA] [numeric](11, 2) NULL,
	[FijiUpgradedAllowsDate] [datetime] NULL,
	[JobCode] [varchar](12) NULL,
	[EffProportionType] [varchar](21) NULL,
	[EffTransPay] [bit] NULL,
	[DisableFringeBenefit] [bit] NULL,
	[DisableFringeBenefitFrom] [datetime] NULL,
	[DisableFringeBenefitTo] [datetime] NULL,
	[IgnorePBIPeriodCapTestUntil] [datetime] NULL,
	[IgnorePBIAnnualCapTestUntil] [datetime] NULL,
	[CalcFBOnTermination] [bit] NULL,
	[CalcFBForManualPays] [bit] NULL,
	[SSCWTRate] [numeric](6, 2) NULL,
	[UpdateSSCWT] [bit] NULL,
	[YTDKiwiSaverEmployerSuper] [numeric](11, 2) NULL,
	[YTDKiwiSaverEmployeeSuper] [numeric](11, 2) NULL,
	[XSTANDARDHRS] [varchar](5) NULL,
	[XTRANSFER] [bit] NULL,
	[NewEntrantException] [varchar](25) NULL,
	[ATOCorrespondenceDate] [datetime] NULL,
	[FinalPayUponDeath] [numeric](11, 2) NULL,
	[NewEntrantStartDate] [datetime] NULL,
	[NewEntrantHours] [numeric](8, 2) NULL,
	[MinimumWageExempt] [varchar](13) NULL,
	[MinimumWageExemptReason] [varchar](12) NULL,
	[NewEntrantMonthsPrevEmployer] [numeric](10, 6) NULL,
	[NewEntrantHoursPrevEmployer] [numeric](8, 2) NULL,
	[PermState] [varchar](3) NULL,
	[UsePostalAddressAsResidential] [bit] NULL,
	[XROSTER] [varchar](33) NULL,
	[XACESSLVL] [varchar](33) NULL,
	[XAWARD] [varchar](33) NULL,
	[ResidencyStatus] [varchar](12) NULL,
	[YTDTaxCredit] [numeric](11, 2) NULL,
	[X52WKAVG] [numeric](12, 4) NULL,
	[X4WKREL] [numeric](12, 4) NULL,
	[SchoolChild] [bit] NULL,
	[YTDSuperSalarySacrifice] [numeric](11, 2) NULL,
	[YTDRESC] [numeric](11, 2) NULL,
	[ALMaxPayoutUnits] [numeric](6, 2) NULL,
	[ALPayoutPaid] [numeric](11, 2) NULL,
	[ALPayoutUnitsTaken] [numeric](6, 2) NULL,
	[ALPayoutBalance] [numeric](11, 2) NULL,
	[ALPayoutUnitsBalance] [numeric](6, 2) NULL,
	[XAVGHRSWRK] [numeric](12, 2) NULL,
	[ExemptFloodLevy] [bit] NULL,
	[XCONNECT] [numeric](9, 0) NULL,
	[XEYTDUNION] [numeric](11, 2) NULL,
	[XCONNECTYTD] [numeric](9, 0) NULL,
	[XEALTBAL] [numeric](11, 2) NULL,
	[XELOCATION] [varchar](30) NULL,
	[XEAVGHRS] [numeric](11, 2) NULL,
	[XEHRGP] [varchar](12) NULL,
	[XEHRINSRVC] [varchar](12) NULL,
	[XEHRHCA] [varchar](12) NULL,
	[XEHRAPRDATE] [datetime] NULL,
	[XEHRCOMPHCA] [varchar](12) NULL,
	[XWORKPERMIT] [varchar](20) NULL,
	[XERTINC] [numeric](11, 2) NULL,
	[XEHRSSUSRNME] [varchar](30) NULL,
	[XENETIDCODE] [varchar](30) NULL,
	[XEUSERID] [varchar](30) NULL,
	[PreviousEmploymentYTDCode] [varchar](12) NULL,
	[XNSN] [int] NULL,
	[XTOPUPENT] [varchar](3) NULL,
	[XTOPUPDATE1] [datetime] NULL,
	[XTOPUPDATE2] [datetime] NULL,
	[XTOPUP1PAY] [numeric](12, 2) NULL,
	[XTOPUP2PAY] [numeric](12, 2) NULL,
	[XTOPCOM] [varchar](150) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Location]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Location](
	[LocationCode] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[ManagerEmployeeCode] [varchar](12) NULL,
	[AssistantEmployeeCode] [varchar](12) NULL,
	[ManagerName] [varchar](62) NULL,
	[ManagerPhone] [varchar](15) NULL,
	[ManagerMobilePhone] [varchar](15) NULL,
	[ManagerPager] [varchar](15) NULL,
	[ManagerFax] [varchar](20) NULL,
	[ManagerEmail] [varchar](60) NULL,
	[Filename] [varchar](60) NULL,
	[CashAreaCode] [varchar](12) NULL,
	[UserProfileCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[BudgetCentreCode] [varchar](12) NULL,
	[JobCode] [varchar](12) NULL,
	[AwardCode] [varchar](12) NULL,
	[RateCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[LocationID] [int] NOT NULL,
	[ContactPersonEmployeeCode] [varchar](12) NULL,
	[ContactPersonName] [varchar](130) NULL,
	[ContactPersonPositionDesc] [varchar](30) NULL,
	[ContactPhone] [varchar](16) NULL,
	[ContactEmail] [varchar](60) NULL,
	[Address1] [varchar](30) NULL,
	[Address2] [varchar](30) NULL,
	[Suburb] [varchar](30) NULL,
	[CityTown] [varchar](30) NULL,
	[PostCode] [varchar](4) NULL,
	[State] [varchar](3) NULL,
	[XLOCACTIVE] [bit] NULL,
	[XLREPTEMAIL] [varchar](120) NULL,
	[XLGLCODE] [varchar](12) NULL,
	[XADDRESS1] [varchar](50) NULL,
	[XADDRESS2] [varchar](50) NULL,
	[XADDRESS3] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Position]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Position](
	[PositionCode] [varchar](12) NULL,
	[Description] [varchar](30) NULL,
	[CostPerFTE] [numeric](9, 2) NULL,
	[EmployeeCode] [varchar](12) NULL,
	[PositionClassificationCode] [varchar](12) NULL,
	[PositionGroupCode] [varchar](12) NULL,
	[ContractCode] [varchar](12) NULL,
	[AppraisalTypeCode] [varchar](12) NULL,
	[DepartmentCode] [varchar](12) NULL,
	[CostCentreCode] [varchar](12) NULL,
	[BudgetCentreCode] [varchar](12) NULL,
	[JobCode] [varchar](12) NULL,
	[AwardCode] [varchar](12) NULL,
	[RateCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[MinSkillMatch] [numeric](5, 4) NULL,
	[ParentCode] [varchar](12) NULL,
	[Notes] [text] NULL,
	[PositionID] [int] NOT NULL,
	[XPOSTEXP] [datetime] NULL,
	[XPOSNZACA] [varchar](50) NULL,
	[XPOSTION] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Trans]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Trans](
	[EmployeeCode] [varchar](12) NULL,
	[PaySequence] [int] NULL,
	[StartDate] [datetime] NULL,
	[Date] [datetime] NULL,
	[AllowanceCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[TotalAmount] [numeric](11, 2) NULL,
	[FTEHours] [numeric](11, 2) NULL,
	[Quantity] [numeric](9, 2) NULL,
	[Company] [nvarchar](50) NULL,
	[Facility] [nvarchar](50) NULL,
	[Account] [nvarchar](50) NULL,
	[Commodity] [nvarchar](50) NULL,
	[Analysis] [nvarchar](50) NULL,
	[LocationCode] [varchar](12) NULL,
	[PositionCode] [varchar](12) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_PG_Trans_2015]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_PG_Trans_2015](
	[EmployeeCode] [varchar](12) NULL,
	[PaySequence] [int] NULL,
	[StartDate] [datetime] NULL,
	[Date] [datetime] NULL,
	[AllowanceCode] [varchar](12) NULL,
	[RateAmount] [numeric](11, 4) NULL,
	[Factor] [numeric](7, 4) NULL,
	[TotalAmount] [numeric](11, 2) NULL,
	[FTEHours] [numeric](11, 2) NULL,
	[Quantity] [numeric](9, 2) NULL,
	[Company] [nvarchar](50) NULL,
	[Facility] [nvarchar](50) NULL,
	[Account] [nvarchar](50) NULL,
	[Commodity] [nvarchar](50) NULL,
	[Analysis] [nvarchar](50) NULL,
	[LocationCode] [varchar](12) NULL,
	[PositionCode] [varchar](12) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_TT_Department]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_TT_Department](
	[DepartmentID] [varchar](50) NOT NULL,
	[DepartmentName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_TT_Employee]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_TT_Employee](
	[UID] [varchar](50) NOT NULL,
	[EmployeeCode] [varchar](50) NULL,
	[EmployeeName] [varchar](50) NULL,
	[FPC] [varchar](50) NULL,
	[Live] [varchar](1) NULL,
	[DefaultLocationID] [varchar](4) NULL,
	[DefaultDepartment] [varchar](50) NULL,
	[DefaultRole] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_TT_Location]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_TT_Location](
	[LocationId] [varchar](4) NOT NULL,
	[LocationName] [varchar](100) NULL,
	[GroupID] [varchar](50) NOT NULL,
	[RegionCode] [varchar](50) NULL,
	[FacilityID] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_TT_Roles]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_TT_Roles](
	[RoleID] [varchar](50) NOT NULL,
	[RoleName] [varchar](60) NULL,
	[Live] [varchar](1) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_TT_ShiftType]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_TT_ShiftType](
	[ShiftID] [varchar](50) NOT NULL,
	[ShiftName] [varchar](50) NULL,
	[IsNormalType] [bit] NULL,
	[IsAttendedType] [bit] NULL,
	[IsLeaveType] [bit] NULL,
	[IsRequestable] [bit] NULL,
	[IsUnPaid] [bit] NOT NULL,
	[IsAccrualType] [bit] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_TT_Timesheet]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_TT_Timesheet](
	[ShiftType] [varchar](50) NULL,
	[Department] [varchar](50) NULL,
	[Role] [varchar](50) NULL,
	[LocationID] [varchar](4) NULL,
	[Date] [datetime] NULL,
	[Employee] [varchar](50) NULL,
	[AuthorisedHours] [decimal](18, 8) NULL,
	[AuthorisedBreakhours] [decimal](18, 8) NULL,
	[Nethours] [decimal](18, 8) NULL,
	[TotalCost] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SOURCE_TT_Timesheet_SUM]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SOURCE_TT_Timesheet_SUM](
	[DIMENSION] [varchar](3) NULL,
	[Date] [datetime] NULL,
	[NET_Costs] [float] NULL,
	[Net_Hrs] [decimal](14, 6) NULL,
	[TOT_Costs] [float] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SubsidyStatus]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubsidyStatus](
	[SubsidyStatus] [tinyint] NULL,
	[SubsidyDescription] [nvarchar](20) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeName] [nvarchar](50) NOT NULL,
	[EmployeeEmail] [nvarchar](50) NOT NULL,
	[TravelDate] [datetime] NOT NULL,
	[TravelReason] [nvarchar](50) NOT NULL,
	[TravelNote] [nvarchar](255) NULL,
	[ApprovalEmail] [nvarchar](50) NOT NULL,
	[EmployeePhone] [nvarchar](20) NOT NULL,
	[Company] [nvarchar](10) NOT NULL,
	[Facility] [nvarchar](20) NOT NULL,
	[RequestStatus] [nvarchar](10) NULL,
	[EditedBy] [nvarchar](50) NULL,
	[EditedOn] [datetime] NULL,
 CONSTRAINT [PK_TravelRequest] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_ApprovalManager]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_ApprovalManager](
	[ID] [tinyint] NOT NULL,
	[FullName] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](50) NOT NULL,
	[Facility] [nvarchar](10) NULL,
	[Company] [nvarchar](10) NULL,
 CONSTRAINT [PK_TravelRequest_ApprovalManager] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_City]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_City](
	[City] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_TravelRequest_City] PRIMARY KEY CLUSTERED 
(
	[City] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_Company]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_Company](
	[CompanyCode] [nvarchar](10) NOT NULL,
	[CompanyName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_TravelRequest_Company] PRIMARY KEY CLUSTERED 
(
	[CompanyCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_EmailNote]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_EmailNote](
	[TravelRequestID] [int] NOT NULL,
	[EmailNote] [nvarchar](max) NULL,
 CONSTRAINT [PK_TravelRequest_EmailNote] PRIMARY KEY CLUSTERED 
(
	[TravelRequestID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_Facility]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_Facility](
	[DIMENSION] [nvarchar](20) NOT NULL,
	[NAME] [nvarchar](50) NULL,
	[DHB] [nvarchar](50) NULL,
	[Region] [nvarchar](15) NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL,
	[CompanyCode] [nvarchar](10) NOT NULL,
	[ApprovalManager] [nvarchar](50) NULL,
 CONSTRAINT [PK_TravelRequest_Facility] PRIMARY KEY CLUSTERED 
(
	[DIMENSION] ASC,
	[CompanyCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_Iti_Type]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_Iti_Type](
	[Iti_Type] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_TravelRequest_Iti_Type] PRIMARY KEY CLUSTERED 
(
	[Iti_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_Itinerary]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_Itinerary](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TravelRequestID] [int] NOT NULL,
	[ItineraryType] [nvarchar](10) NOT NULL,
	[CityDeparture] [nvarchar](50) NOT NULL,
	[DateDeparture] [datetime] NOT NULL,
	[CityArrival] [nvarchar](50) NULL,
	[DateArrival] [datetime] NULL,
	[Luggage] [nvarchar](50) NOT NULL,
	[ItinararyNote] [nvarchar](255) NULL,
	[EditedBy] [nvarchar](50) NULL,
	[EditedOn] [datetime] NULL,
	[DepartureOn] [nvarchar](50) NULL,
	[ArrivalOn] [nvarchar](50) NULL,
 CONSTRAINT [PK_TravelRequest_Itinarary] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_Luggage]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_Luggage](
	[Options] [nvarchar](50) NOT NULL,
	[Iti_Type] [nvarchar](10) NULL,
 CONSTRAINT [PK_TravelRequest_Luggage] PRIMARY KEY CLUSTERED 
(
	[Options] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_ReasonCode]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_ReasonCode](
	[TravelReasonCode] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_TravelRequest_ReasonCode] PRIMARY KEY CLUSTERED 
(
	[TravelReasonCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TravelRequest_Status]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TravelRequest_Status](
	[ID] [tinyint] NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_TravelRequest_Status] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[v_Dim_AX_Facility]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  *****
AND (F.RVREGIONID <> '*SOLD')*/
CREATE VIEW [dbo].[v_Dim_AX_Facility]
AS
SELECT        LTRIM(F.FACILITYID) AS FacilityID, F.NAME, F.FACILITYTYPEID, F.DIMENSION, F.ADDRESS, F.STREET, F.ZIPCODE, F.CITY, F.COUNTY, F.COUNTRY, F.RACSNAME AS DHB, F.RVREGIONID AS Region, M.Latitude, 
                         M.Longitude
FROM            dbo.SOURCE_AX_Facility AS F INNER JOIN
                         dbo.FacilityMap AS M ON LTRIM(F.FACILITYID) = M.[Facility No ]
WHERE        (F.DATAAREAID = 'virt')

GO
/****** Object:  View [dbo].[v_Dim_AX_Dimension0]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_AX_Dimension0]
AS
SELECT        DIMENSION, MIN(NAME) AS NAME, MIN(DHB) AS DHB, MIN(Region) AS Region, MIN(Latitude) AS Latitude, MIN(Longitude) AS Longitude
FROM            dbo.v_Dim_AX_Facility
GROUP BY DIMENSION
UNION
SELECT        '130' DIMENSION, 'zzzCare Support' NAME, 'zzzCare Support', 'Support Office', - 36.847772, 174.750697
UNION
SELECT        '001S' DIMENSION, 'Support Office' NAME, 'Support Office', 'Support Office', - 36.847772, 174.750697
UNION
SELECT        '120T' DIMENSION, 'Training Centre - Wesley' NAME, 'Training Centre - Wesley', 'Support Office', - 36.847772, 174.750697

GO
/****** Object:  View [dbo].[v_Dim_0_Facility]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[v_Dim_0_Facility]
AS
SELECT        dbo.SOURCE_AX_Dimensions.NUM, dbo.SOURCE_AX_Dimensions.DESCRIPTION + ' (' + dbo.SOURCE_AX_Dimensions.NUM + ')' AS Facility, FD.Cluster_Executive, D.NAME, D.DHB, D.Region, D.Latitude, 
                         D.Longitude
FROM            dbo.SOURCE_AX_Dimensions LEFT OUTER JOIN
                         [DDB460-20\I460_01].Oceania_Reporting.dbo.Facility_Details AS FD ON dbo.SOURCE_AX_Dimensions.NUM = FD.Facility_Code LEFT OUTER JOIN
                         dbo.v_Dim_AX_Dimension0 AS D ON dbo.SOURCE_AX_Dimensions.NUM = D.DIMENSION
WHERE        (dbo.SOURCE_AX_Dimensions.DIMENSIONCODE = 0) AND (dbo.SOURCE_AX_Dimensions.DATAAREAID = 'virt')

GO
/****** Object:  View [dbo].[v_Dim_Employee]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_Employee]
AS
SELECT        EmployeeCode, ISNULL(Gender, 'N/A') AS Gender, ISNULL(BirthDate, '1900-01-01') AS BirthDate, dbo.fn_GetAgeAsToday(ISNULL(BirthDate, '1900-01-01')) AS Age, ISNULL(Address4, 'N/A') AS City, PositionCode, 
                         LocationCode, DepartmentCode, PayPeriodCode, CostCentreCode, Dim1Code AS BusinessArea, Dim2Code AS Region, Dim3Code AS Area, ISNULL(HolidayGroupCode, 'N/A') AS HolidayGroupCode, ContractCode, 
                         ISNULL(EmployeeStatusCode, 'N/A') AS EmployeeStatusCode, ISNULL(UnionCode, 'N/A') AS UnionCode, ISNULL(Salary, 0) AS Salary, RateAmount, StartDate, YEAR(StartDate) AS HireYear, MONTH(StartDate) 
                         AS HireMonth, CASE WHEN TerminationDate <> '1900-01-01' THEN CASE WHEN DATEDIFF(D, StartDate, TerminationDate) <= 90 THEN 'Y' ELSE 'N' END ELSE 'N' END AS BadHire, ISNULL(TerminationDate, 
                         '2099-12-31 00:00:00.000') AS TerminationDate, YEAR(ISNULL(TerminationDate, '1900-01-01')) AS TerminationYear, MONTH(ISNULL(TerminationDate, '1900-01-01')) AS TerminationMonth, 
                         CASE WHEN TerminationDate IS NULL THEN 'N' ELSE 'Y' END AS Terminated, ISNULL(TermReasonCode, 'N/A') AS TermReasonCode, ISNULL(ParentLvStartDate, '1900-01-01') AS ParentLvStartDate, 
                         ISNULL(ParentLvEndDate, '1900-01-01') AS ParentLvEndDate, PayType, PayMethod, TaxCode, ISNULL(StudentDebt, 'N/A') AS StudentDebt, ISNULL(ALGross, 0) AS ALGross, ISNULL(ALGrossAccrued, 0) 
                         AS ALGrossAccrued, ISNULL(ALPaidAdvance, 0) AS ALPaidAdvance, ALOutstandLiable, ALLiability, ALOutstandRate, ALAccruedRate, ALOutstand, ISNULL(ALAccrued, 0) AS ALAccrued, ALTotalUnits, SLTotalUnits, 
                         SLLiability, SLOutstandRate, ISNULL(SLOutstand, 0) AS SLOutstand, ISNULL(SLAccrued, 0) AS SLAccrued, ISNULL(X52WKAVG, 0) AS X52WKAVG, ISNULL(X4WKREL, 0) AS X4WKREL, ISNULL(XELOCATION, 'N/A') 
                         AS XELOCATION, XEAVGHRS, ISNULL(AvgWorkedHoursPerWeek, 0) AS AvgWorkedHoursPerWeek, XEALTBAL AS AltBal, FirstNames, LastName, ISNULL(XWORKPERMIT, 'PERMANENT') AS WorkPermit, 
                         ISNULL(WorkPermitExpiryDate, '2099-01-01') AS VisaExpiryDate, ISNULL(PlannedTerminationDate, '2099-01-01') AS ContractExpiryDate, dbo.fn_GetAgeBucketAsToday(ISNULL(BirthDate, '1900-01-01')) 
                         AS AgeBucket
FROM            dbo.SOURCE_PG_Employee AS E

GO
/****** Object:  View [dbo].[v_Fact_EmployeeXXX]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Fact_EmployeeXXX]
as
SELECT        EmployeeCode, Gender, BirthDate, Age, PositionCode, LocationCode, DepartmentCode, PayPeriodCode, CostCentreCode, BusinessArea, Region, Area, HolidayGroupCode, ContractCode, EmployeeStatusCode, 
                         UnionCode, StartDate, BadHire, TerminationDate, TermReasonCode, TaxCode, ALTotalUnits, SLTotalUnits, 1 [Flow], 'IN' [FlowCode], StartDate [BusinessDate]
FROM            v_Dim_Employee
UNION
SELECT        EmployeeCode, Gender, BirthDate, Age, PositionCode, LocationCode, DepartmentCode, PayPeriodCode, CostCentreCode, BusinessArea, Region, Area, HolidayGroupCode, ContractCode, EmployeeStatusCode, 
                         UnionCode, StartDate, BadHire, TerminationDate, TermReasonCode, TaxCode, ALTotalUnits, SLTotalUnits, -1 [Flow], 'OUT' [FlowCode], TerminationDate [BusinessDate]
FROM            v_Dim_Employee WHERE TerminationDate<>'1900-01-01 00:00:00.000'
GO
/****** Object:  View [dbo].[v_Fact_Employee1]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Fact_Employee1]
AS
SELECT        EmployeeCode, Gender, BirthDate, Age, PositionCode, LocationCode, DepartmentCode, PayPeriodCode, CostCentreCode, BusinessArea, Region, Area, HolidayGroupCode, ContractCode, 
                         CASE EmployeeStatusCode WHEN 'FULL' THEN 'FullTime' WHEN 'PART' THEN 'PartTime' WHEN 'CASUAL' THEN 'Casual' WHEN 'TEMPFULL' THEN 'FULLTIME' WHEN 'TEMPPART' THEN 'PARTTIME' ELSE 'OTHER'
                          END AS EmployeeStatusCode, UnionCode, StartDate, BadHire, CASE TerminationDate WHEN '1900-01-01 00:00:00.000' THEN '2099-12-31 00:00:00.000' ELSE TerminationDate END AS TerminationDate, 
                         TermReasonCode, TaxCode, ALTotalUnits AS ALHours, SLTotalUnits AS SLDays, CASE Terminated WHEN 'Y' THEN 0 ELSE 1 END AS [Current], ALOutstand, AltBal, XEAVGHRS, FirstNames, LastName, 
                         CASE TerminationDate WHEN '1900-01-01 00:00:00.000' THEN DATEDIFF(day, StartDate, GetDate()) ELSE DATEDIFF(day, StartDate, TerminationDate) END AS Tenure, AgeBucket
FROM            dbo.v_Dim_Employee

GO
/****** Object:  View [dbo].[v_Fact_AccommodationHistory1]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*select * from dbo.v_Fact_AccommodationHistory order by 1, 6*/
CREATE VIEW [dbo].[v_Fact_AccommodationHistory1]
AS
SELECT        H_1.CUSTACCOUNT, H_1.ACTIVE, CASE WHEN F.ACCOMMODATIONHISTORYID IS NULL THEN 0 ELSE 1 END AS FirstEntry, H_1.FacilityID, H_1.AccommodationID, H_1.EntryDate, 
                         CASE WHEN H_1.BILLINGCEASEDATE = '1900-01-01 00:00:00.000' AND 
                         H_1.DepartureDate = '1900-01-01 00:00:00.000' THEN '2099-01-01 00:00:00.000' WHEN H_1.BILLINGCEASEDATE = '1900-01-01 00:00:00.000' AND 
                         H_1.DepartureDate <> '1900-01-01 00:00:00.000' THEN DATEADD(DAY, - 1, H_1.DepartureDate) ELSE DATEADD(DAY, - 1, H_1.BILLINGCEASEDATE) END AS RecordDate, H_1.DepartureDate, 
                         H_1.SUBSIDYCEASEDATE, H_1.BILLINGCEASEDATE, CASE WHEN LEN(H_1.REASONFORLEAVINGID) 
                         = 0 THEN 'N/A' WHEN H_1.REASONFORLEAVINGID = 'Other' THEN 'N/A' ELSE H_1.REASONFORLEAVINGID END AS REASONFORLEAVINGID, H_1.ACCOMMODATIONHISTORYID, H_1.RESIDENTTYPEID, 
                         H_1.DIMENSION, H_1.MOVEMENTTYPE, H_1.SUBSIDYSTATUS, H_1.PPTCSLIVEARRANGEMENTID
FROM            (SELECT        CUSTACCOUNT, ACTIVE, LTRIM(FACILITYID) AS FacilityID, LTRIM(RTRIM(ACCOMMODATIONID)) AS AccommodationID, ENTRYDATE AS EntryDate, DEPARTUREDATE AS DepartureDate, 
                                                    SUBSIDYCEASEDATE, BILLINGCEASEDATE, SETTLEMENTDATE, PREADMITDATE, REASONFORLEAVINGID, ACCOMMODATIONHISTORYID, BEDID, VACANCYDATE, RESIDENTTYPEID, 
                                                    RESIDENTBONDSID, DIMENSION, CUSTGROUPID, MOVEMENTTYPE, PARTNERED, CUSTACCOUNTPARTNER, TRANSFERDATE, TERMNOTIFYDATE, LICEXPIRYDATE, COMPANY, SUBSIDYSTATUS, 
                                                    DATAAREAID, OVERRIDESTDPROPOSALS, EXCLUDEFROMPROPOSALS, PPTCSLIVEARRANGEMENTID
                          FROM            dbo.SOURCE_AX_AccommodationHistory AS H
                          WHERE        (DATAAREAID = 'virt') AND (ENTRYDATE <> DEPARTUREDATE) AND (EXCLUDEFROMPROPOSALS = 0)) AS H_1 LEFT OUTER JOIN
                             (SELECT        AH.CUSTACCOUNT, AH.ACCOMMODATIONHISTORYID
                               FROM            dbo.SOURCE_AX_AccommodationHistory AS AH INNER JOIN
                                                             (SELECT        CUSTACCOUNT, MIN(ENTRYDATE) AS No1_ENTRY
                                                               FROM            dbo.SOURCE_AX_AccommodationHistory
                                                               WHERE        (DATAAREAID = 'virt') AND (ENTRYDATE <> DEPARTUREDATE)
                                                               GROUP BY CUSTACCOUNT) AS E ON AH.CUSTACCOUNT = E.CUSTACCOUNT AND AH.ENTRYDATE = E.No1_ENTRY
                               WHERE        (AH.EXCLUDEFROMPROPOSALS = 0)) AS F ON H_1.ACCOMMODATIONHISTORYID = F.ACCOMMODATIONHISTORYID
WHERE        (H_1.RESIDENTTYPEID <> 'LEGACY') AND (H_1.DepartureDate = '1900-01-01 00:00:00.000' OR
                         H_1.DepartureDate > H_1.EntryDate) AND (H_1.DATAAREAID = 'virt')

GO
/****** Object:  View [dbo].[v_Fact_AccommodationHistory]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Fact_AccommodationHistory]
AS
/* this view is to consolidate the Resident Type*/ SELECT [CUSTACCOUNT], [ACTIVE], [FirstEntry], [FacilityID], [AccommodationID]
, [EntryDate],  [RecordDate],  [DepartureDate], [SUBSIDYCEASEDATE], [BILLINGCEASEDATE], 
                         [REASONFORLEAVINGID], [ACCOMMODATIONHISTORYID], A.[RESIDENTTYPEID] Old_ResidentType, [DIMENSION], [MOVEMENTTYPE], [SUBSIDYSTATUS], [PPTCSLIVEARRANGEMENTID] ResidentType, 
                         DATEDIFF(DAY, EntryDate, CASE RecordDate WHEN '2099-01-01 00:00:00.000' THEN GETDATE() ELSE RecordDate END) DaysPerAHN
FROM            [DW_OCEANIA].[dbo].[v_Fact_AccommodationHistory1] A INNER JOIN
                         ResidentType1 T ON A.RESIDENTTYPEID = T .RESIDENTTYPEID
WHERE        LEN([PPTCSLIVEARRANGEMENTID]) > 0
/* [PPTCSLIVEARRANGEMENTID] IN ('REST', 'HOS', 'DEM', 'ILU', 'RENT')*/ UNION
SELECT        [CUSTACCOUNT], [ACTIVE], [FirstEntry], [FacilityID], [AccommodationID]
, [EntryDate],  [RecordDate],  [DepartureDate], [SUBSIDYCEASEDATE], [BILLINGCEASEDATE], [REASONFORLEAVINGID], 
                         [ACCOMMODATIONHISTORYID], A.[RESIDENTTYPEID] Old_ResidentType, [DIMENSION], [MOVEMENTTYPE], [SUBSIDYSTATUS], NewResidentType ResidentType, DATEDIFF(DAY, EntryDate, 
                         CASE RecordDate WHEN '2099-01-01 00:00:00.000' THEN GETDATE() ELSE RecordDate END) DaysPerAHN
FROM            [DW_OCEANIA].[dbo].[v_Fact_AccommodationHistory1] A INNER JOIN
                         ResidentType1 T ON A.RESIDENTTYPEID = T .RESIDENTTYPEID
WHERE        LEN([PPTCSLIVEARRANGEMENTID]) = 0

/*, DATEADD(HOUR, -12, [EntryDate]) [EntryDate], DATEADD(HOUR, -12, [RecordDate]) [RecordDate], DATEADD(HOUR, -12, [DepartureDate]) [DepartureDate]*/

GO
/****** Object:  View [dbo].[v_DIM_AX_ResasonLeaving]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[v_DIM_AX_ResasonLeaving]
as
SELECT DISTINCT
      [REASONFORLEAVINGID]

  FROM [DW_OCEANIA].[dbo].[v_Fact_AccommodationHistory]
GO
/****** Object:  View [dbo].[v_Dim_PG_Union]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_PG_Union]
AS
SELECT DISTINCT UnionCode
FROM            dbo.v_Fact_Employee1
WHERE        ([Current] = 1) AND (UnionCode <> 'N/A')

GO
/****** Object:  View [dbo].[v_Dim_PG_EmployeeStatus]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_PG_EmployeeStatus]
as
 SELECT DISTINCT EmployeeStatusCode
FROM [dbo].[v_Fact_Employee1]
GO
/****** Object:  View [dbo].[v_Dim_1_Commodity]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[v_Dim_1_Commodity]
AS
SELECT        NUM, DESCRIPTION AS Facility
FROM            dbo.SOURCE_AX_Dimensions
WHERE        (DIMENSIONCODE = 1) AND (DATAAREAID = 'virt')
UNION
SELECT 'NA' NUM, 'Not Available' AS Facility

GO
/****** Object:  View [dbo].[v_Dim_2_Analysis]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[v_Dim_2_Analysis]
AS
SELECT        NUM, DESCRIPTION [Analysis]
FROM            dbo.SOURCE_AX_Dimensions
WHERE        (DIMENSIONCODE = 2) AND (DATAAREAID = 'virt')
UNION
SELECT  'NA' NUM, 'Not Available' [Analysis]

GO
/****** Object:  View [dbo].[v_Dim_AX_Accommodation]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_AX_Accommodation]
AS
SELECT  LTRIM([FACILITYID]) FacilityID
		, LEFT( LTRIM([FACILITYID]),3) Dimension
		, SUBSTRING(LTRIM([FACILITYID]),4,1) FacilityType
      ,LTRIM([ACCOMMODATIONID]) AccommodationID
      ,[DESCRIPTION] AccommodationDescription
      ,[BLOCKED] Blocked
      ,[ACCOMMODATIONTYPEID] AccommodationTypeID
      ,[SQUAREMETERS] Size
      ,[ACCOMMODATIONNAME] AccommodationName
      ,[RVSTATUS] RVStatus
      ,[SALEABLEDATE] SaleableDate
      ,[SALESTATUS] SalesStatus
  FROM [DW_OCEANIA].[dbo].[SOURCE_AX_ECL_Accommodation]
  WHERE [DATAAREAID]='virt'
GO
/****** Object:  View [dbo].[v_Dim_AX_Company]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE View [dbo].[v_Dim_AX_Company]
as
SELECT 'N/A' Company, 'Not Applicable' Company_Name
UNION
select DataAreaID Company, NAME Company_Name from [dbo].[SOURCE_AX_Company] WHERE LEN(NAME)>1 AND DataAreaID<>'ZZZ'




GO
/****** Object:  View [dbo].[v_Dim_AX_FacilityXXX]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[v_Dim_AX_FacilityXXX]
as
select LTRIM(FACILITYID) FACILITYID, NAME Facility_Name, FACILITYTYPEID, DIMENSION, STREET, ZIPCODE, CITY, COUNTY, STATE, COUNTRY, COUNTY+', '+CITY+', NEW ZEALAND' ADDRESS1,  RACSNAME DHB, RVREGIONID from [dbo].[SOURCE_AX_Facility] WHERE DATAAREAID='virt'
UNION 
select 'N/A', 'Not Applicable', 'N/A','N/A','N/A','N/A','N/A','N/A','N/A','N/A','AUCKLAND, NEW ZEALAND','N/A','N/A'


GO
/****** Object:  View [dbo].[v_Dim_AX_LedgerTable]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE View [dbo].[v_Dim_AX_LedgerTable]
as
SELECT 'N/A' LedgerAccount, 'Not Applicable' Account_Name
UNION
SELECT ACCOUNTNUM LedgerAccount, ACCOUNTNAME Account_Name FROM [dbo].[SOURCE_AX_LedgerTable] WHERE DATAAREAID='virt'




GO
/****** Object:  View [dbo].[v_Dim_HATB_Debtors]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_HATB_Debtors]
as
SELECT     ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY,   ACCOUNTNUM, DIMENSION, RVREGIONID, FACILITY, ARCHIVED, PAYMMODE, CREDITRATING, Resident_Type, DOB, Age, Entry_Date, Departure_Date, Daily_Rate, Record_Date, DHB, CUSTGROUP, 
                         LAST_PVT_PAYMENT_DATE, PVT_LAST_PMT, PVT_LAST_PAYMODE, MOH_LAST_PMT_DATE, MOH_LAST_PMT, Daily_PAC, Daily_Total_Subsidy, Outstanding_Private, Outstanding_MOH, Outstanding_WINZ, 
                         Outstanding_ACC, Total_Balance
FROM            [dbo].[Fact_HATB]
GO
/****** Object:  View [dbo].[v_Dim_HATB_Period]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_HATB_Period]
as
/****** used in Power BI for HATB  ******/
SELECT DISTINCT Record_Date [Month_End_Date], UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) [Period] FROM [dbo].[Fact_HATB]

GO
/****** Object:  View [dbo].[v_Dim_PG_Allwance]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_Dim_PG_Allwance] as 
SELECT AllowanceCode, Description AllowanceDescription, Type AllowanceType, Taxable, Calc, ISNULL(XALLEXP, '2099-01-01 00:00:00.000') ExpiredDate FROM dbo.SOURCE_PG_Allowance
GO
/****** Object:  View [dbo].[v_Dim_PG_Area]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE View [dbo].[v_Dim_PG_Area]
as
SELECT 'N/A' Area, 'Not Applicable' Area_Name
UNION
SELECT Dim3Code Area, Description Area_Name FROM dbo.SOURCE_PG_Dim3



GO
/****** Object:  View [dbo].[v_Dim_PG_BusinessArea]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE View [dbo].[v_Dim_PG_BusinessArea]
as
SELECT 'N/A' BusinessArea, 'Not Applicable' BusinessArea_Name
UNION
SELECT Dim1Code BusinessArea, Description BusinessArea_Name FROM dbo.SOURCE_PG_Dim1



GO
/****** Object:  View [dbo].[v_Dim_PG_CostCentre]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE View [dbo].[v_Dim_PG_CostCentre]
as
SELECT CostCentreCode, Description CostCentre_Description, GeneralLedgerCode,  [dbo].[fn_GetDelimitedValue](GeneralLedgerCode,1) Company, 
ISNULL([dbo].[fn_GetDelimitedValue](GeneralLedgerCode,2),'N/A') Facility, 
ISNULL([dbo].[fn_GetDelimitedValue](GeneralLedgerCode,3),'N/A') LedgerAccount, 
ISNULL([dbo].[fn_GetDelimitedValue](GeneralLedgerCode,5),'N/A') AnalysisCode, 
ISNULL(GeneralLedgerDesc, 'N/A') AS GeneralLedgerDesc, ISNULL(LocationCode, 'N/A') AS LocationCode, ISNULL(DepartmentCode, 'N/A') AS DepartmentCode, 
TotalAmount, TotalFTEHours, ISNULL(XCCDIM1CODE, 'N/A') AS BusinessArea, ISNULL(XCCDIM2CODE,'N/A') AS Region, ISNULL(XCCDIM3CODE,'N/A') Area FROM [dbo].[SOURCE_PG_CostCentre]
UNION
SELECT 'N/A', 'Not Applicable', 'N/A', 'N/A','N/A', 'N/A','N/A', 'N/A', 'N/A','N/A',0,0, 'N/A', 'N/A','N/A'


GO
/****** Object:  View [dbo].[v_Dim_PG_Department]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE View [dbo].[v_Dim_PG_Department]
as
SELECT 'N/A' DepartmentCode, 'Not Applicable' Department_Name
UNION
SELECT DepartmentCode, Description Department_Name FROM [dbo].[SOURCE_PG_Department]




GO
/****** Object:  View [dbo].[v_Dim_PG_Location]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE View [dbo].[v_Dim_PG_Location]
as
SELECT 'N/A' LocationCode, 'Not Applicable' Location_Name, null ManagerEmployeeCode, null ManagerName
UNION
SELECT LocationCode, Description Location_Name, ManagerEmployeeCode, ManagerName FROM [dbo].[SOURCE_PG_Location]




GO
/****** Object:  View [dbo].[v_Dim_PG_Position]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_PG_Position]
AS
SELECT        'N/A' PositionCode, 'Not Applicable' Position_Name, 'Not Applicable' Position_Group
UNION
SELECT        PositionCode, Description Position_Name, [XPOSNZACA] Position_Group
FROM            [dbo].[SOURCE_PG_Position]

GO
/****** Object:  View [dbo].[v_Dim_PG_Region]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE View [dbo].[v_Dim_PG_Region]
as
SELECT 'N/A' Region, 'Not Applicable' Region_Name
UNION
SELECT Dim2Code Region, Description Region_Name FROM dbo.SOURCE_PG_Dim2



GO
/****** Object:  View [dbo].[v_Dim_ResidentType]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Dim_ResidentType]
AS
SELECT DISTINCT NewResidentType AS ResidentType
FROM            dbo.ResidentType1

GO
/****** Object:  View [dbo].[v_Fact_Budget]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_Fact_Budget]
AS
SELECT        Calendar_Date, Facility, 'Effective' EBA, 'REST' ResidentType, Effective_RH Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Effective' EBA, 'DEM' ResidentType, Effective_DM Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Effective' EBA, 'HOS' ResidentType, Effective_HP Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Budget' EBA, 'REST' ResidentType, Budget_RH Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Budget' EBA, 'DEM' ResidentType, Budget_DM Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Budget' EBA, 'HOS' ResidentType, Budget_HP Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Actual' EBA, 'REST' ResidentType, Actual_RH Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Actual' EBA, 'DEM' ResidentType, Actual_DM Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)
UNION
SELECT        Calendar_Date, Facility, 'Actual' EBA, 'HOS' ResidentType, Actual_HP Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)

UNION
SELECT        Calendar_Date, Facility, 'Budget' EBA, 'PACS' ResidentType, Budget_PACS Quantity
FROM            [DDB460-20\I460_01].[Oceania_Reporting].[dbo].[Dates] D INNER JOIN
                         [DDB460-20\I460_01].[Oceania_Reporting].dbo.Budget B ON D .Calendar_Month = MONTH(B.Date) AND D .Calendar_Year = YEAR(B.Date)

GO
/****** Object:  View [dbo].[v_Fact_HATB_Amounts]    Script Date: 16/07/2018 11:49:37 a.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_Fact_HATB_Amounts]
as
SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'PVT' Funding_Type
		, 0 Ageing_Buckets
		, PVT_AGEING_0 Amount
 FROM [dbo].[Fact_HATB]
 UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'PVT' Funding_Type
		, 1 Ageing_Buckets
		, PVT_AGEING_1 Amount
 FROM [dbo].[Fact_HATB]
  UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'PVT' Funding_Type
		, 2 Ageing_Buckets
		, PVT_AGEING_2 Amount
 FROM [dbo].[Fact_HATB] 
 UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'PVT' Funding_Type
		, 3 Ageing_Buckets
		, PVT_AGEING_3 Amount
 FROM [dbo].[Fact_HATB] 
 UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'PVT' Funding_Type
		, 4 Ageing_Buckets
		, PVT_AGEING_4 Amount
 FROM [dbo].[Fact_HATB]
  UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'PVT' Funding_Type
		, 5 Ageing_Buckets
		, PVT_Licence Amount
 FROM [dbo].[Fact_HATB]
 UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'MOH' Funding_Type
		, 0 Ageing_Buckets
		, MOH_AGEING_0 Amount
 FROM [dbo].[Fact_HATB]
  UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'MOH' Funding_Type
		, 1 Ageing_Buckets
		, MOH_AGEING_1 Amount
 FROM [dbo].[Fact_HATB] UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'MOH' Funding_Type
		, 2 Ageing_Buckets
		, MOH_AGEING_2 Amount
 FROM [dbo].[Fact_HATB] UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'MOH' Funding_Type
		, 3 Ageing_Buckets
		, MOH_AGEING_3 Amount
 FROM [dbo].[Fact_HATB] UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'MOH' Funding_Type
		, 4 Ageing_Buckets
		, MOH_AGEING_4 Amount
 FROM [dbo].[Fact_HATB]

  UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'WINZ' Funding_Type
		, 0 Ageing_Buckets
		, WINZ_AGEING_0 Amount
 FROM [dbo].[Fact_HATB]
   UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'WINZ' Funding_Type
		, 1 Ageing_Buckets
		, WINZ_AGEING_1 Amount
 FROM [dbo].[Fact_HATB]  UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'WINZ' Funding_Type
		, 2 Ageing_Buckets
		, WINZ_AGEING_2 Amount
 FROM [dbo].[Fact_HATB]  UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'WINZ' Funding_Type
		, 3 Ageing_Buckets
		, WINZ_AGEING_3 Amount
 FROM [dbo].[Fact_HATB]  UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'WINZ' Funding_Type
		, 4 Ageing_Buckets
		, WINZ_AGEING_4 Amount
 FROM [dbo].[Fact_HATB]

   UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'ACC' Funding_Type
		, 0 Ageing_Buckets
		, ACC_AGEING_0 Amount
 FROM [dbo].[Fact_HATB]
   UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'ACC' Funding_Type
		, 1 Ageing_Buckets
		, ACC_AGEING_1 Amount
 FROM [dbo].[Fact_HATB]
    UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'ACC' Funding_Type
		, 2 Ageing_Buckets
		, ACC_AGEING_2 Amount
 FROM [dbo].[Fact_HATB]
    UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'ACC' Funding_Type
		, 3 Ageing_Buckets
		, ACC_AGEING_3 Amount
 FROM [dbo].[Fact_HATB]
    UNION
 SELECT ACCOUNTNUM+'-'+UPPER(LEFT(DATENAME(MONTH,Record_Date),3))+'-'+LTRIM(STR(YEAR(Record_Date))) ACCOUNT_KEY
		, 'ACC' Funding_Type
		, 4 Ageing_Buckets
		, ACC_AGEING_4 Amount
 FROM [dbo].[Fact_HATB]

GO
/****** Object:  Index [ClusteredIndex-20180312-200246]    Script Date: 16/07/2018 11:49:37 a.m. ******/
CREATE CLUSTERED INDEX [ClusteredIndex-20180312-200246] ON [dbo].[Images]
(
	[ImageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClustered-Date]    Script Date: 16/07/2018 11:49:37 a.m. ******/
CREATE NONCLUSTERED INDEX [NonClustered-Date] ON [dbo].[SOURCE_PG_Trans]
(
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-Date]    Script Date: 16/07/2018 11:49:37 a.m. ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-Date] ON [dbo].[SOURCE_TT_Timesheet_SUM]
(
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DayCare_Tran]  WITH CHECK ADD  CONSTRAINT [FK__DayCare_T__Cust___01D345B0] FOREIGN KEY([Cust_ID])
REFERENCES [dbo].[DayCare_Cust] ([ID])
GO
ALTER TABLE [dbo].[DayCare_Tran] CHECK CONSTRAINT [FK__DayCare_T__Cust___01D345B0]
GO
ALTER TABLE [dbo].[DayCare_User]  WITH CHECK ADD  CONSTRAINT [FK_UserType] FOREIGN KEY([UserType])
REFERENCES [dbo].[DayCare_UserType] ([UserType])
GO
ALTER TABLE [dbo].[DayCare_User] CHECK CONSTRAINT [FK_UserType]
GO
ALTER TABLE [dbo].[TravelRequest_Itinerary]  WITH CHECK ADD  CONSTRAINT [FK_TravelRequest_Itinerary_TravelRequest] FOREIGN KEY([TravelRequestID])
REFERENCES [dbo].[TravelRequest] ([ID])
GO
ALTER TABLE [dbo].[TravelRequest_Itinerary] CHECK CONSTRAINT [FK_TravelRequest_Itinerary_TravelRequest]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "SOURCE_AX_Dimensions"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 198
               Right = 268
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "FD"
            Begin Extent = 
               Top = 14
               Left = 533
               Bottom = 144
               Right = 713
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "D"
            Begin Extent = 
               Top = 6
               Left = 306
               Bottom = 136
               Right = 476
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_0_Facility'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_0_Facility'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "SOURCE_AX_Dimensions"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 268
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_1_Commodity'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_1_Commodity'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "SOURCE_AX_Dimensions"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 268
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_2_Analysis'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_2_Analysis'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_AX_Dimension0'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_AX_Dimension0'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "F"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 350
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "M"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_AX_Facility'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_AX_Facility'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[35] 4[21] 2[26] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "E"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 370
               Right = 303
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_Employee'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_Employee'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_PG_Position'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_PG_Position'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "v_Fact_Employee1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 239
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_PG_Union'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_PG_Union'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ResidentType1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 102
               Right = 222
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_ResidentType'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Dim_ResidentType'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[21] 4[31] 2[24] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_AccommodationHistory'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_AccommodationHistory'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[32] 4[12] 2[37] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "H_1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 294
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "F"
            Begin Extent = 
               Top = 27
               Left = 539
               Bottom = 123
               Right = 795
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 2850
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_AccommodationHistory1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_AccommodationHistory1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[11] 4[26] 2[44] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_Budget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_Budget'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "v_Dim_Employee"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 373
               Right = 267
            End
            DisplayFlags = 280
            TopColumn = 43
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_Employee1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_Fact_Employee1'
GO
USE [master]
GO
ALTER DATABASE [DW_OCEANIA] SET  READ_WRITE 
GO
