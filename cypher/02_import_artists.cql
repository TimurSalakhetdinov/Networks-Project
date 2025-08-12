// Import artists from CSV file into Neo4j database
// batch import  (commit every 2 000 rows)
:auto
CALL {
  LOAD CSV WITH HEADERS FROM 'file:///neo4j_artists.csv' AS row
  WITH row
  WHERE trim(row.artist_id) <> ''

  WITH
    toInteger(trim(row.artist_id)) AS artistId,
    trim(row.common_name) AS cname,
    CASE trim(row.aliases) WHEN '' THEN NULL ELSE apoc.convert.fromJsonList(trim(row.aliases)) END AS aliases,
    trim(row.artist_type) AS atype,
    trim(row.home_country) AS country,
    CASE trim(row.birth_year) WHEN '' THEN NULL ELSE toInteger(trim(row.birth_year)) END AS by,
    CASE trim(row.death_year) WHEN '' THEN NULL ELSE toInteger(trim(row.death_year)) END AS dy,
    CASE trim(row.member_of) WHEN '' THEN NULL ELSE [x IN apoc.convert.fromJsonList(trim(row.member_of)) | toInteger(x)] END AS member_of,
    CASE trim(row.RS_Ranking) WHEN '' THEN NULL ELSE toInteger(trim(row.RS_Ranking)) END AS rsr,
    CASE trim(row.allmusic_Ranking) WHEN '' THEN NULL ELSE toInteger(trim(row.allmusic_Ranking)) END AS amr,
    CASE trim(row.year_of_first_org_perf) WHEN '' THEN NULL ELSE toInteger(trim(row.year_of_first_org_perf)) END AS yop,
    CASE trim(row.wiki_url) WHEN '' THEN NULL ELSE trim(row.wiki_url) END AS wiki,
    CASE trim(row.qid) WHEN '' THEN NULL ELSE trim(row.qid) END AS qid,
    CASE trim(row.short_bio) WHEN '' THEN NULL ELSE trim(row.short_bio) END AS bio

  MERGE (a:Artist {artist_id: artistId})
  SET a += {
    common_name: cname,
    aliases: aliases,
    artist_type: atype,
    home_country: country,
    birth_year: by,
    death_year: dy,
    member_of: member_of,
    RS_Ranking: rsr,
    allmusic_Ranking: amr,
    year_of_first_org_perf: yop,
    wiki: wiki,
    qid: qid,
    short_bio: bio
  }
} IN TRANSACTIONS OF 2000 ROWS

// node counts
MATCH (a:Artist) RETURN count(*) AS artists;