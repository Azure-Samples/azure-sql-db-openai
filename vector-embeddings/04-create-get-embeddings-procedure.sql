/*
    Get the embeddings for the input text by calling the OpenAI API
*/
create or alter procedure dbo.get_embedding
@deployedModelName nvarchar(1000),
@inputText nvarchar(max),
@embedding nvarchar(max) output
as
declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max) = json_object('input': @inputText);
declare @url nvarchar(1000) = 'https://<your-app-name>.openai.azure.com/openai/deployments/' + @deployedModelName + '/embeddings?api-version=2023-03-15-preview'
exec @retval = sp_invoke_external_rest_endpoint
    @url = @url,
    @method = 'POST',
    @credential = [https://<your-app-name>],
    @payload = @payload,
    @response = @response output;

declare @re nvarchar(max) = '[]';
if (@retval = 0) begin
    set @re = json_query(@response, '$.result.data[0].embedding')
end

set @embedding = @re;

return @retval
go

