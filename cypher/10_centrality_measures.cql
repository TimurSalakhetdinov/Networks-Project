
// in_degree
CALL gds.degree.write('artistInfluence6020', {
  orientation: 'REVERSE',
  writeProperty: 'in_degree'
});

// PageRank 
CALL gds.pageRank.write('artistInfluence6020', {
  relationshipWeightProperty: 'weight',
  dampingFactor: 0.85,
  maxIterations: 50,
  writeProperty: 'pagerank'
});

// Betweenness
CALL gds.betweenness.write('artistInfluence6020', {
  writeProperty: 'betweenness',
  concurrency: 4   // 
});

// or produce a table for each 


// Betweenness 
CALL gds.betweenness.stream('artistInfluence6020')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).common_name AS artist, score AS betweenness
ORDER BY betweenness DESC
LIMIT 100;

// in_degree 
CALL gds.degree.stream('artistInfluence6020', { orientation: 'REVERSE' })
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).common_name AS artist, score AS in_degree
ORDER BY in_degree DESC
LIMIT 100;

// PageRank 

CALL gds.pageRank.stream('artistInfluence6020', {
  dampingFactor: 0.85,   
  tolerance: 1e-6,      
  maxIterations: 50      
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).common_name AS artist, score AS pagerank
ORDER BY pagerank DESC
LIMIT 100;