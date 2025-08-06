/* run once – creates about 70 k [:INFLUENCE] relationships */
:auto
CALL {
  MATCH (c:Cover)-[:COVER_OF]->(:Song)<-[:PERFORMED]-(orig:Artist),
        (c)<-[:PERFORMED]-(cov:Artist)
  WHERE 1960 <= c.year <= 2020
  WITH cov, orig, count(*) AS w
  MERGE (cov)-[r:INFLUENCE]->(orig)
  ON CREATE SET r.weight = 1       // unweighted hops
} IN TRANSACTIONS OF 5000 ROWS;

// 0. Drop the graph if it exists
CALL gds.graph.drop('artistInfluence6020', false);

// 1. Create a new graph projection
// 2 ▸ create aggregated projection
CALL gds.graph.project.cypher(
  'artistInfluence6020',

  /* nodes (all artists) */
  'MATCH (a:Artist) RETURN id(a) AS id',

  /* edges: covering → original, aggregated weight */
  '
  MATCH (c:Cover)-[:COVER_OF]->(:Song)<-[:PERFORMED]-(orig:Artist),
        (c)<-[:PERFORMED]-(cov:Artist)
  WHERE 1960 <= c.year <= 2020
  WITH id(cov)    AS source,
       id(orig)   AS target,
       count(*)   AS weight            // <── aggregates duplicates
  RETURN source, target, weight
  '
);

// 2. Basic size and degree distribution
/* size & degree */
/* ── combined network-metrics query ─────────────────────────── */
CALL {
  /* 1 ▸ size + density (fast) */
  CALL gds.graph.list('artistInfluence6020')
  YIELD nodeCount, relationshipCount, density
  RETURN
    nodeCount         AS vertices,
    relationshipCount AS edges,
    round(density,8)  AS density
}
CALL {
  /* 2 ▸ degree stats (stream + aggregate) */
  CALL gds.degree.stream('artistInfluence6020')
  YIELD score                       /* total degree of one artist */
  RETURN
    min(score)         AS minDeg,
    round(avg(score),2) AS avgDeg,
    max(score)         AS maxDeg
}
RETURN
  vertices,
  edges,
  density,
  minDeg,
  avgDeg,
  maxDeg;

/* components */
CALL gds.wcc.stats('artistInfluence6020') YIELD componentCount;
CALL gds.scc.stats('artistInfluence6020') YIELD componentCount;

/* 3. Path length & diameter */
/* 100-pair sample → average path length & diameter */
MATCH (a:Artist)
WITH collect(a) AS all
WITH apoc.coll.randomItems(all, 100, false) AS sample

UNWIND sample AS source
UNWIND sample AS target
WITH source, target WHERE id(source) < id(target)

CALL apoc.algo.dijkstra(source, target, 'INFLUENCE>', 'weight')
YIELD weight                                     // weight = hop-count
RETURN
  round(avg(weight), 2) AS avg_path_length,
  max(weight)          AS diameter;