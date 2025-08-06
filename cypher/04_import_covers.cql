// Import covers from CSV file into Neo4j database
//        0 · (recommended) fast lookup indexes / constraints
CREATE CONSTRAINT cover_id_unique  IF NOT EXISTS
FOR (c:Cover) REQUIRE c.cover_id  IS UNIQUE;

//        1 · batch import  (commit every 2 000 rows)
:auto
CALL {
  LOAD CSV WITH HEADERS FROM 'file:///covers.csv' AS row
  WITH row
  WHERE row.perf_id <> ''

  MERGE (c:Cover {cover_id: toInteger(row.perf_id)})
  SET  c.title = row.song_title,
       c.year  = CASE row.perf_year WHEN '' THEN NULL ELSE toInteger(row.perf_year) END

  WITH c, row
  MATCH (o:Song {song_id: toInteger(row.org_perf_id)})
  MERGE (c)-[:COVER_OF]->(o)

  WITH c,
       [id IN split(
              replace(replace(replace(row.cov_art_id,'[',''),']',''),',',' '),
              ' ')
        | trim(id)] AS ids

  UNWIND ids AS artId
  WITH c, toInteger(artId) AS aid
  WHERE aid IS NOT NULL

  MATCH (a:Artist {artist_id: aid})
  MERGE (a)-[:PERFORMED]->(c)
} IN TRANSACTIONS OF 500 ROWS


// Sanity checks after it finishes
// covers imported
MATCH (c:Cover) RETURN count(c);

// artist-→cover links
MATCH (:Artist)-[r:PERFORMED]->(:Cover) RETURN count(r);

// sample 5
MATCH (a:Artist)-[:PERFORMED]->(c:Cover)-[:COVER_OF]->(o:Song)
RETURN c.cover_id, c.title, a.common_name, o.title
ORDER BY rand() LIMIT 5;