// Bloom search bar
Artist-[:INFLUENCE]->Artist

// Create a Search Phrase in Bloom (Perspective -> Saved Cypher)
// Add Search Phrase: Influential Artists and Cypher:
MATCH (a:Artist)-[:INFLUENCE]->()
WITH a, count(*) AS influences
WHERE influences > 20
RETURN a