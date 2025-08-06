// Import releases from CSV file into Neo4j database
//        0 · (recommended) fast lookup indexes / constraints
CREATE CONSTRAINT release_id_unique IF NOT EXISTS
FOR (r:Release) REQUIRE r.release_id IS UNIQUE;

//        1 · batch import  (commit every 2 000 rows)
:auto
CALL {
  // ──────────────── 1 · stream the CSV ─────────────────────────────
  LOAD CSV WITH HEADERS FROM 'file:///releases.csv' AS row
  WITH row
  WHERE row.release_id <> ''                               // skip blanks

  // ──────────────── 2 · create / update Release node ──────────────
  MERGE (rel:Release {release_id: toInteger(row.release_id)})
  SET   rel.title        = row.release_title,
        rel.type         = row.release_type,
        rel.catalog_nr   = row.catalog_nr,
        rel.tribute_album=
              CASE trim(row.TributeAlbum)   // "TRUE", "False", ""
                   WHEN ''   THEN NULL
                   ELSE toBoolean(row.TributeAlbum) END,
        // store year as INT (safer than Date when only "1979.0")
        rel.year =
              CASE row.release_date
                   WHEN '' THEN NULL
                   ELSE toInteger( split(row.release_date, '.')[0] )
              END

  // ──────────────── 3 · link the credited artist (optional) ───────
  WITH rel, row
  WHERE row.artist_id <> ''
  MATCH (a:Artist {artist_id: toInteger(row.artist_id)})
  MERGE (a)-[:RELEASED]->(rel)

  // ──────────────── 4 · explode perf_ids list  ─────────────────────
  WITH rel,
       [ id IN split(
               replace(
                 replace(
                   replace(row.perf_ids,'[',''),']',''),
                 ',',' '),   // normalise commas
               ' ')
         | trim(id) ] AS perfList

  UNWIND perfList AS pid
  WITH rel, pid
  WHERE pid <> ''

  // ──────────────── 5 · connect to Song or Cover ───────────────────
  OPTIONAL MATCH (s:Song  {song_id:  toInteger(pid)})
  OPTIONAL MATCH (c:Cover {cover_id: toInteger(pid)})

  FOREACH (x IN CASE WHEN s IS NULL THEN [] ELSE [s] END |
           MERGE (rel)-[:CONTAINS]->(x))

  FOREACH (x IN CASE WHEN c IS NULL THEN [] ELSE [c] END |
           MERGE (rel)-[:CONTAINS]->(x))

} IN TRANSACTIONS OF 500 ROWS;

// Quick checks after it finishes
// releases imported
MATCH (r:Release) RETURN count(r);

// artist → release links
MATCH (:Artist)-[ :RELEASED ]->(:Release) RETURN count(*);

// release → performance links
MATCH (:Release)-[:CONTAINS]->() RETURN count(*);

// random sample
MATCH (art:Artist)-[:RELEASED]->(rel:Release)-[:CONTAINS]->(p)
RETURN rel.release_id, rel.title, art.common_name, labels(p)[0] AS perfLabel, p.title
ORDER BY rand() LIMIT 5;