// Add constraint of uniqueness before importing data
CREATE CONSTRAINT artist_id_unique IF NOT EXISTS
FOR (a:Artist)
REQUIRE a.artist_id IS UNIQUE;

CREATE CONSTRAINT song_perf_id_unique IF NOT EXISTS
FOR (s:Song)
REQUIRE s.perf_id IS UNIQUE;

CREATE CONSTRAINT cover_perf_id_unique IF NOT EXISTS
FOR (c:Cover)
REQUIRE c.perf_id IS UNIQUE;

CREATE CONSTRAINT release_id_unique IF NOT EXISTS
FOR (r:Release)
REQUIRE r.release_id IS UNIQUE;

// Add these settings to the Neo4j configuration
dbms.memory.heap.initial_size=4G
dbms.memory.heap.max_size=4G
dbms.memory.pagecache.size=512m
dbms.memory.transaction.global_max_size=2G

// Add CSV files to import folder of Neo4j