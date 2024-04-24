# How to calculate common vectors distances in T-SQL

The sample data used to show how to calculate the common vector distances in T-SQL the following

```sql
declare @v1 nvarchar(max) = '[1,3,-5]';
declare @v2 nvarchar(max) = '[4,-2,-1]';

drop table if exists #v1;
select 
    cast([key] as int) as [vector_value_id], 
    cast([value] as float) as [vector_value]
into 
    #v1 
from
    openjson(@v1);

drop table if exists #v2;
select 
    cast([key] as int) as [vector_value_id], 
    cast([value] as float) as [vector_value]
into 
    #v2
from
    openjson(@v2);
```

## Cosine Distance

The cosine distance can be calculated as follows:

```sql
select
    1-SUM(v1.[vector_value] * v2.[vector_value]) / 
    (
        SQRT(SUM(v1.[vector_value] * v1.[vector_value])) 
        * 
        SQRT(SUM(v2.[vector_value] * v2.[vector_value]))
    ) as cosine_distance
from
    #v1 as v1
inner join 
    #v2 as v2 on v1.[vector_value_id] = v2.[vector_value_id]
```

## Dot Product

The dot produce can be calculated as follows:

```sql
select
    SUM(v1.[vector_value] * v2.[vector_value]) as dot_product
from
    #v1 as v1
inner join 
    #v2 as v2 on v1.[vector_value_id] = v2.[vector_value_id]
```

## Euclidean Distance

The euclidean distance can be calculated as follows:

```sql
select
    SQRT(SUM(POWER(v1.[vector_value] - v2.[vector_value], 2))) as euclidean_distance    
from
    #v1 as v1  
inner join
    #v2 as v2 on v1.[vector_value_id] = v2.[vector_value_id]
```

## Manhattan Distance

The manhattan distance can be calculated as follows:

```sql
select
    SUM(ABS(v1.[vector_value] - v2.[vector_value])) as manhattan_distance
from
    #v1 as v1  
inner join
    #v2 as v2 on v1.[vector_value_id] = v2.[vector_value_id]
```