/* run once – creates about 70 k [:INFLUENCE] relationships */
// INFLUENCE relationship between artists, with a numeric weight telling 
// how many covers by cov are of songs by orig (only between 1960–2020) and
// a time influence property showing a year gap between the cover and the original song
:auto
CALL {
  MATCH (c:Cover)-[:COVER_OF]->(s:Song)<-[:PERFORMED]-(orig:Artist),
        (c)<-[:PERFORMED]-(cov:Artist)
  WHERE 1960 <= c.year <= 2020
  WITH cov, orig, 
       count(*) AS w,
       avg(c.year - s.year) AS avg_time_gap    // average gap in years between cover and original

  MERGE (cov)-[r:INFLUENCE]->(orig)
  ON CREATE SET 
      r.weight = w, 
      r.avg_time_gap = avg_time_gap
  ON MATCH SET 
      r.weight = r.weight + w,
      r.avg_time_gap = (coalesce(r.avg_time_gap, 0) * (r.weight - w) + avg_time_gap * w) / r.weight
} IN TRANSACTIONS OF 5000 ROWS;

// Drop old projection if it exists
CALL gds.graph.drop('artistInfluence6020', false);

// Create aggregated projection with both weight and avg_time_gap
CALL gds.graph.project.cypher(
  'artistInfluence6020',

  /* nodes (all artists) */
  'MATCH (a:Artist) RETURN id(a) AS id',

  /* edges: include both properties */
  '
  MATCH (cov:Artist)-[r:INFLUENCE]->(orig:Artist)
  RETURN id(cov) AS source, 
         id(orig) AS target, 
         r.weight AS weight,
         r.avg_time_gap AS avg_time_gap
  '
);

// Full network stats in one table
CALL {
  /* size & density */
  CALL gds.graph.list('artistInfluence6020')
  YIELD nodeCount, relationshipCount, density
  RETURN
    nodeCount            AS vertices,
    relationshipCount    AS edges,
    round(density,8)     AS density
} 
WITH vertices, edges, density

CALL {
  /* degree statistics */
  CALL gds.degree.stream('artistInfluence6020')
  YIELD score
  RETURN
    min(score)           AS minDeg,
    round(avg(score),2)  AS avgDeg,
    max(score)           AS maxDeg
}
WITH vertices, edges, density, minDeg, avgDeg, maxDeg

CALL {
  /* weakly-connected components */
  CALL gds.wcc.stats('artistInfluence6020')
  YIELD componentCount
  RETURN componentCount  AS wcc_components
}
WITH vertices, edges, density, minDeg, avgDeg, maxDeg, wcc_components

CALL {
  /* strongly-connected components */
  CALL gds.scc.stats('artistInfluence6020')
  YIELD componentCount
  RETURN componentCount  AS scc_components
}
WITH vertices, edges, density, minDeg, avgDeg, maxDeg, wcc_components, scc_components

CALL {
  /* sample for path length & diameter */
  MATCH (a:Artist)
  WITH a ORDER BY rand() LIMIT 100
  RETURN collect(a) AS sample
}
WITH vertices, edges, density, minDeg, avgDeg, maxDeg, wcc_components, scc_components, sample

UNWIND sample AS source
UNWIND sample AS target
WITH vertices, edges, density, minDeg, avgDeg, maxDeg, wcc_components, scc_components, source, target
WHERE id(source) < id(target)

CALL {
  WITH source, target
  OPTIONAL MATCH p = shortestPath((source)-[:INFLUENCE*..15]-(target))
  RETURN CASE WHEN p IS NULL THEN NULL ELSE length(p) END AS hops
}
WITH vertices, edges, density, minDeg, avgDeg, maxDeg, wcc_components, scc_components, hops
WHERE hops IS NOT NULL

RETURN
  vertices,
  edges,
  density,
  minDeg,
  avgDeg,
  maxDeg,
  wcc_components,
  scc_components,
  round(avg(hops), 2) AS avg_path_length,
  max(hops)           AS diameter;