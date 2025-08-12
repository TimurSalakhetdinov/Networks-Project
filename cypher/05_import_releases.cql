// Import releases from CSV file into Neo4j database
// batch import  (commit every 2 000 rows)
:auto
CALL {
  // ──────────────── 1 · stream the CSV ─────────────────────────────
  LOAD CSV WITH HEADERS FROM 'file:///releases.csv' AS row
  WITH row
  WHERE trim(row.release_id) <> ''                               // skip blanks

  // ──────────────── 2 · create / update Release node ──────────────
  MERGE (rel:Release {release_id: toInteger(trim(row.release_id))})
  SET   rel.title        = trim(row.release_title),
        rel.type         = trim(row.release_type),
        rel.catalog_nr   = CASE WHEN row.catalog_nr IS NULL OR trim(row.catalog_nr) = '' THEN NULL ELSE trim(row.catalog_nr) END,
        rel.tribute_album=
              CASE trim(coalesce(row.TributeAlbum, ''))          // "True", "FALSE", ""
                   WHEN ''   THEN NULL
                   ELSE toBoolean(trim(row.TributeAlbum)) END,
        // store year as INT (handles values like "1979.0")
        rel.year = CASE trim(coalesce(row.release_date, ''))
                     WHEN '' THEN NULL
                     ELSE toInteger(floor(toFloat(trim(row.release_date))))
                   END

  // ──────────────── 3 · parse lists once (keep both without `row`) ─
  WITH rel,
       [x IN split(
              trim(replace(replace(coalesce(row.artist_id,''),'[',''),']','')),
              ',')
        | toInteger(trim(x))] AS artistIds,
       [x IN split(
              trim(replace(replace(coalesce(row.perf_ids,''),'[',''),']','')),
              ',')
        | toInteger(trim(x))] AS perfList

  // ──────────────── 4 · link the credited artist(s) ───────────────
  UNWIND artistIds AS aid
  WITH rel, perfList, aid
  WHERE aid IS NOT NULL
  MATCH (a:Artist {artist_id: aid})
  MERGE (a)-[:RELEASED]->(rel)

  // ──────────────── 5 · connect each perf_id to Song or Cover ─────
  WITH rel, perfList
  UNWIND perfList AS pid
  WITH rel, pid
  WHERE pid IS NOT NULL
  OPTIONAL MATCH (s:Song  {song_id:  pid})
  OPTIONAL MATCH (c:Cover {cover_id: pid})
  WITH rel, coalesce(s, c) AS perf
  WHERE perf IS NOT NULL
  MERGE (rel)-[:CONTAINS]->(perf)

} IN TRANSACTIONS OF 2000 ROWS;

// Quick checks after it finishes
// releases imported
MATCH (r:Release) RETURN count(r);

// artist → release links
MATCH (:Artist)-[:RELEASED]->(:Release) RETURN count(*);

// release → performance links
MATCH (:Release)-[:CONTAINS]->() RETURN count(*);

// random sample
MATCH (art:Artist)-[:RELEASED]->(rel:Release)-[:CONTAINS]->(p)
RETURN rel.release_id, rel.title, art.common_name, labels(p)[0] AS perfLabel, p.title
ORDER BY rand() LIMIT 5;