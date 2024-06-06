import os
import pyodbc
import logging
import json
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from utilities import get_mssql_connection

load_dotenv()

if __name__ == '__main__':
    print('Initializing sample...')
    print('Getting embeddings...')    
    sentences = [
        'The dog is barking',
        'The cat is purring',
        'The bear is growling',
        'A bear growling to a cat'
    ]
    model = SentenceTransformer('multi-qa-MiniLM-L6-cos-v1')
    embeddings = model.encode(sentences)

    conn = get_mssql_connection()

    print('Cleaning up the database...')
    try:
        cursor = conn.cursor()    
        cursor.execute("DELETE FROM dbo.sample_documents;")
        cursor.commit();        
    finally:
        cursor.close()

    print('Saving documents and embeddings in the database...')    
    try:
        cursor = conn.cursor()  
        
        for id, (content, embedding) in enumerate(zip(sentences, embeddings)):
            cursor.execute(f"""
                DECLARE @id INT = ?;
                DECLARE @content NVARCHAR(MAX) = ?;
                DECLARE @embedding NVARCHAR(MAX) = ?;
                INSERT INTO dbo.sample_documents (id, content, embedding) VALUES (@id, @content, JSON_ARRAY_TO_VECTOR(@embedding));
            """,
            id,
            content, 
            json.dumps(embedding.tolist())
            )

        cursor.commit()
    finally:
        cursor.close()

    print('Searching for similar documents...')
    print('Getting embeddings...')    
    query = 'a growling bear'
    embedding = model.encode(query)    
    
    print(f'Querying database for "{query}"...')  
    k = 5  
    try:
        cursor = conn.cursor()  
        
        results  = cursor.execute(f"""
            DECLARE @k INT = ?;
            DECLARE @q NVARCHAR(4000) = ?;
            DECLARE @e VARBINARY(8000) = JSON_ARRAY_TO_VECTOR(CAST(? AS NVARCHAR(MAX)));
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
                            dbo.sample_documents AS sd
                        INNER JOIN 
                            FREETEXTTABLE(dbo.sample_documents, *, @q) AS ftt ON sd.id = ftt.[KEY]
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
                            dbo.sample_documents
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

        for row in results:
            print(f'Document: "{row[2]}", Id: {row[0]} -> RRF score: {row[1]:0.4} (Semantic Rank: {row[3]}, Keyword Rank: {row[4]})')

    finally:
        cursor.close()
