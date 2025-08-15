# Artist Influence Network – Export & Analysis Guide

This project extracts an **Artist Influence Network** from Neo4j, exports it to CSV (and optionally GraphML), and loads it into Python/NetworkX for analysis.

---

## 📂 Files

| File                     | Description |
|--------------------------|-------------|
| `influence_edges.csv`    | Directed edges between artists (`src_id` → `dst_id`) with attributes (`weight`, `avg_time_gap`). |
| `artists_nodes.csv`      | Node list with artist metadata (`id`, `artist_id`, `name`, `birth_year`, `death_year`, `country`). |
| `influence.graphml`      | *(Optional)* Single GraphML file containing both nodes and edges for import into NetworkX, Gephi, or Cytoscape. |

---

## 1️⃣ Exporting from Neo4j

### **APOC configuration**
Add the following lines to your `apoc.conf` (in `<dbms-folder>/conf/`):

```properties
apoc.export.file.enabled=true
apoc.import.file.enabled=true
apoc.export.file.use_neo4j_config=true
apoc.import.file.use_neo4j_config=true
```

Restart the DBMS after saving.

---

### **Export edges (INFLUENCE relationships)**

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

---

### **Export nodes (Artists)**

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

---

### **(Optional) Export GraphML**

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

All exported files will be saved in the DBMS **`import/`** directory.

---

## 2️⃣ Loading into Python

```python
import pandas as pd
import networkx as nx

# Load data
edges = pd.read_csv("influence_edges.csv")
nodes = pd.read_csv("artists_nodes.csv")

# Create directed graph with edge attributes
G = nx.from_pandas_edgelist(
    edges,
    source="src_id",
    target="dst_id",
    edge_attr=["weight", "avg_time_gap"],
    create_using=nx.DiGraph()
)

# Attach node attributes
node_attrs = nodes.set_index("id").to_dict(orient="index")
nx.set_node_attributes(G, node_attrs)

# Sanity check
print(G.number_of_nodes(), "nodes,", G.number_of_edges(), "edges")

# Example: weighted out-degree centrality
out_strength = {
    n: sum(d.get("weight", 1) for _,_,d in G.out_edges(n, data=True))
    for n in G.nodes()
}
top10 = sorted(out_strength.items(), key=lambda x: x[1], reverse=True)[:10]
print("Top-10 by influence weight:", top10)
```

---

## 3️⃣ Analysis Ideas

- **Centrality measures:** Degree, betweenness, PageRank.
- **Communities:** Use Louvain or Girvan–Newman to find clusters.
- **Time patterns:** Analyze `avg_time_gap` between influences.
- **Visualization:** Plot in NetworkX, Gephi, or Cytoscape.

---

## 📌 Notes

- Ensure APOC is installed and enabled in Neo4j.
- The `id(a)` function is used so node IDs match between edges and nodes.
- If you can’t write to disk, use `{stream:true}` in the export call and download from the Neo4j Browser.
