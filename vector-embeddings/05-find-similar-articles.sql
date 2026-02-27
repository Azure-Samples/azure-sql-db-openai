/*
    Get the embeddings for the input text by calling the OpenAI API
    and then search the most similar articles (by title)
*/

declare @inputText nvarchar(max) = 'the foundation series by isaac asimov';
declare @embedding vector(1536);

set @embedding = ai_generate_embeddings(@inputText use model Ada2Embeddings)

select top(10)
    a.id,
    a.title,
    a.url,
    vector_distance('cosine', @embedding, title_vector_ada2) as cosine_distance
from
    dbo.wikipedia_articles_embeddings a
order by
    cosine_distance;
go

