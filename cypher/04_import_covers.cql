// Import covers from CSV file into Neo4j database
// batch import  (commit every 2 000 rows)
:auto
CALL {
  LOAD CSV WITH HEADERS FROM 'file:///covers.csv' AS row
  WITH row
  WHERE trim(row.perf_id) <> ''                       // skip broken lines

  // 1 ─ create/update Cover node
  MERGE (c:Cover {cover_id: toInteger(trim(row.perf_id))})
  SET  c.title = trim(row.song_title),
       c.year  = CASE
                    WHEN trim(row.perf_year) = '' THEN NULL
                    ELSE toInteger(floor(toFloat(trim(row.perf_year))))
                 END

  // 2 ─ link to original Song (if present)
  WITH c, row
  WHERE trim(row.org_perf_id) <> ''
  MATCH (o:Song {song_id: toInteger(trim(row.org_perf_id))})
  MERGE (c)-[:COVER_OF]->(o)

  // 3 ─ parse cov_art_id list and connect artists → cover
  WITH c, row
  WITH c,
       [id IN split(
              trim(replace(replace(row.cov_art_id,'[',''),']','')),
              ',')
        | toInteger(trim(id))] AS artIds
  UNWIND artIds AS aid
  WITH c, aid
  WHERE aid IS NOT NULL

  MATCH (a:Artist {artist_id: aid})
  MERGE (a)-[:PERFORMED]->(c)
} IN TRANSACTIONS OF 2000 ROWS


// Sanity checks after it finishes
// covers imported
MATCH (c:Cover) RETURN count(c);

// artist→cover links
MATCH (:Artist)-[r:PERFORMED]->(:Cover) RETURN count(r);

// sample 5
MATCH (a:Artist)-[:PERFORMED]->(c:Cover)-[:COVER_OF]->(o:Song)
RETURN c.cover_id, c.title, a.common_name, o.title
ORDER BY rand() LIMIT 5;