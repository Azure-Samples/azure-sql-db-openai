drop table if exists dbo.hybrid_search_sample
go

create table dbo.hybrid_search_sample
(
    id int constraint pk__hybrid_search_sample primary key,
    content nvarchar(max),
    embedding vector(384)
)

if not exists(select * from sys.fulltext_catalogs where [name] = 'main_ft_catalog')
begin
    create fulltext catalog [main_ft_catalog] as default;
end
go

create fulltext index on dbo.hybrid_search_sample (content) key index pk__hybrid_search_sample;
go

alter fulltext index on dbo.hybrid_search_sample enable; 
go
