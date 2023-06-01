/*
    Create database credentials to store API key
*/
if exists(select * from sys.[database_scoped_credentials] where name = 'https://<your-app-name>.openai.azure.com')
begin
	drop database scoped credential [https://<your-app-name>.openai.azure.com];
end
create database scoped credential [https://<your-app-name>.openai.azure.com]
with identity = 'HTTPEndpointHeaders', secret = '{"api-key": "<api-key>"}';
go

/*
    Get the embeddings for the input text by calling the OpenAI API
*/
declare @inputText nvarchar(max) = 'the foundation series by isaac asimov';
declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max) = json_object('input': @inputText);
exec @retval = sp_invoke_external_rest_endpoint
    @url = 'https://<your-app-name>.openai.azure.com/openai/deployments/<deployment-id>?api-version=2023-03-15-preview',
    @method = 'POST',
    @credential = [https://<your-app-name>.openai.azure.com],
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