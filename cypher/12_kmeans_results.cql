// KMEANS REVIEW 1/5 — Size & basic centralities per cluster
MATCH (a:Artist) WHERE a.kmeans_cid IS NOT NULL
RETURN a.kmeans_cid AS cluster,
       count(*) AS size,
       round(avg(a.pagerank), 4)   AS avg_pr,
       round(avg(a.in_degree), 1)  AS avg_in_degree,
       round(avg(a.betweenness),0) AS avg_betweenness
ORDER BY size DESC;

// KMEANS REVIEW 2/5 — Centroids in standardized space (your kvec = [z(PR), z(InDeg), z(log(Betw))])
MATCH (a:Artist) WHERE a.kmeans_cid IS NOT NULL AND a.kvec IS NOT NULL
RETURN a.kmeans_cid AS cluster,
       round(avg(a.kvec[0]), 2) AS z_PR,
       round(avg(a.kvec[1]), 2) AS z_InDeg,
       round(avg(a.kvec[2]), 2) AS z_BetwLog
ORDER BY cluster;

// KMEANS REVIEW 3/5 — "Exemplars": 5 nearest artists to each centroid (in kvec space)
CALL () {
  WITH *
  MATCH (a:Artist) WHERE a.kmeans_cid IS NOT NULL AND a.kvec IS NOT NULL
  RETURN a.kmeans_cid AS cid,
         avg(a.kvec[0]) AS c0, avg(a.kvec[1]) AS c1, avg(a.kvec[2]) AS c2
}
WITH cid, [c0,c1,c2] AS centroid
CALL {
  WITH cid, centroid
  MATCH (a:Artist) WHERE a.kmeans_cid = cid AND a.kvec IS NOT NULL
  WITH cid, centroid, a,
       ((a.kvec[0]-centroid[0])*(a.kvec[0]-centroid[0]) +
        (a.kvec[1]-centroid[1])*(a.kvec[1]-centroid[1]) +
        (a.kvec[2]-centroid[2])*(a.kvec[2]-centroid[2])) AS d2
  ORDER BY d2 ASC
  LIMIT 5
  RETURN cid AS cluster, a.common_name AS artist, d2
}
RETURN cluster, artist, round(d2, 4) AS dist2
ORDER BY cluster, dist2 ASC;

// KMEANS REVIEW 4/5 — Distances between centroids
CALL () {
  WITH *
  MATCH (a:Artist) WHERE a.kmeans_cid IS NOT NULL AND a.kvec IS NOT NULL
  RETURN a.kmeans_cid AS cid,
         avg(a.kvec[0]) AS c0, avg(a.kvec[1]) AS c1, avg(a.kvec[2]) AS c2
}
WITH collect({cid: cid, c: [c0,c1,c2]}) AS C
UNWIND C AS A
UNWIND C AS B
WITH A, B WHERE A.cid < B.cid
WITH A.cid AS c1, B.cid AS c2,
     sqrt( (A.c[0]-B.c[0])*(A.c[0]-B.c[0]) +
           (A.c[1]-B.c[1])*(A.c[1]-B.c[1]) +
           (A.c[2]-B.c[2])*(A.c[2]-B.c[2]) ) AS dist
RETURN c1, c2, round(dist, 2) AS centroid_distance
ORDER BY centroid_distance DESC;

// KMEANS REVIEW 5/5 — Leaders: top 15 by PageRank within each cluster
MATCH (a:Artist) WHERE a.kmeans_cid IS NOT NULL
WITH a
ORDER BY a.kmeans_cid, a.pagerank DESC
WITH a.kmeans_cid AS cluster, collect(a)[0..15] AS top15
UNWIND top15 AS a
RETURN cluster,
       a.common_name AS artist,
       a.pagerank    AS pagerank,
       a.in_degree   AS in_degree,
       a.betweenness AS betweenness
ORDER BY cluster, pagerank DESC;
