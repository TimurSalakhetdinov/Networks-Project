// Add constraint of uniqueness before importing data
CREATE CONSTRAINT artist_id_unique IF NOT EXISTS
FOR (a:Artist)
REQUIRE a.artist_id IS UNIQUE;

CREATE CONSTRAINT song_id_unique IF NOT EXISTS
FOR (s:Song)
REQUIRE s.song_id IS UNIQUE;

CREATE CONSTRAINT cover_id_unique IF NOT EXISTS
FOR (c:Cover)
REQUIRE c.cover_id IS UNIQUE;

CREATE CONSTRAINT release_id_unique IF NOT EXISTS
FOR (r:Release)
REQUIRE r.release_id IS UNIQUE;

// Check constraints
SHOW CONSTRAINTS;

// Add these settings to the Neo4j configuration
dbms.memory.heap.initial_size=4G
dbms.memory.heap.max_size=4G
dbms.memory.pagecache.size=512m
dbms.memory.transaction.global_max_size=2G

// Add CSV files to import folder of Neo4j