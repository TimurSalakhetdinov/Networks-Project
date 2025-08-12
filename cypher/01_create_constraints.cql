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