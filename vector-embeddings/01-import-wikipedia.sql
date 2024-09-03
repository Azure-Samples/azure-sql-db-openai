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
add constraint pk__wikipedia_articles_embeddings primary key clustered (id)
go

/*
	Add index on title
*/
create index [ix_title] on [dbo].[wikipedia_articles_embeddings](title)
go

/*
	Verify data
*/
select top (10) * from [dbo].[wikipedia_articles_embeddings]
go

select * from [dbo].[wikipedia_articles_embeddings] where title = 'Alan Turing'
go




