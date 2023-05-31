/*
	Cleanup if needed
*/
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
	create master key encryption by password = 'Pa$$w0rd!'
end
go
if exists(select * from sys.[external_data_sources] where name = 'openai_playground')
begin
	drop external data source [openai_playground];
end
go
if exists(select * from sys.[database_scoped_credentials] where name = 'openai_playground')
begin
	drop database scoped credential [openai_playground];
end
go

/*
	Create database scoped credential and external data source
*/
create database scoped credential [openai_playground]
with identity = 'SHARED ACCESS SIGNATURE',
secret = '<sas-token>'; -- make sure not to include the ? at the beginning
go
create external data source [openai_playground]
with 
( 
	type = blob_storage,
 	location = 'https://<account>.blob.core.windows.net/playground',
 	credential = [openai_playground]
);
go

/*
	Create table
*/
drop table if exists [dbo].[wikipedia_articles_embeddings];
create table [dbo].[wikipedia_articles_embeddings]
(
	[id] [int] not null,
	[url] [varchar](1000) not null,
	[title] [varchar](1000) not null,
	[text] [varchar](max) not null,
	[title_vector] [varchar](max) not null,
	[content_vector] [varchar](max) not null,
	[vector_id] [int] not null
)
go

/*
	Import data
*/
bulk insert dbo.[wikipedia_articles_embeddings]
from 'wikipedia/vector_database_wikipedia_articles_embedded.csv'
with (
	data_source = 'openai_playground',
    format = 'csv',
    firstrow = 2,
    codepage = '65001',
	fieldterminator = ',',
	rowterminator = '0x0a',
    fieldquote = '"',
    batchsize = 1000,
    tablock
)
go

/*
	Add primary key
*/
alter table [dbo].[wikipedia_articles_embeddings]
add constraint pk__wikipedia_articles_embeddings primary key nonclustered (id)
go

/*
	Verify data
*/
select top (100) * from [dbo].[wikipedia_articles_embeddings]
go


