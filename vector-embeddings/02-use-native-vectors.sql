/*
    Add columns to store the native vectors
*/
alter table wikipedia_articles_embeddings
add title_vector_native varbinary(8000);

alter table wikipedia_articles_embeddings
add content_vector_native varbinary(8000);

/*
    Update the native vectors
*/
update 
    wikipedia_articles_embeddings
set 
    title_vector_native = json_array_to_vector(title_vector),
    content_vector_native = json_array_to_vector(content_vector);
go

/*
    Remove old columns
*/
alter table wikipedia_articles_embeddings
drop column title_vector;
go

alter table wikipedia_articles_embeddings
drop column content_vector;
go

/*
    Rename the columns
*/
EXEC sp_rename 'dbo.wikipedia_articles_embeddings.title_vector_native', 'title_vector_ada2', 'COLUMN';
EXEC sp_rename 'dbo.wikipedia_articles_embeddings.content_vector_native', 'content_vector_ada2', 'COLUMN';

/*
	Verify data
*/
select top (100) * from [dbo].[wikipedia_articles_embeddings]
go

select * from [dbo].[wikipedia_articles_embeddings] where title = 'Alan Turing'
go
