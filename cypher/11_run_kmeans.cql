// --- 1) Create log-scaled metrics for all three centralities ---
MATCH (a:Artist) WHERE a.pagerank IS NOT NULL
SET a.pr_log = log(1 + a.pagerank);

MATCH (a:Artist) WHERE a.in_degree IS NOT NULL
SET a.deg_log = log(1 + a.in_degree);

MATCH (a:Artist) WHERE a.betweenness IS NOT NULL
SET a.btw_log = log(1 + a.betweenness);

// --- 2) Global means/stddevs for z-scoring on the logs ---
CALL () {
  WITH *
  MATCH (a:Artist)
  WHERE a.pr_log IS NOT NULL AND a.deg_log IS NOT NULL AND a.btw_log IS NOT NULL
  RETURN
    avg(a.pr_log)  AS mu_pr,  stDev(a.pr_log)  AS sd_pr,
    avg(a.deg_log) AS mu_deg, stDev(a.deg_log) AS sd_deg,
    avg(a.btw_log) AS mu_btw, stDev(a.btw_log) AS sd_btw
}
WITH mu_pr, sd_pr, mu_deg, sd_deg, mu_btw, sd_btw

// --- 3) Standardized 3-D vector on log metrics ---
MATCH (a:Artist)
WHERE a.pr_log IS NOT NULL AND a.deg_log IS NOT NULL AND a.btw_log IS NOT NULL
SET a.kvec = [
  toFloat( (a.pr_log  - mu_pr)  / (CASE WHEN sd_pr  IS NULL OR sd_pr  = 0 THEN 1 ELSE sd_pr  END) ),
  toFloat( (a.deg_log - mu_deg) / (CASE WHEN sd_deg IS NULL OR sd_deg = 0 THEN 1 ELSE sd_deg END) ),
  toFloat( (a.btw_log - mu_btw) / (CASE WHEN sd_btw IS NULL OR sd_btw = 0 THEN 1 ELSE sd_btw END) )
];

// --- 4) Re-project graph for k-means (includes 'kvec') ---
CALL gds.graph.drop('artistInfluence_kmeans', false);
CALL gds.graph.project.cypher(
  'artistInfluence_kmeans',
  'MATCH (a:Artist) WHERE a.kvec IS NOT NULL RETURN id(a) AS id, a.kvec AS kvec',
  'MATCH (u:Artist)-[:INFLUENCE]->(v:Artist) RETURN id(u) AS source, id(v) AS target'
);

// --- 5) Check silhouette for k in 2..8 ---
UNWIND range(2, 8) AS k
CALL gds.kmeans.stats('artistInfluence_kmeans', {
  nodeProperty: 'kvec', k: k, initialSampler: 'kmeans++', computeSilhouette: true
})
YIELD averageSilhouette
RETURN k, round(averageSilhouette, 3) AS avg_sil
ORDER BY avg_sil DESC, k ASC;

// --- 6) Write final clusters (example k = 3) ---
CALL gds.kmeans.write('artistInfluence_kmeans', {
  nodeProperty: 'kvec', k: 3, initialSampler: 'kmeans++', randomSeed: 42, writeProperty: 'kmeans_cid'
})
YIELD nodePropertiesWritten
RETURN nodePropertiesWritten;
