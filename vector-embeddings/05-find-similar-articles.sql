/*
    Get the embeddings for the input text by calling the OpenAI API
    Note: <deployment-id> needs to be replaced with the deployment name of your embedding model in Azure OpenAI
*/
declare @inputText nvarchar(max) = 'the foundation series by isaac asimov';
declare @retval int, @response nvarchar(max);

exec @retval = dbo.get_embedding '<deployment-id>', @inputText, @response output;

drop table if exists #response;
select @response as [response] into #response;
select * from #response;
go


/*
    Extract the title vectors from the JSON and store them in a table
*/
declare @response nvarchar(max) = (select response from #response);
drop table if exists #t;
select 
    cast([key] as int) as [vector_value_id],
    cast([value] as float) as [vector_value]
into    
    #t
from 
    openjson(@response, '$.result.data[0].embedding')
go
select * from #t;
go

/* 
    Calculate cosine distance between the input text and all the articles
*/
drop table if exists #results;
select top(50)
    v2.article_id, 
    sum(v1.[vector_value] * v2.[vector_value]) / 
        (
            sqrt(sum(v1.[vector_value] * v1.[vector_value])) 
            * 
            sqrt(sum(v2.[vector_value] * v2.[vector_value]))
        ) as cosine_distance
into
    #results
from 
    #t v1
inner join 
    dbo.wikipedia_articles_embeddings_contents_vector v2 on v1.vector_value_id = v2.vector_value_id
group by
    v2.article_id
order by
    cosine_distance desc;

select 
    a.id,
    a.title,
    a.url,
    r.cosine_distance
from 
    #results r
inner join 
    dbo.wikipedia_articles_embeddings a on r.article_id = a.id
order by
    cosine_distance desc;
go


/* 
    Optimization: since vectors are normalized (as per OpenAI documentation: https://platform.openai.com/docs/guides/embeddings/which-distance-function-should-i-use),
    we can simplify the cosine distance calculation to a dot product
*/
drop table if exists #results;
select top(50)
    v2.article_id, 
    sum(v1.[vector_value] * v2.[vector_value]) as cosine_distance
into
    #results
from 
    #t v1
inner join 
    dbo.wikipedia_articles_embeddings_contents_vector v2 on v1.vector_value_id = v2.vector_value_id
group by
    v2.article_id
order by
    cosine_distance desc;

select 
    a.id,
    a.title,
    a.url,
    r.cosine_distance
from 
    #results r
inner join 
    dbo.wikipedia_articles_embeddings a on r.article_id = a.id
order by
    cosine_distance desc;
go