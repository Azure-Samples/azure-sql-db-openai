# Vector Similarity Search with Azure SQL & Azure OpenAI

This example shows how to use Azure OpenAI from Azure SQL database to get the vector embeddings of any choosen text, and then calculate the cosine distance against the Wikipedia articles (for which vector embeddings have been already calculated) to find the articles that covers topics that are close - or similar - to the searched text.

Azure SQL database can be used to significatly speed up vectors operations using column store indexes, so that search can have sub-seconds performances even on large datasets.

Download the [wikipedia embeedings from here](https://cdn.openai.com/API/examples/data/vector_database_wikipedia_articles_embedded.zip), unzip it and upload it to an Azure Blob Storage container.

