/*
    Get the embeddings for the input text by calling the OpenAI API
*/
declare @inputText nvarchar(max) = 'the foundation series by isaac asimov';
declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max) = json_object('input': @inputText);
exec @retval = sp_invoke_external_rest_endpoint
    @url = 'https://dm-open-ai.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
    @method = 'POST',
    @headers = '{"api-key":"7194a8c183be4cd08c514834f4e985ea"}',
    @payload = @payload,
    @response = @response output;
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
    SUM(v1.[vector_value] * v2.[vector_value]) / 
        (
            SQRT(SUM(v1.[vector_value] * v1.[vector_value])) 
            * 
            SQRT(SUM(v2.[vector_value] * v2.[vector_value]))
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