// Preview a sample artist network
MATCH (a:Artist)-[:COVERED]->(s:Song)-[:COVER_OF]->(o:Song)<-[:PERFORMED]-(orig:Artist)
RETURN a.name, s.title, orig.name LIMIT 50;