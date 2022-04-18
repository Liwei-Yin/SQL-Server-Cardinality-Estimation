use AdventureWorks2019
go
IF exists(select 1 from sys.tables where name='SalesOrderDetail' and schema_id=schema_id('dbo'))
	drop table SalesOrderDetail
go
select * into SalesOrderDetail from [Sales].[SalesOrderDetail]
go
create statistics iProductID ON SalesOrderDetail(productid) with fullscan
Go
dbcc show_statistics(SalesOrderDetail,iProductID) with DENSITY_VECTOR
--All density   Average Length Columns
--------------- -------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--0.003759399   4              ProductID


---1.Variable
---SQL Server is not aware of the value passed to where caluse in compile stage, hence it will use the average selectivity(All Density) to calculate the estimated rows, rather than using the histogram.
---The estimated rows is :0.003759399*121317=456.079008483
DECLARE @pid INT = 799
SELECT * FROM SalesOrderDetail WHERE ProductID = @pid
go

---2.Group by
---Estiamted row:select 1/0.003759399=265.9999643560
select count(*),ProductID from SalesOrderDetail group by ProductID


---3.OPTIMIZE FOR UNKNOWN
---https://docs.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver15
--Instructs the Query Optimizer to use the average selectivity of the predicate across all column values instead of using the runtime parameter value when the query is compiled and optimized.
--If you use OPTIMIZE FOR @variable_name = literal_constant and OPTIMIZE FOR UNKNOWN in the same query hint, the Query Optimizer will use the literal_constant specified for a specific value. The Query Optimizer will use UNKNOWN for the rest of the variable values. The values are used only during query optimization, and not during query execution.
create or alter proc Proc_OPTIMIZE_FOR_UNKNOWN
@pid INT
as
SELECT * FROM SalesOrderDetail WHERE ProductID = @pid
option (OPTIMIZE FOR (@pid UNKNOWN))
GO
EXEC Proc_OPTIMIZE_FOR_UNKNOWN 799

go

----4.DISABLE_PARAMETER_SNIFFING
---https://docs.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver15
--Instructs Query Optimizer to use average data distribution while compiling a query with one or more parameters. This instruction makes the query plan independent on the parameter value that was first used when the query was compiled. This hint name is equivalent to trace flag 4136 or Database Scoped Configuration setting PARAMETER_SNIFFING = OFF.
create or alter proc Proc_DISABLE_PARAMETER_SNIFFING
@pid INT
as
SELECT * FROM SalesOrderDetail WHERE ProductID = @pid
option (use hint('DISABLE_PARAMETER_SNIFFING'))
GO
EXEC Proc_DISABLE_PARAMETER_SNIFFING 799
