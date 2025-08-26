MATCH (a:Artist)
RETURN a.common_name AS artist,
       a.in_degree   AS in_degree,
       a.betweenness AS betweenness,
       a.pagerank    AS pagerank
ORDER BY pagerank DESC
LIMIT 1000;
