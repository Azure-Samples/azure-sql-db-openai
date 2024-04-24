DROP TABLE IF EXISTS dbo.document_embeddings
DROP TABLE IF EXISTS dbo.documents
go

CREATE TABLE dbo.documents (id INT CONSTRAINT pk__documents PRIMARY KEY IDENTITY, content NVARCHAR(MAX), embedding NVARCHAR(MAX))
CREATE TABLE dbo.document_embeddings (id INT REFERENCES dbo.documents(id), vector_value_id INT, vector_value FLOAT)
go

CREATE CLUSTERED COLUMNSTORE INDEX csi__document_embeddings ON dbo.document_embeddings ORDER (id)
go

IF NOT EXISTS(SELECT * FROM sys.fulltext_catalogs WHERE [name] = 'FullTextCatalog')
BEGIN
    CREATE FULLTEXT CATALOG [FullTextCatalog] AS DEFAULT;
END
go

CREATE FULLTEXT INDEX ON dbo.documents (content) KEY INDEX pk__documents;
go

ALTER FULLTEXT INDEX ON dbo.documents ENABLE; 
go
