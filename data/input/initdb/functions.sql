

-- vector setup ------------------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS vector;


-- get_related -------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS get_related;

CREATE OR REPLACE FUNCTION get_related(
    word_search TEXT,
    embeddings_table TEXT,
    word_column_name TEXT,
    embeddings_column_name TEXT,
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
    safe_word_search TEXT := format('%L', word_search);
    safe_embeddings_table TEXT := format('%I', embeddings_table);
    safe_word_column_name TEXT := format('%I', word_column_name);
    safe_embeddings_column_name TEXT := format('%I', embeddings_column_name);
    safe_number_results TEXT := format('%L', number_results);
    order_clause TEXT;
BEGIN
    IF order_by_closest THEN
        order_clause := 'DESC';
    ELSE
        order_clause := 'ASC';
    END IF;
    RETURN QUERY EXECUTE
        ' SELECT' ||
        '   t2.' || safe_word_column_name || ',' ||
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
    embeddings_table TEXT,
    word_column_name TEXT,
    embeddings_column_name TEXT,
    number_results INT,
    order_by_closest BOOLEAN
) IS $doc$
Returns the most related words to a given word based on vector cosine similarity.

Parameters:
- word_search (TEXT): The reference word to search for.
- embeddings_table (TEXT): Name of the embeddings table.
- word_column_name (TEXT): Name of the column that stores the words.
- embeddings_column_name (TEXT): Name of the column that stores the embeddings (pgvector type).
- number_results (INT, default 10): Maximum number of related words to return.
- order_by_closest (BOOLEAN, default TRUE): If TRUE, return closest matches first; 
if FALSE, return farthest words first.

Returns:
- word_related (TEXT): Related word.
- cos_sim (DOUBLE PRECISION): Cosine similarity to the input word.

Example:
SELECT * FROM get_related('frau', 'word2vec__m4', 'word', 'embedding');
SELECT * FROM get_related('frau', 'word2vec__m4', 'word', 'embedding', 5, FALSE);
$doc$;


-- get_sim_between_words ---------------------------------------------------------------------------

DROP FUNCTION IF EXISTS get_sim_between_words;

CREATE OR REPLACE FUNCTION get_sim_between_words (
    word_search_1 TEXT,
    word_search_2 TEXT,
    embeddings_table TEXT,
    word_column_name TEXT,
    embeddings_column_name TEXT
) RETURNS TABLE (cos_sim DOUBLE PRECISION) LANGUAGE PLPGSQL AS $$
DECLARE
    safe_word_search_1 TEXT := format('%L', word_search_1);
    safe_word_search_2 TEXT := format('%L', word_search_2);
    safe_embeddings_table TEXT := format('%I', embeddings_table);
    safe_word_column_name TEXT := format('%I', word_column_name);
    safe_embeddings_column_name TEXT := format('%I', embeddings_column_name);
BEGIN
    RETURN QUERY EXECUTE
        ' SELECT 1 - ( t1.embedding <=> t2.embedding )' ||
        ' FROM ' || safe_embeddings_table || ' t1 JOIN '  || safe_embeddings_table || ' t2 ' ||
        '   ON t1.' || safe_word_column_name || '=' || safe_word_search_1 || ' AND t2.' || safe_word_column_name || '=' || safe_word_search_2 ||
        ' LIMIT 2'
    ;
END;
$$;

COMMENT ON FUNCTION get_sim_between_words(
    word_search_1 TEXT,
    word_search_2 TEXT,
    embeddings_table TEXT,
    word_column_name TEXT,
    embeddings_column_name TEXT
) IS $doc$
Returns the cosine similarity between two given words based on their vector embeddings.

Parameters:
- word_search_1 (TEXT): The first word to compare.
- word_search_2 (TEXT): The second word to compare.
- embeddings_table (TEXT): Name of the embeddings table.
- word_column_name (TEXT): Name of the column that stores the words.
- embeddings_column_name (TEXT): Name of the column that stores the embeddings (pgvector type).

Returns:
- cos_sim (DOUBLE PRECISION): Cosine similarity between the two words.

Example:
SELECT * FROM get_sim_between_words('frau', 'mann', 'word2vec__m4', 'word', 'embedding');
$doc$;

