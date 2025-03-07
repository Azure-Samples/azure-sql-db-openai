/*
    Get the embeddings for the input text by calling the OpenAI API
    and then search the most similar articles (by title)
    Note: <deployment-id> needs to be replaced with the deployment name of your embedding model in Azure OpenAI
*/

DECLARE @q NVARCHAR(1000) = 'the foundation series by isaac asimov';
DECLARE @k INT = 10

DECLARE @r INT, @e VECTOR(1536);

EXEC @r = dbo.get_embedding '<deployment-id>', @q, @e OUTPUT;
IF (@r != 0) SELECT @r;

WITH keyword_search AS (
    SELECT TOP(@k)
        id, 
        RANK() OVER (ORDER BY ft_rank DESC) AS rank,
        title,
        [text]
    FROM
        (
            SELECT TOP(@k)
                id,
                ftt.[RANK] AS ft_rank,
                title,
                [text]
            FROM 
                dbo.wikipedia_articles_embeddings w
            INNER JOIN 
                FREETEXTTABLE(dbo.wikipedia_articles_embeddings, *, @q) AS ftt ON w.id = ftt.[KEY]
            ORDER BY
                ft_rank DESC
        ) AS freetext_documents
    ORDER BY
        rank ASC
),
semantic_search AS
(
    SELECT TOP(@k)
        id, 
        RANK() OVER (ORDER BY cosine_distance) AS rank
    FROM
        (
            SELECT 
                id, 
                VECTOR_DISTANCE('cosine', @e, content_vector_ada2) AS cosine_distance
            FROM 
                dbo.wikipedia_articles_embeddings w
        ) AS similar_documents
),
result AS (
    SELECT TOP(@k)
        COALESCE(ss.id, ks.id) AS id,
        ss.rank AS semantic_rank,
        ks.rank AS keyword_rank,
        COALESCE(1.0 / (@k + ss.rank), 0.0) +
        COALESCE(1.0 / (@k + ks.rank), 0.0) AS score -- Reciprocal Rank Fusion (RRF) 
    FROM
        semantic_search ss
    FULL OUTER JOIN
        keyword_search ks ON ss.id = ks.id
    ORDER BY 
        score DESC
)   
SELECT
    w.id,
    cast(score * 1000 as int) as rrf_score,
    rank() OVER(ORDER BY cast(score * 1000 AS INT) DESC) AS rrf_rank,
    semantic_rank,
    keyword_rank,
    w.title,
    w.[text]
FROM
    result AS r
INNER JOIN
    dbo.wikipedia_articles_embeddings AS w ON r.id = w.id
ORDER BY
    rrf_rank