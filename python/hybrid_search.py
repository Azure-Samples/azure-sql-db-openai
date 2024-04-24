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
        'The bear is growling'
    ]
    model = SentenceTransformer('multi-qa-MiniLM-L6-cos-v1')
    embeddings = model.encode(sentences)

    print('Cleaning up the database...')
    try:
        conn = get_mssql_connection()
        conn.execute("DELETE FROM dbo.document_embeddings;")
        conn.execute("DELETE FROM dbo.documents;")
        conn.commit();        
    finally:
        conn.close()

    print('Saving documents and embeddings in the database...')    
    try:
        conn = get_mssql_connection()
        cursor = conn.cursor()  
        
        for content, embedding in zip(sentences, embeddings):
            cursor.execute(f"""
                INSERT INTO dbo.documents (content, embedding) VALUES (?, ?);
                INSERT INTO dbo.document_embeddings SELECT SCOPE_IDENTITY(), CAST([key] AS INT), CAST([value] AS FLOAT) FROM OPENJSON(?);
            """,
            content, 
            json.dumps(embedding.tolist()),
            json.dumps(embedding.tolist())
            )

        cursor.close()
        conn.commit()
    finally:
        conn.close()

    print('Searching for similar documents...')
    print('Getting embeddings...')    
    query = 'growling bear'
    embedding = model.encode(query)    
    
    print('Querying database...')  
    k = 5  
    try:
        conn = get_mssql_connection()
        cursor = conn.cursor()  
        
        results  = cursor.execute(f"""
            DECLARE @k INT = ?;
            WITH keyword_search AS (
                SELECT TOP(@k)
                    id,
                    ftt.[RANK] AS rank
                FROM 
                    dbo.documents 
                INNER JOIN 
                    FREETEXTTABLE(dbo.documents, *, ?) AS ftt ON dbo.documents.id = ftt.[KEY]
            ),
            semantic_search AS
            (
                SELECT 
                    id, 
                    rank        
                FROM 
                    dbo.similar_documents(?)
            )
            SELECT TOP(@k)
                COALESCE(ss.id, ks.id) AS id,
                COALESCE(1.0 / (@k + ss.rank), 0.0) +
                COALESCE(1.0 / (@k + ks.rank), 0.0) AS score -- Reciprocal Rank Fusion (RRF) 
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
            print('document:', row[0], 'RRF score:', row[1])

        cursor.close()
        conn.commit()
    finally:
        conn.close()