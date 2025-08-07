// 1  Sanity-check the raw graph
// node counts
MATCH (a:Artist)  RETURN count(*) AS artists;
MATCH (s:Song)    RETURN count(*) AS originals;
MATCH (c:Cover)   RETURN count(*) AS covers;
MATCH (r:Release) RETURN count(*) AS releases;

// relationship counts
MATCH (:Artist)-[:PERFORMED]->() RETURN count(*) AS perf_links;
MATCH (:Cover)-[:COVER_OF]->()   RETURN count(*) AS cover_links;
MATCH (:Artist)-[:RELEASED]->()  RETURN count(*) AS rel_links;

/* ─────────── integrity-check dashboard ─────────── */
CALL {
  // node counts
  MATCH (a:Artist)  RETURN 'nodes_Artist'  AS metric, count(a)  AS value
  UNION ALL
  MATCH (s:Song)    RETURN 'nodes_Song'    AS metric, count(s)  AS value
  UNION ALL
  MATCH (c:Cover)   RETURN 'nodes_Cover'   AS metric, count(c)  AS value
  UNION ALL
  MATCH (r:Release) RETURN 'nodes_Release' AS metric, count(r)  AS value

  // duplicate IDs (should be 0)
  UNION ALL
  MATCH (a:Artist)
  WITH a.artist_id AS id, count(*) AS c
  WHERE c > 1
  RETURN 'dup_artist_id'  AS metric, count(*) AS value
  UNION ALL
  MATCH (s:Song)
  WITH s.song_id AS id, count(*) AS c
  WHERE c > 1
  RETURN 'dup_song_id'    AS metric, count(*) AS value
  UNION ALL
  MATCH (c:Cover)
  WITH c.cover_id AS id, count(*) AS c
  WHERE c > 1
  RETURN 'dup_cover_id'   AS metric, count(*) AS value

  // orphan originals (expect 0)
  UNION ALL
  MATCH (s:Song)
  WHERE NOT ( (:Artist)-[:PERFORMED]->(s) )
  RETURN 'songs_without_performer' AS metric, count(s) AS value

  // orphan covers (ideally 0)
  UNION ALL
  MATCH (c:Cover)
  WHERE NOT ( (:Artist)-[:PERFORMED]->(c) )
     OR NOT ( (c)-[:COVER_OF]->(:Song) )
  RETURN 'covers_missing_link' AS metric, count(c) AS value
}
RETURN metric, value
ORDER BY metric;

// delete original songs with no performer
MATCH (s:Song)
WHERE NOT ( (:Artist)-[:PERFORMED]->(s) )
DETACH DELETE s;

// delete covers that miss either link
MATCH (c:Cover)
WHERE NOT ( (:Artist)-[:PERFORMED]->(c) )
   OR NOT ( (c)-[:COVER_OF]->(:Song) )
DETACH DELETE c;