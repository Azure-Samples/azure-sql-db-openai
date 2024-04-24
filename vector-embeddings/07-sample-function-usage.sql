/*
    Test the function
*/
declare @e nvarchar(max);
declare @text nvarchar(max) = N'the foundation series by isaac asimov';

exec dbo.get_embedding 'embeddings', @text, @e output;

select * from dbo.SimilarContentArticles(@e) as r order by cosine_distance desc
go