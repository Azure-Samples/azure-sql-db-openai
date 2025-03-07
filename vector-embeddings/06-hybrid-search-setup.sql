if not exists(select * from sys.fulltext_catalogs where [name] = 'FullTextCatalog')
begin
    create fulltext catalog [FullTextCatalog] as default;
end
go

create fulltext index on dbo.wikipedia_articles_embeddings ([text]) key index pk__wikipedia_articles_embeddings;
go

alter fulltext index on dbo.wikipedia_articles_embeddings enable; 
go

select * from sys.fulltext_catalogs
go
