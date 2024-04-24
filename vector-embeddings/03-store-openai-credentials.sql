/*
    Create database credentials to store API key
*/
if exists(select * from sys.[database_scoped_credentials] where name = 'https://<your-app-name>.openai.azure.com')
begin
	drop database scoped credential [https://<your-app-name>.openai.azure.com];
end
create database scoped credential [https://<your-app-name>.openai.azure.com]
with identity = 'HTTPEndpointHeaders', secret = '{"api-key": "<api-key>"}';
go