/*
    Add columns to store the native vectors
*/
alter table wikipedia_articles_embeddings
add title_vector_ada2 vector(1536);

alter table wikipedia_articles_embeddings
add content_vector_ada2 vector(1536);
go

/*
    Update the native vectors
*/
update 
    wikipedia_articles_embeddings
set 
    title_vector_ada2 = cast(title_vector as vector(1536)),
    content_vector_ada2 = cast(content_vector as vector(1536))
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
	Verify data
*/
select top (10) * from [dbo].[wikipedia_articles_embeddings]
go

select * from [dbo].[wikipedia_articles_embeddings] where title = 'Alan Turing'
go
