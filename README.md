# Artist Influence Network (1960–2020)  
_A network analysis of cover-song influence using SecondHandSongs and Neo4j_

> Who was the most influential music artist between 1960 and 2020?  
> We model influence as **who covers whom**, build a directed, weighted graph in **Neo4j (GDS + APOC)**, analyze it in **Cypher queries (Neo4j GDS)**, and visualize in **Neo4j Bloom**.  
> Across centrality metrics (In-Degree, PageRank, Betweenness) and a composite score, **The Beatles** emerge as the top artist.

---

## 📂 Repository Structure

```
.
├── data/
├── visuals/
├── queries_cypher/
│
├── artists_nodes.csv
├── influence_edges.csv
├── influence.graphml
├── Network Analysis Report.pdf
├── README.md
├── .gitignore
```

## 🚀 Reproduce in Neo4j (Cypher + GDS) — End‑to‑End

The full process to create the graph projection, compute centrality metrics (In-Degree, PageRank, Betweenness), transform data, and extract top artists by metric is provided as Cypher scripts in the `queries_cypher/` folder.

### K‑Means on Centrality Profiles (GDS Beta)

K-Means clustering on centrality profiles and subsequent analysis of cluster centroids can be found in the `queries_cypher/` folder.

### Bloom Views

Instructions and Cypher queries to filter nodes by cluster, style node size and color, and draw subgraphs for visualization in Neo4j Bloom are included in the `queries_cypher/` folder.

---

## 📦 Neo4j Environment

- Neo4j 5.x  
- Graph Data Science (GDS) 2.x  
- APOC 5.x  
- Neo4j Bloom (desktop or server)  

Ensure `apoc.conf` includes the following flags:

```properties
apoc.export.file.enabled=true
apoc.import.file.enabled=true
apoc.export.file.use_neo4j_config=true
apoc.import.file.use_neo4j_config=true
```

Restart Neo4j after modifying configuration.

---

## 🔧 Data Pipeline

### 1. Extract from Neo4j

We use **APOC procedures** to export nodes and edges.  
Ensure `apoc.conf` (in `<dbms-folder>/conf/`) contains:

```properties
apoc.export.file.enabled=true
apoc.import.file.enabled=true
apoc.export.file.use_neo4j_config=true
apoc.import.file.use_neo4j_config=true
```

Restart Neo4j after changes.

#### Export edges
```cypher
CALL apoc.export.csv.query(
  '
  MATCH (src:Artist)-[r:INFLUENCE]->(dst:Artist)
  RETURN id(src) AS src_id, id(dst) AS dst_id,
         r.weight AS weight, r.avg_time_gap AS avg_time_gap
  ',
  "influence_edges.csv",
  {batchSize:50000, quotes:true}
);
```

#### Export nodes
```cypher
CALL apoc.export.csv.query(
  '
  MATCH (a:Artist)
  RETURN id(a) AS id,
         a.artist_id AS artist_id,
         a.common_name AS name,
         a.birth_year AS birth_year,
         a.death_year AS death_year,
         a.home_country AS country
  ',
  "artists_nodes.csv",
  {quotes:true}
);
```

#### (Optional) Export GraphML
```cypher
CALL apoc.export.graphml.query(
  '
  MATCH (a:Artist)-[r:INFLUENCE]->(b:Artist)
  RETURN a, r, b
  ',
  "influence.graphml",
  {useTypes:true, storeNodeIds:true}
);
```

---

## 📊 Analysis Highlights

- **Centrality metrics**  
  - *In-Degree:* measures how often an artist is covered.  
  - *PageRank:* weights influence recursively.  
  - *Betweenness:* captures “bridges” in influence flow.  

- **Results (from Cypher shown above)**  
  - The Beatles dominate all metrics.  
  - Other key influencers: Bob Dylan, Elvis Presley, and Rolling Stones.  
  - Communities reveal genre clusters (rock, jazz, pop).  
  - Note: PageRank computed with **dampingFactor = 0.85**, In-Degree computed with **orientation = 'REVERSE'**.

- **Visualization (in Neo4j Bloom)**  
  - Bloom visualizations highlight “super-influencers” using force-directed layouts.  
  - Subgraphs of top-50 artists form tightly connected hubs.  

---

## 📌 Notes

- Ensure APOC is installed and enabled.  
- Node IDs are matched with `id(a)` for consistency.  
- If file export is disabled, use `{stream:true}` in APOC to download data.  

---

## 📖 References

- Dataset: [SecondHandSongs](https://secondhandsongs.com)  
- Abe (2009), Zhang et al. (2020), Simon et al. (2021) — referenced in the report.  
