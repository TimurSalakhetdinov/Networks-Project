// Import artists from CSV file into Neo4j database
//        0 · (recommended) fast lookup indexes / constraints
CREATE CONSTRAINT artist_id_unique IF NOT EXISTS
FOR (a:Artist)
REQUIRE a.id IS UNIQUE;

//        1 · batch import  (commit every 2 000 rows)
:auto
CALL {
  LOAD CSV WITH HEADERS FROM 'file:///neo4j_artists.csv' AS row
  WITH row
  WHERE trim(row.artist_id) <> ''

  WITH
      toInteger(trim(row.artist_id)) AS artistId,
      trim(row.common_name)          AS cname,
      trim(row.aliases)              AS aliases,
      trim(row.artist_type)          AS atype,
      trim(row.home_country)         AS country,
      CASE trim(row.birth_year)             WHEN '' THEN NULL ELSE toInteger(row.birth_year)             END AS by,
      CASE trim(row.death_year)             WHEN '' THEN NULL ELSE toInteger(row.death_year)             END AS dy,
      trim(row.member_of)           AS member_of,
      CASE trim(row.RS_Ranking)             WHEN '' THEN NULL ELSE toInteger(row.RS_Ranking)             END AS rsr,
      CASE trim(row.allmusic_Ranking)       WHEN '' THEN NULL ELSE toInteger(row.allmusic_Ranking)       END AS amr,
      CASE trim(row.year_of_first_org_perf) WHEN '' THEN NULL ELSE toInteger(row.year_of_first_org_perf) END AS yop,
      trim(row.wiki_url)            AS wiki,
      trim(row.qid)                 AS qid,
      trim(row.short_bio)           AS bio

  MERGE (a:Artist {artist_id: artistId})
  SET  a += {
        common_name:            cname,
        aliases:                aliases,
        artist_type:            atype,
        home_country:           country,
        birth_year:             by,
        death_year:             dy,
        member_of:              member_of,
        RS_Ranking:             rsr,
        allmusic_Ranking:       amr,
        year_of_first_org_perf: yop,
        wiki:                   CASE wiki WHEN '' THEN NULL ELSE wiki END,
        qid:                    CASE qid  WHEN '' THEN NULL ELSE qid  END,
        short_bio:              CASE bio WHEN '' THEN NULL ELSE bio END
      }
} IN TRANSACTIONS OF 2000 ROWS

// node counts
MATCH (a:Artist)  RETURN count(*) AS artists;