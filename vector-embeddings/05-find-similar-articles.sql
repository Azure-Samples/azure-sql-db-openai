/*
    Get the embeddings for the input text by calling the OpenAI API
    and then search the most similar articles (by title)
    Note: <deployment-id> needs to be replaced with the deployment name of your embedding model in Azure OpenAI
*/

declare @inputText nvarchar(max) = 'the foundation series by isaac asimov';
declare @retval int, @embedding varbinary(8000);

exec @retval = dbo.get_embedding '<deployment-id>', @inputText, @embedding output;

select top(10)
    a.id,
    a.title,
    a.url,
    vector_distance('cosine', @embedding, title_vector_ada2) cosine_distance
from
    dbo.wikipedia_articles_embeddings a
order by
    cosine_distance;
go

