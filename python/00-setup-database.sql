drop table if exists dbo.sample_documents
go

create table dbo.sample_documents
(
    id int constraint pk__documents primary key,
    content nvarchar(max),
    embedding varbinary(8000)
)

if not exists(select * from sys.fulltext_catalogs where [name] = 'main_ft_catalog')
begin
    create fulltext catalog [main_ft_catalog] as default;
end
go

create fulltext index on dbo.sample_documents (content) key index pk__documents;
go

alter fulltext index on dbo.sample_documents enable; 
go
