
DROP FUNCTION IF EXISTS get_related;

CREATE OR REPLACE FUNCTION get_related(
  word_search TEXT, 
  word_column_name TEXT, 
  embeddings_column_name TEXT, 
  embeddings_table TEXT,
  number_results INT DEFAULT 10,
  order_by_closest BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
  word_related TEXT,
  cos_sim DOUBLE PRECISION
)
LANGUAGE plpgsql
AS $$
DECLARE
  safe_word_column_name TEXT := format('%I', word_column_name);
  safe_embeddings_column_name TEXT := format('%I', embeddings_column_name);
  safe_embeddings_table TEXT := format('%I', embeddings_table);
  safe_word_search TEXT := format('%L', word_search);
  safe_number_results TEXT := format('%L', number_results);
  order_clause TEXT;
BEGIN
  -- RAISE NOTICE 'safe_word_column_name: %', safe_word_column_name;
  -- RAISE NOTICE 'safe_embeddings_column_name: %', safe_embeddings_column_name;
  -- RAISE NOTICE 'safe_embeddings_table: %', safe_embeddings_table;
  -- RAISE NOTICE 'safe_word_search: %', safe_word_search;
  -- RAISE NOTICE 'safe_number_results: %', safe_number_results;
  -- RAISE NOTICE 'order_by_closest: %', order_by_closest;
  IF order_by_closest THEN
    order_clause := 'DESC';
  ELSE
    order_clause := 'ASC';
  END IF;
    RETURN QUERY EXECUTE
      'SELECT ' || 
      '   t2.' || safe_word_column_name || ', ' || 
      '   1 - (t1.' || safe_embeddings_column_name || ' <=> t2.' || safe_embeddings_column_name || ') AS cos_sim' ||
      ' FROM ' || safe_embeddings_table || ' t1 JOIN ' || safe_embeddings_table || ' t2' ||
      '   ON t1.' || safe_word_column_name || ' <> t2.' || safe_word_column_name ||
      ' WHERE t1.' || safe_word_column_name || '=' || safe_word_search ||
      ' ORDER BY cos_sim ' || order_clause ||
      ' LIMIT ' || safe_number_results
    ;
END;
$$;

COMMENT ON FUNCTION get_related(
  word_search TEXT, 
  word_column_name TEXT, 
  embeddings_column_name TEXT, 
  embeddings_table TEXT,
  number_results INT,
  order_by_closest BOOLEAN
) IS $doc$
Returns the most related words to a given word based on vector cosine similarity.

Parameters:
- word_search (TEXT): The reference word to search for.
- word_column_name (TEXT): Name of the column that stores the words.
- embeddings_column_name (TEXT): Name of the column that stores the embeddings (pgvector type).
- embeddings_table (TEXT): Name of the embeddings table.
- number_results (INT, default 10): Maximum number of related words to return.
- order_by_closest (BOOLEAN, default TRUE): If TRUE, return closest matches first; 
  if FALSE, return farthest words first.

Returns:
- word_related (TEXT): Related word.
- cos_sim (DOUBLE PRECISION): Cosine similarity to the input word.

Example:
  SELECT * FROM get_related('frau', 'word', 'embedding', 'word2vec__m4');
  SELECT * FROM get_related('frau', 'word', 'embedding', 'word2vec__m4', 5, FALSE);
$doc$;
