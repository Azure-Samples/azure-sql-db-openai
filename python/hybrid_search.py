import os
import time
import pyodbc
import logging
import json
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from utilities import get_mssql_connection

load_dotenv()

if __name__ == '__main__':
    print('Initializing sample...')
    model = SentenceTransformer('multi-qa-MiniLM-L6-cos-v1', tokenizer_kwargs={'clean_up_tokenization_spaces': True})

    print('Getting embeddings...')    
    sentences = [
        'The dog is barking',
        'The cat is purring',
        'The bear is growling',
        'A bear growling to a cat',
        'A cat purring to a dog',
        'A dog barking to a bear',
        'A bear growling to a dog',
        'A cat purring to a bear',
        'A wolf howling to a bear',
        'A bear growling to a wolf'
    ]
    embeddings = model.encode(sentences)

    conn = get_mssql_connection()

    print('Cleaning up the database...')
    try:
        cursor = conn.cursor()    
        cursor.execute("DELETE FROM dbo.hybrid_search_sample;")
        cursor.commit();        
    finally:
        cursor.close()

    print('Saving documents and embeddings in the database...')    
    try:
        cursor = conn.cursor()  
        
        for id, (sentence, embedding) in enumerate(zip(sentences, embeddings)):
            cursor.execute(f"""
                DECLARE @id INT = ?;
                DECLARE @content NVARCHAR(MAX) = ?;
                DECLARE @embedding VECTOR(384) = CAST(? AS VECTOR(384));
                INSERT INTO dbo.hybrid_search_sample (id, content, embedding) VALUES (@id, @content, @embedding);
            """,
            id,
            sentence, 
            json.dumps(embedding.tolist())
            )

        cursor.commit()
    finally:
        cursor.close()

    print('Waiting a few seconds to let fulltext index sync...')    
    time.sleep(3)

    print('Searching for similar documents...')
    print('Getting embeddings...')    
    query = 'a growling bear'
    embedding = model.encode(query)    
    
    k = 5  
    print(f'Querying database for {k} similar sentenct to "{query}"...')  
    try:
        cursor = conn.cursor()  
        
        results  = cursor.execute(f"""
            DECLARE @k INT = ?;
            DECLARE @q NVARCHAR(4000) = ?;
            DECLARE @e VECTOR(384) = CAST(? AS VECTOR(384));
            WITH keyword_search AS (
                SELECT TOP(@k)
                    id,
                    RANK() OVER (ORDER BY rank) AS rank,
                    content
                FROM
                    (
                        SELECT TOP(@k)
                            sd.id,
                            ftt.[RANK] AS rank,
                            sd.content
                        FROM 
                            dbo.hybrid_search_sample AS sd
                        INNER JOIN 
                            FREETEXTTABLE(dbo.hybrid_search_sample, *, @q) AS ftt ON sd.id = ftt.[KEY]
                        ORDER BY
                            rank DESC
                    ) AS t
                ORDER BY
                    rank
            ),
            semantic_search AS
            (
                SELECT TOP(@k)
                    id,
                    RANK() OVER (ORDER BY distance) AS rank,
                    content
                FROM
                    (
                        SELECT TOP(@k)
                            id, 
                            VECTOR_DISTANCE('cosine', embedding, @e) AS distance,
                            content
                        FROM 
                            dbo.hybrid_search_sample
                        ORDER BY
                            distance
                    ) AS t
                ORDER BY
                    rank
            )
            SELECT TOP(@k)
                COALESCE(ss.id, ks.id) AS id,
                COALESCE(1.0 / (@k + ss.rank), 0.0) +
                COALESCE(1.0 / (@k + ks.rank), 0.0) AS score, -- Reciprocal Rank Fusion (RRF)
                COALESCE(ss.content, ks.content) AS content,
                ss.rank AS semantic_rank,
                ks.rank AS keyword_rank
            FROM
                semantic_search ss
            FULL OUTER JOIN
                keyword_search ks ON ss.id = ks.id
            ORDER BY 
                score DESC
            """,
            k,
            query, 
            json.dumps(embedding.tolist()),        
        )

        for (pos, row) in enumerate(results):
            print(f'[{pos}] RRF score: {row[1]:0.4} (Semantic Rank: {row[3]}, Keyword Rank: {row[4]})\tDocument: "{row[2]}", Id: {row[0]}')

    finally:
        cursor.close()
    
    print("Done.")