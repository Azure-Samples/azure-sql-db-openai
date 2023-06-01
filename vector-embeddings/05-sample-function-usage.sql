/*
    Test the function
*/
declare @response nvarchar(max);
declare @payload nvarchar(max) = json_object('input': 'the foundation series by isaac asimov');

exec sp_invoke_external_rest_endpoint
    @url = 'https://<your-app-name>.openai.azure.com/openai/deployments/embeddings/embeddings?api-version=2023-03-15-preview',
    @credential = [https://<your-app-name>.openai.azure.com],
    @payload = @payload,
    @response = @response output;

select * from dbo.SimilarContentArticles(json_query(@response, '$.result.data[0].embedding')) as r order by cosine_distance desc
go