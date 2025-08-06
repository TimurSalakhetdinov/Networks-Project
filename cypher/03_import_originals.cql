// Import original songs from CSV file into Neo4j database
//        0 · (recommended) fast lookup indexes / constraints
CREATE INDEX song_id_index IF NOT EXISTS
FOR (s:Song) ON (s.song_id);

//        1 · batch import  (commit every 2 000 rows)
:auto
CALL {
  // 1 ─ read the CSV, keep rows that have a perf_id
  LOAD CSV WITH HEADERS FROM 'file:///originals.csv' AS row
  WITH row
  WHERE row.perf_id <> ''          // skip broken lines

  // 2 ─ create or update the Song node
  MERGE (s:Song {
          song_id:  toInteger(row.perf_id)   // unique key
        })
  SET   s.title = row.song_title,
        s.year  = CASE row.release_year
                  WHEN '' THEN NULL ELSE toInteger(row.release_year) END

  // 3 ─ get the list of original-artist ids cleanly
  WITH s,
       // remove both [ and ], then split on space or comma
       [id IN split(
                trim(replace(replace(row.org_art_id,'[',''),']','')),
                ' ')
        | trim(id)]          AS rawIds

  UNWIND rawIds AS artistId
  WITH s, artistId
  WHERE artistId <> ''               // filter out empties

  // 4 ─ connect artist → song
  MATCH (a:Artist {artist_id: toInteger(artistId)})
  MERGE (a)-[:PERFORMED]->(s)
} IN TRANSACTIONS OF 2000 ROWS

// 3 . Sanity checks after it finishes
// Songs created
MATCH (s:Song) RETURN count(s);

// Artist-→Song links created
MATCH (:Artist)-[r:PERFORMED]->(:Song) RETURN count(r);

// Random sample
MATCH (a:Artist)-[:PERFORMED]->(s:Song)
RETURN s.song_id, s.title, a.artist_id, a.common_name
ORDER BY rand()
LIMIT 5;