/*
    Setup external model to allow embedding model usage
    Note: <deployment-id> needs to be replaced with the deployment name of your embedding model in Azure OpenAI
*/
if  exists(select * from sys.external_models where [name] = 'Ada2Embeddings')
begin
	drop external model [Ada2Embeddings];
end
go

create external model Ada2Embeddings
with ( 
    location = 'https://<your-api-name>.openai.azure.com/openai/deployments/<deployment-id>/embeddings?api-version=2023-05-15',
    credential = [https://<your-api-name>.openai.azure.com],
    api_format = 'Azure OpenAI',
    model_type = embeddings,
    model = 'embeddings'
);
go

select * from sys.external_models where [name] = 'Ada2Embeddings'
go
