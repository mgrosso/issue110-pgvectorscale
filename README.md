## steps to replicate

### 1. create the table

```sql  
CREATE TABLE test_embedding_dim128 (
    id BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    metadata JSONB,
    contents TEXT,
    embedding VECTOR(128)
);
```

### load the data

first, `gunzip test32k.txt.gz`, then:

```sql
COPY "test_embedding_dim128" (metadata, contents, embedding) FROM '/home/admin/test32k.txt' WITH (FORMAT TEXT, DELIMITER '|');
```

### build index

```sql
CREATE INDEX test_embedding_dim128_diskann on test_embedding_dim128 USING diskann (embedding);
```

### run the query, demonstrating the bug

```sql
explain analyze SELECT x.* FROM
(
       SELECT *, embedding <=>
        '[0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0]'
        as distance, metadata->>'name' = 'test3' as filter1, to_tsvector(contents) @@ plainto_tsquery('world3') as filter2
       FROM "test_embedding_dim128" ORDER BY distance LIMIT 5000000
) as x
WHERE filter1 = true AND filter2 = true
LIMIT 10
;
 Limit  (cost=82.46..116.16 rows=10 width=573) (actual time=0.347..0.347 rows=0 loops=1)
   ->  Subquery Scan on x  (cost=82.46..27689.50 rows=8192 width=573) (actual time=0.345..0.346 rows=0 loops=1)
         Filter: (x.filter1 AND x.filter2)
         Rows Removed by Filter: 51
         ->  Limit  (cost=82.46..27361.82 rows=32768 width=573) (actual time=0.163..0.342 rows=51 loops=1)
               ->  Index Scan using test_embedding_dim128_diskann on test_embedding_dim128  (cost=82.46..27361.82 rows=32768 width=573) (actual time=0.162..0.337 rows=51 loops=1)
                     Order By: (embedding <=> '[0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,
1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,
0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1,0.11,0.29,0.61,1]'::vector)
 Planning Time: 0.081 ms
 Execution Time: 0.366 ms
(9 rows)

-- use your editor to remove the 'explain analyze', then run the query
\e

admin=# \g
 id | metadata | contents | embedding | distance | filter1 | filter2 
----+----------+----------+-----------+----------+---------+---------
(0 rows)
```

There should have been 10 rows returned, but there are none.

Note the 'Rows Removed by Filter: 51' in the explain output. Note the `Index Scan using test_embedding_dim128_diskann on test_embedding_dim128` in the explain output finds 51 rows, `num_neighbors` is left at the default of 50 for this.

### recreate the index and re-run the query demonstrating the workaround

```sql
DROP INDEX test_embedding_dim128_diskann;
CREATE INDEX test_embedding_dim128_diskann_109 on test_embedding_dim128_nn109 USING diskann (embedding) WITH(num_neighbors=109);
explain analyze SELECT x.* FROM
(
       SELECT *, embedding <=>
        '[0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0, 0.11, 0.29, 0.61, 1.0]'
        as distance, metadata->>'name' = 'test3' as filter1, to_tsvector(contents) @@ plainto_tsquery('world3') as filter2
       FROM "test_embedding_dim128" ORDER BY distance LIMIT 5000000
) as x
WHERE filter1 = true AND filter2 = true
LIMIT 10
;
```

## steps to regenerate the test data

Run `ruby generate_test_data.rb` or customize: `ruby generate_test_data.rb my_output.txt 1048576`

Run `ruby generate_test_data.rb query_vector` to generate a 128 dimension query vector which is deliberately closest to the rows with contents 'hello world1' in the test data.
