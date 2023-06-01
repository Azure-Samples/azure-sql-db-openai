/*
    Create a sample function to reuse code
*/
create or alter function dbo.SimilarContentArticles(@vector nvarchar(max))
returns table
as
return with cteVector as
(
    select 
        cast([key] as int) as [vector_value_id],
        cast([value] as float) as [vector_value]
    from 
        openjson(@vector)
),
cteSimilar as
(
select top (50)
    v2.article_id, 
    sum(v1.[vector_value] * v2.[vector_value]) / 
        (
            sqrt(sum(v1.[vector_value] * v1.[vector_value])) 
            * 
            sqrt(sum(v2.[vector_value] * v2.[vector_value]))
        ) as cosine_distance
from 
    cteVector v1
inner join 
    dbo.wikipedia_articles_embeddings_contents_vector v2 on v1.vector_value_id = v2.vector_value_id
group by
    v2.article_id
order by
    cosine_distance desc
)
select 
    a.id,
    a.title,
    a.url,
    r.cosine_distance
from 
    cteSimilar r
inner join 
    dbo.wikipedia_articles_embeddings a on r.article_id = a.id
go
