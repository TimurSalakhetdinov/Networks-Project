// Import original songs from CSV file into Neo4j database
// 1. Batch import (commit every 2 000 rows)
:auto
CALL {
  // 1 ─ Read the CSV, keep rows that have a perf_id
  LOAD CSV WITH HEADERS FROM 'file:///originals.csv' AS row
  WITH row
  WHERE trim(row.perf_id) <> ''          // skip broken lines

  // 2 ─ Create or update the Song node
  MERGE (s:Song {
          song_id: toInteger(trim(row.perf_id))   // unique key
        })
  SET   s.title = trim(row.song_title),
        s.year  = CASE 
                    WHEN trim(row.release_year) = '' THEN NULL
                    ELSE toInteger(floor(toFloat(trim(row.release_year))))
                  END

  // 3 ─ Get the list of original-artist ids cleanly
  WITH s,
       [id IN split(
                trim(replace(replace(row.org_art_id,'[',''),']','')),
                ',')
        | trim(id)] AS rawIds

  UNWIND rawIds AS artistId
  WITH s, artistId
  WHERE artistId IS NOT NULL AND artistId <> ''  // filter out empties

  // 4 ─ Connect artist → song
  MATCH (a:Artist {artist_id: toInteger(artistId)})
  MERGE (a)-[:PERFORMED]->(s)
} IN TRANSACTIONS OF 2000 ROWS;


// 2. Sanity checks after it finishes
// Songs created
MATCH (s:Song) RETURN count(s);

// Artist→Song links created
MATCH (:Artist)-[r:PERFORMED]->(:Song) RETURN count(r);

// Random sample
MATCH (a:Artist)-[:PERFORMED]->(s:Song)
RETURN s.song_id, s.title, a.artist_id, a.common_name
ORDER BY rand()
LIMIT 5;