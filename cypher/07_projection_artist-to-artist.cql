// 0. Drop the graph if it exists
CALL gds.graph.exists('artistInfluence6020') YIELD exists;
CALL apoc.when(exists,
  'CALL gds.graph.drop("artistInfluence6020") YIELD graphName RETURN graphName',
  'RETURN "no old projection" AS graphName',
  {}
) YIELD graphName;

// 1. Create a new graph projection
/*  Directed, weighted edges:
     source = covering artist
     target = original artist
     weight = number of distinct covers, 1960-2020            */
CALL gds.graph.project.cypher(
  'artistInfluence6020',

  /* ── node query ─────────────────────────────────────────── */
  'MATCH (a:Artist) RETURN id(a) AS id',

  /* ── edge query ─────────────────────────────────────────── */
  '
  MATCH (cov:Cover)-[:COVER_OF]->(:Song)<-[:PERFORMED]-(orig:Artist),
        (cov)<-[:PERFORMED]-(covering:Artist)
  WHERE 1960 <= cov.year <= 2020
  RETURN id(covering) AS source,
         id(orig)     AS target,
         count(*)     AS weight
  '
);

// 2. Basic size and degree distribution
CALL gds.graph.list('artistInfluence6020')
YIELD nodeCount, relationshipCount, density, degreeDistribution
RETURN
  nodeCount            AS vertices,
  relationshipCount    AS edges,
  round(density,8)     AS density,
  degreeDistribution.minimum AS minDegree,
  round(degreeDistribution.mean,2) AS avgDegree,
  degreeDistribution.maximum AS maxDegree;

// 3. Components
/* weakly-connected */
CALL gds.wcc.stats('artistInfluence6020')
YIELD componentCount
RETURN componentCount AS wcc_components;

/* strongly-connected */
CALL gds.scc.stats('artistInfluence6020')
YIELD componentCount
RETURN componentCount AS scc_components;

// 4. Distance measures
/* approximate diameter */
CALL gds.alpha.diameter.approximate.stream('artistInfluence6020')
YIELD eccentricity
RETURN max(eccentricity) AS diameter;

/* average shortest-path length (undirected) */
CALL gds.alpha.shortestPath.avg('artistInfluence6020')
YIELD averageShortestPath
RETURN round(averageShortestPath,2) AS avg_path_length;