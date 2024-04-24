/*
    Extract the title vectors from the JSON and store them in a table
*/
drop table if exists dbo.wikipedia_articles_embeddings_titles_vector;
with cte as
(
    select 
        v.id as article_id,    
        cast(tv.[key] as int) as vector_value_id,
        cast(tv.[value] as float) as vector_value   
    from 
        [dbo].[wikipedia_articles_embeddings] as v
    cross apply 
        openjson(title_vector) tv
)
select
    article_id,
    vector_value_id,
    vector_value
into
    dbo.wikipedia_articles_embeddings_titles_vector
from
    cte;
go

/*
    Extract the content vectors from the JSON and store them in a table
*/
drop table if exists dbo.wikipedia_articles_embeddings_contents_vector;
with cte as
(
    select 
        v.id as article_id,    
        cast(tv.[key] as int) as vector_value_id,
        cast(tv.[value] as float) as vector_value   
    from 
        [dbo].[wikipedia_articles_embeddings] as v
    cross apply 
        openjson(content_vector) tv
)
select
    article_id,
    vector_value_id,
    vector_value
into
    dbo.wikipedia_articles_embeddings_contents_vector
from
    cte;
go

/*
    Create columnstores to support vector operations
*/
create clustered columnstore index ixc 
on dbo.wikipedia_articles_embeddings_titles_vector 
order (article_id)
go

create clustered columnstore index ixc 
on dbo.wikipedia_articles_embeddings_contents_vector 
order (article_id)
go
