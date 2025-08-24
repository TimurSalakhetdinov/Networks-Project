// Bloom Cyphers

// 1. Influential Artists
MATCH (a:Artist)-[:INFLUENCE]->()
WITH a, count(*) AS influences
WHERE influences > 20
RETURN a

// 2. Ego top-50 direct neighbors
MATCH (center:Artist {common_name:"The Beatles"})
-[r:INFLUENCE]->(nbr:Artist)
WITH center, nbr, r
ORDER BY r.weight DESC
LIMIT 50
RETURN center, r, nbr

// 3. Top 50 artists by out-degree
CALL {
  MATCH (a:Artist)-[:INFLUENCE]->()
  RETURN a, count(*) AS outdeg
  ORDER BY outdeg DESC
  LIMIT 50
}
WITH collect(a) AS topHubs
UNWIND topHubs AS hub
MATCH (hub)-[r:INFLUENCE]->(other:Artist)
WHERE other IN topHubs
RETURN hub, r, other

// 4. High-Weight Links (w ≥ 5)
MATCH p=(a:Artist)-[r:INFLUENCE]->(b:Artist)
WHERE coalesce(r.weight,0) >= 5
RETURN p
LIMIT 2000

// 5. Ego – 2 hops (by name)
MATCH (center:Artist {common_name:"The Beatles"})
OPTIONAL MATCH p=(center)-[:INFLUENCE*1..2]-(nbr:Artist)
RETURN p
LIMIT 2000

// 6. Largest component (2 hops)
// find the largest WCC id
MATCH (a:Artist)
WITH a.wccId AS cid, count(*) AS size
ORDER BY size DESC LIMIT 1

// draw a manageable slice of that component (paths up to 2 hops)
MATCH p = (x:Artist {wccId: cid})-[:INFLUENCE*1..2]-(y:Artist {wccId: cid})
RETURN p
LIMIT 3000;     // raise/lower to taste