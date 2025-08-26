// Basic Graph Description

// 1) Size & density
CALL gds.graph.list('artistInfluence6020')
YIELD nodeCount, relationshipCount, density
WITH nodeCount AS vertices, relationshipCount AS edges, density

// 2) Weakly connected components
CALL gds.wcc.stats('artistInfluence6020')
YIELD componentCount
WITH vertices, edges, density, componentCount AS number_of_components

// 3) Strongly connected components (optional)
CALL gds.scc.stats('artistInfluence6020')
YIELD componentCount
WITH vertices, edges, density, number_of_components, componentCount AS number_of_strong_components

// 4) Average distance & diameter
CALL () {
  WITH *
  MATCH (a:Artist)
  WITH a ORDER BY rand() LIMIT 200      
  WITH collect(a) AS sample
  UNWIND sample AS source
  UNWIND sample AS target
  WITH source, target
  WHERE elementId(source) < elementId(target)   // statt id()
  OPTIONAL MATCH p = shortestPath((source)-[:INFLUENCE*..15]-(target))
  WITH CASE WHEN p IS NULL THEN NULL ELSE length(p) END AS hops
  RETURN avg(hops) AS avg_distance, max(hops) AS diameter
}
WITH vertices, edges, density, number_of_components, number_of_strong_components, avg_distance, diameter

RETURN
  vertices,
  edges,
  density,
  number_of_components,
  number_of_strong_components,
  round(coalesce(avg_distance,0) * 100.0) / 100.0 AS avg_shortest_path,
  diameter;
