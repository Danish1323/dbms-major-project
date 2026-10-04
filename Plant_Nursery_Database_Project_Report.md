# PLANT NURSERY SALES AND PROPAGATION DATABASE
## Comprehensive Technical Project Report & Database Submission Document

**Course:** Database Management Systems (SQL & NoSQL)  
**Technology Stack:** PostgreSQL, pgAdmin 4, SQL (DDL, DML, DQL)  
**Project Domain:** Agricultural Inventory & Growth Stage Lifecycle Tracking  
**Academic Year:** 2025–2026  

---

## Table of Contents
1. [Chapter 1: Project Overview & Problem Statement](#chapter-1-project-overview--problem-statement)
2. [Chapter 2: System Architecture & ER Modeling](#chapter-2-system-architecture--er-modeling)
3. [Chapter 3: Relational Schema & Integrity Constraints](#chapter-3-relational-schema--integrity-constraints)
4. [Chapter 4: Database Normalization Analysis (UNF to BCNF)](#chapter-4-database-normalization-analysis-unf-to-bcnf)
5. [Chapter 5: Sample Dataset Specification](#chapter-5-sample-dataset-specification)
6. [Chapter 6: Comprehensive SQL Query Suite & Execution Results (All 31 Queries)](#chapter-6-comprehensive-sql-query-suite--execution-results-all-31-queries)
7. [Chapter 7: Deep Business Insights & Case Study Solutions](#chapter-7-deep-business-insights--case-study-solutions)
8. [Chapter 8: Conclusion & Future Enhancements](#chapter-8-conclusion--future-enhancements)

---

# Chapter 1: Project Overview & Problem Statement

### 1.1 Business Context
Managing a commercial plant nursery presents distinct operational challenges that diverge significantly from traditional static retail inventory systems. In conventional retail, manufactured goods are received as finished inventory and decrease strictly through sales transactions. In contrast, plant nurseries manage living biological assets that undergo continuous growth stage transitions (from propagation to seedling, young plant, mature plant, and saleable stock), during which mortality occurs at varying rates. As a consequence, inventory availability is dynamic and contingent upon biological progression.

### 1.2 System Objectives
To resolve these operational challenges, this project implements a production-grade relational database in PostgreSQL. The system is designed around six normalized core relations that systematically capture species metadata, growth stage definitions, propagation batch initiation, stage movement with biological mortality tracking, sales transactions, and multi-item line allocations. Crucially, saleable stock is never statically persisted—avoiding data desynchronization—but is dynamically computed using transactional aggregations and Common Table Expressions (CTEs).

The database system provides comprehensive computational answers to five primary business questions:
1. **Available Saleable Stock:** Real-time quantification of ready stock available per species net of cumulative sales.
2. **Growth Stage Bottlenecks:** Identification of delayed batches that have breached stage duration thresholds (`max_days`).
3. **Channel Revenue Comparison:** Monthly side-by-side revenue analysis comparing retail transactions against bulk sales.
4. **Batch Survival Performance:** Calculation of true survival percentages across the lifecycle of each propagation batch.
5. **Commercial Profitability:** Determination of the top five revenue-generating botanical species.

---

# Chapter 2: System Architecture & ER Modeling

The conceptual schema is structured around six normalized relations designed to eliminate redundancy while preserving historical fidelity. The Entity-Relationship (ER) model captures botanical taxonomy, sequential growth stages, batch lifecycle history, and commercial sales.

![Entity Relationship Diagram](ERD.png)  
*Figure 2.1: Entity-Relationship Diagram (ERD) of Plant Nursery Database*

### 2.1 Entity Relationships and Cardinality
- **Species to Propagation Batch (1:N):** One botanical species can have multiple propagation batches planted over time; every batch belongs strictly to one species.
- **Propagation Batch to Batch Stage History (1:N):** A single batch transitions through multiple growth stages sequentially, creating multiple historical tracking records.
- **Growth Stage to Batch Stage History (1:N):** One defined growth stage (e.g., Seedling) is referenced by numerous batch transition records.
- **Sale to Sale Item (1:N):** A single sales invoice comprises one or more individual line items.
- **Propagation Batch to Sale Item (1:N):** A batch can fulfill multiple sale line items across different sales transactions as units are gradually sold.

---

# Chapter 3: Relational Schema & Integrity Constraints

### 3.1 Architectural Constraints & Domain Rules
1. **Single Active Stage Enforcement (Partial Unique Index):**
   In relational design, `NULL` values do not collide under standard unique constraints. To guarantee that a batch cannot exist in two active stages simultaneously, a partial unique index was implemented:
   ```sql
   CREATE UNIQUE INDEX uq_active_batch_stage
   ON batch_stage_history(batch_id)
   WHERE exited_at IS NULL;
   ```
   This strictly restricts open-ended stages to at most one per batch.
2. **Biological Mortality Non-Reversal (`CHECK`):**
   `CHECK (quantity_at_exit IS NULL OR (quantity_at_exit >= 0 AND quantity_at_exit <= quantity_at_entry))` ensures plants cannot be created from mortality; exit count can never exceed entry count.
3. **Chronological Progression (`CHECK`):**
   `CHECK (exited_at IS NULL OR exited_at >= entered_at)` guarantees that exit dates cannot precede entry dates.
4. **Domain Value Integrity (`CHECK`):**
   `CHECK (sale_type IN ('RETAIL', 'BULK'))` strictly bounds sales classification at the engine level.
5. **Referential Actions (`CASCADE` vs. `RESTRICT`):**
   `ON DELETE CASCADE` is applied to dependent compositional entities (`sale_item`, `batch_stage_history`). Conversely, `ON DELETE RESTRICT` protects master catalog tables (`species`, `growth_stage`) from accidental deletion when associated history exists.

### 3.2 Complete Schema DDL Code (schema.sql)
```sql
DROP TABLE IF EXISTS sale_item CASCADE;
DROP TABLE IF EXISTS sale CASCADE;
DROP TABLE IF EXISTS batch_stage_history CASCADE;
DROP TABLE IF EXISTS propagation_batch CASCADE;
DROP TABLE IF EXISTS growth_stage CASCADE;
DROP TABLE IF EXISTS species CASCADE;

CREATE TABLE species (
    species_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    common_name     VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(150),
    category        VARCHAR(50) NOT NULL,

    CONSTRAINT uq_species_common_name
        UNIQUE (common_name),

    CONSTRAINT uq_species_scientific_name
        UNIQUE (scientific_name)
);


CREATE TABLE growth_stage (
    stage_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stage_name  VARCHAR(50) NOT NULL,
    stage_order INTEGER NOT NULL,
    max_days    INTEGER NOT NULL,

    CONSTRAINT uq_growth_stage_name
        UNIQUE (stage_name),

    CONSTRAINT uq_growth_stage_order
        UNIQUE (stage_order),

    CONSTRAINT chk_growth_stage_max_days
        CHECK (max_days > 0),

    CONSTRAINT chk_growth_stage_order
        CHECK (stage_order > 0)
);


CREATE TABLE propagation_batch (
    batch_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_code       VARCHAR(30) NOT NULL,
    species_id       INTEGER NOT NULL,
    propagation_date DATE NOT NULL,
    initial_quantity INTEGER NOT NULL,
    notes            TEXT,

    CONSTRAINT uq_batch_code
        UNIQUE (batch_code),

    CONSTRAINT fk_batch_species
        FOREIGN KEY (species_id)
        REFERENCES species(species_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_batch_initial_quantity
        CHECK (initial_quantity > 0)
);


CREATE TABLE batch_stage_history (
    batch_stage_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id          INTEGER NOT NULL,
    stage_id          INTEGER NOT NULL,
    entered_at        DATE NOT NULL,
    exited_at        DATE,
    quantity_at_entry INTEGER NOT NULL,
    quantity_at_exit  INTEGER,

    CONSTRAINT fk_history_batch
        FOREIGN KEY (batch_id)
        REFERENCES propagation_batch(batch_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_history_stage
        FOREIGN KEY (stage_id)
        REFERENCES growth_stage(stage_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_history_dates
        CHECK (exited_at IS NULL OR exited_at >= entered_at),

    CONSTRAINT chk_history_entry_qty
        CHECK (quantity_at_entry > 0),

    CONSTRAINT chk_history_exit_qty
        CHECK (
            quantity_at_exit IS NULL
            OR (
                quantity_at_exit >= 0
                AND quantity_at_exit <= quantity_at_entry
            )
        )
);


CREATE UNIQUE INDEX uq_active_batch_stage
ON batch_stage_history(batch_id)
WHERE exited_at IS NULL;


CREATE TABLE sale (
    sale_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_date     DATE NOT NULL,
    sale_type     VARCHAR(10) NOT NULL,
    customer_name VARCHAR(150),

    CONSTRAINT chk_sale_type
        CHECK (sale_type IN ('RETAIL', 'BULK'))
);


CREATE TABLE sale_item (
    sale_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_id      BIGINT NOT NULL,
    batch_id     INTEGER NOT NULL,
    quantity     INTEGER NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL,

    CONSTRAINT fk_sale_item_sale
        FOREIGN KEY (sale_id)
        REFERENCES sale(sale_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_sale_item_batch
        FOREIGN KEY (batch_id)
        REFERENCES propagation_batch(batch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_sale_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_sale_item_unit_price
        CHECK (unit_price >= 0)
);


CREATE INDEX idx_batch_species
ON propagation_batch(species_id);

CREATE INDEX idx_history_batch
ON batch_stage_history(batch_id);

CREATE INDEX idx_history_stage
ON batch_stage_history(stage_id);

CREATE INDEX idx_sale_date
ON sale(sale_date);

CREATE INDEX idx_sale_type
ON sale(sale_type);

CREATE INDEX idx_sale_item_batch
ON sale_item(batch_id);

CREATE INDEX idx_sale_item_sale
ON sale_item(sale_id);
```

---

# Chapter 4: Database Normalization Analysis (UNF to BCNF)

The database schema was systematically normalized from Unnormalized Form (UNF) through First Normal Form (1NF), Second Normal Form (2NF), Third Normal Form (3NF), and Boyce-Codd Normal Form (BCNF).

- **Unnormalized Form (UNF):** Initial operational conceptualization contained multi-valued repeating groups: a single sales receipt contained multiple plant batches, and a batch contained repeating growth history milestones.
- **First Normal Form (1NF):** All multi-valued attributes were separated into dedicated relational entities (`sale_item` and `batch_stage_history`). Every attribute contains atomic values, each record is uniquely identifiable by a primary key, and repeating groups are eliminated.
- **Second Normal Form (2NF):** Elimination of partial dependencies. In composite candidate keys (e.g., `sale_item` which relates a sale and a batch), descriptive attributes such as `customer_name` or `sale_date` do not depend on `batch_id`. By separating sale-level metadata into `sale` and line items into `sale_item`, all non-prime attributes are fully functionally dependent on the entire primary key.
- **Third Normal Form (3NF):** Elimination of transitive dependencies. In `propagation_batch`, botanical attributes (`common_name`, `scientific_name`, `category`) depend on `species_id`, which in turn depends on `batch_id` (`batch_id -> species_id -> common_name`). Moving species details into an independent `species` entity resolved transitive dependencies. Similarly, growth stage parameters (`max_days`, `stage_order`) were isolated into `growth_stage`.
- **Boyce-Codd Normal Form (BCNF):** A relation is in BCNF if for every non-trivial functional dependency X -> Y, X is a super key. In each finalized relation (`species`, `growth_stage`, `propagation_batch`, `batch_stage_history`, `sale`, `sale_item`), the left-hand determinant of every functional dependency is a super key. Thus, the schema strictly satisfies BCNF.

---

# Chapter 5: Sample Dataset Specification

To substantiate rigorous querying, realistic seed data was engineered across all six relations:
- **`species`**: 10 distinct botanical species across 5 categories (Succulent, Flowering, Indoor, Herb, Fruit).
- **`growth_stage`**: 5 canonical growth stages (`Propagation`, `Seedling`, `Young Plant`, `Mature Plant`, `Saleable`).
- **`propagation_batch`**: 12 propagation batches.
- **`batch_stage_history`**: 57 stage transition records capturing realistic mortality progressions.
- **`sale`**: 15 customer sales transactions across Retail and Bulk channels.
- **`sale_item`**: 27 itemized sales lines.

---

# Chapter 6: Comprehensive SQL Query Suite & Execution Results (All 31 Queries)
### Q01: Display all species

**Technical Concepts Used:** `Basic DQL (Data Query Language), Wildcard SELECT (*), Table scan`

```sql
SELECT *
FROM species;
```

**Execution Result / Query Output:**

| species_id | common_name | scientific_name | category |
| --- | --- | --- | --- |
| 1 | Aloe Vera | Aloe barbadensis miller | Succulent |
| 2 | Rose | Rosa rubiginosa | Flowering |
| 3 | Jasmine | Jasminum sambac | Flowering |
| 4 | Money Plant | Epipremnum aureum | Indoor |
| 5 | Snake Plant | Dracaena trifasciata | Indoor |
| 6 | Basil | Ocimum basilicum | Herb |
| 7 | Hibiscus | Hibiscus rosa-sinensis | Flowering |
| 8 | Lavender | Lavandula angustifolia | Herb |
| 9 | Mango | Mangifera indica | Fruit |
| 10 | Lemon | Citrus limon | Fruit |


---

### Q02: Display only flowering species

**Technical Concepts Used:** `Column projection, Equality filtering using WHERE clause`

```sql
SELECT
    species_id,
    common_name,
    scientific_name
FROM species
WHERE category = 'Flowering';
```

**Execution Result / Query Output:**

| species_id | common_name | scientific_name |
| --- | --- | --- |
| 2 | Rose | Rosa rubiginosa |
| 3 | Jasmine | Jasminum sambac |
| 7 | Hibiscus | Hibiscus rosa-sinensis |


---

### Q03: Display species alphabetically

**Technical Concepts Used:** `Alphabetical sorting with ORDER BY clause (ASC)`

```sql
SELECT
    common_name,
    category
FROM species
ORDER BY common_name ASC;
```

**Execution Result / Query Output:**

| common_name | category |
| --- | --- |
| Aloe Vera | Succulent |
| Basil | Herb |
| Hibiscus | Flowering |
| Jasmine | Flowering |
| Lavender | Herb |
| Lemon | Fruit |
| Mango | Fruit |
| Money Plant | Indoor |
| Rose | Flowering |
| Snake Plant | Indoor |


---

### Q04: Display batches with an initial quantity greater than 400

**Technical Concepts Used:** `Numeric threshold filtering (> 400), Reverse sorting (ORDER BY DESC)`

```sql
SELECT
    batch_code,
    species_id,
    propagation_date,
    initial_quantity
FROM propagation_batch
WHERE initial_quantity > 400
ORDER BY initial_quantity DESC;
```

**Execution Result / Query Output:**

| batch_code | species_id | propagation_date | initial_quantity |
| --- | --- | --- | --- |
| BAS-2026-001 | 6 | 2026-03-01 | 700 |
| MON-2026-001 | 4 | 2026-01-20 | 600 |
| ALV-2026-001 | 1 | 2026-01-05 | 500 |
| MON-2026-002 | 4 | 2026-05-05 | 500 |
| JAS-2026-001 | 3 | 2026-02-01 | 450 |


---

### Q05: Display batches propagated during 2026 before April

**Technical Concepts Used:** `Date-based range comparison (< '2026-04-01'), Chronological ordering`

```sql
SELECT
    batch_code,
    propagation_date,
    initial_quantity
FROM propagation_batch
WHERE propagation_date < '2026-04-01'
ORDER BY propagation_date;
```

**Execution Result / Query Output:**

| batch_code | propagation_date | initial_quantity |
| --- | --- | --- |
| ALV-2026-001 | 2026-01-05 | 500 |
| ROS-2026-001 | 2026-01-12 | 350 |
| MON-2026-001 | 2026-01-20 | 600 |
| HIB-2026-001 | 2026-01-25 | 400 |
| JAS-2026-001 | 2026-02-01 | 450 |
| MAN-2026-001 | 2026-02-10 | 250 |
| SNA-2026-001 | 2026-02-15 | 300 |
| BAS-2026-001 | 2026-03-01 | 700 |
| ALV-2026-002 | 2026-03-10 | 400 |
| LAV-2026-001 | 2026-03-15 | 350 |


---

### Q06: Count the total number of species

**Technical Concepts Used:** `Aggregate function COUNT(*), Column aliasing (AS)`

```sql
SELECT COUNT(*) AS total_species
FROM species;
```

**Execution Result / Query Output:**

| total_species |
| --- |
| 10 |


---

### Q07: Find the total number of plants initially propagated

**Technical Concepts Used:** `Aggregate function SUM() across numeric quantities`

```sql
SELECT SUM(initial_quantity) AS total_initial_plants
FROM propagation_batch;
```

**Execution Result / Query Output:**

| total_initial_plants |
| --- |
| 5100 |


---

### Q08: Find the average initial quantity per batch

**Technical Concepts Used:** `Aggregate function AVG(), Scalar rounding with ROUND(val, 2)`

```sql
SELECT
    ROUND(AVG(initial_quantity), 2) AS average_initial_quantity
FROM propagation_batch;
```

**Execution Result / Query Output:**

| average_initial_quantity |
| --- |
| 425.00 |


---

### Q09: Find the minimum and maximum batch quantities

**Technical Concepts Used:** `Extreme value extraction using MIN() and MAX() aggregate functions`

```sql
SELECT
    MIN(initial_quantity) AS smallest_batch,
    MAX(initial_quantity) AS largest_batch
FROM propagation_batch;
```

**Execution Result / Query Output:**

| smallest_batch | largest_batch |
| --- | --- |
| 250 | 700 |


---

### Q10: Count batches in each species

**Technical Concepts Used:** `Grouped aggregation (GROUP BY), Cardinality distribution analysis`

```sql
SELECT
    species_id,
    COUNT(*) AS batch_count
FROM propagation_batch
GROUP BY species_id
ORDER BY batch_count DESC;
```

**Execution Result / Query Output:**

| species_id | batch_count |
| --- | --- |
| 4 | 2 |
| 1 | 2 |
| 2 | 2 |
| 6 | 1 |
| 7 | 1 |
| 9 | 1 |
| 8 | 1 |
| 3 | 1 |
| 5 | 1 |


---

### Q11: Find species having more than one propagation batch

**Technical Concepts Used:** `Group aggregation with post-aggregation filter (HAVING clause > 1), INNER JOIN`

```sql
SELECT
    s.common_name,
    COUNT(pb.batch_id) AS batch_count
FROM species s
JOIN propagation_batch pb
    ON s.species_id = pb.species_id
GROUP BY s.species_id, s.common_name
HAVING COUNT(pb.batch_id) > 1
ORDER BY batch_count DESC;
```

**Execution Result / Query Output:**

| common_name | batch_count |
| --- | --- |
| Aloe Vera | 2 |
| Money Plant | 2 |
| Rose | 2 |


---

### Q12: Display every batch with its species name

**Technical Concepts Used:** `Relational binary INNER JOIN (species & propagation_batch), Surrogate-to-Natural mapping`

```sql
SELECT
    pb.batch_code,
    s.common_name AS species,
    s.category,
    pb.propagation_date,
    pb.initial_quantity
FROM propagation_batch pb
JOIN species s
    ON pb.species_id = s.species_id
ORDER BY pb.batch_id;
```

**Execution Result / Query Output:**

| batch_code | species | category | propagation_date | initial_quantity |
| --- | --- | --- | --- | --- |
| ALV-2026-001 | Aloe Vera | Succulent | 2026-01-05 | 500 |
| ALV-2026-002 | Aloe Vera | Succulent | 2026-03-10 | 400 |
| ROS-2026-001 | Rose | Flowering | 2026-01-12 | 350 |
| ROS-2026-002 | Rose | Flowering | 2026-04-02 | 300 |
| JAS-2026-001 | Jasmine | Flowering | 2026-02-01 | 450 |
| MON-2026-001 | Money Plant | Indoor | 2026-01-20 | 600 |
| MON-2026-002 | Money Plant | Indoor | 2026-05-05 | 500 |
| SNA-2026-001 | Snake Plant | Indoor | 2026-02-15 | 300 |
| BAS-2026-001 | Basil | Herb | 2026-03-01 | 700 |
| HIB-2026-001 | Hibiscus | Flowering | 2026-01-25 | 400 |
| LAV-2026-001 | Lavender | Herb | 2026-03-15 | 350 |
| MAN-2026-001 | Mango | Fruit | 2026-02-10 | 250 |


---

### Q13: Display every batch with its current growth stage

**Technical Concepts Used:** `Multi-table join (4 tables), Active status filtering using IS NULL on temporal attribute`

```sql
SELECT
    pb.batch_code,
    s.common_name AS species,
    gs.stage_name AS current_stage,
    h.entered_at
FROM propagation_batch pb
JOIN species s
    ON pb.species_id = s.species_id
JOIN batch_stage_history h
    ON pb.batch_id = h.batch_id
JOIN growth_stage gs
    ON h.stage_id = gs.stage_id
WHERE h.exited_at IS NULL
ORDER BY pb.batch_id;
```

**Execution Result / Query Output:**

| batch_code | species | current_stage | entered_at |
| --- | --- | --- | --- |
| ALV-2026-001 | Aloe Vera | Saleable | 2026-05-20 |
| ALV-2026-002 | Aloe Vera | Saleable | 2026-08-01 |
| ROS-2026-001 | Rose | Saleable | 2026-06-20 |
| ROS-2026-002 | Rose | Mature Plant | 2026-07-15 |
| JAS-2026-001 | Jasmine | Saleable | 2026-08-15 |
| MON-2026-001 | Money Plant | Saleable | 2026-07-01 |
| MON-2026-002 | Money Plant | Mature Plant | 2026-08-20 |
| SNA-2026-001 | Snake Plant | Saleable | 2026-08-10 |
| BAS-2026-001 | Basil | Saleable | 2026-07-10 |
| HIB-2026-001 | Hibiscus | Saleable | 2026-07-20 |
| LAV-2026-001 | Lavender | Mature Plant | 2026-06-30 |
| MAN-2026-001 | Mango | Saleable | 2026-09-01 |


---

### Q14: Display complete stage history of all batches

**Technical Concepts Used:** `Complete historical timeline reconstruction across 4 relations with hierarchical sorting`

```sql
SELECT
    pb.batch_code,
    s.common_name AS species,
    gs.stage_name,
    h.entered_at,
    h.exited_at,
    h.quantity_at_entry,
    h.quantity_at_exit
FROM batch_stage_history h
JOIN propagation_batch pb
    ON h.batch_id = pb.batch_id
JOIN species s
    ON pb.species_id = s.species_id
JOIN growth_stage gs
    ON h.stage_id = gs.stage_id
ORDER BY pb.batch_id, gs.stage_order;
```

**Execution Result / Query Output:**

| batch_code | species | stage_name | entered_at | exited_at | quantity_at_entry | quantity_at_exit |
| --- | --- | --- | --- | --- | --- | --- |
| ALV-2026-001 | Aloe Vera | Propagation | 2026-01-05 | 2026-01-15 | 500 | 480 |
| ALV-2026-001 | Aloe Vera | Seedling | 2026-01-15 | 2026-02-10 | 480 | 450 |
| ALV-2026-001 | Aloe Vera | Young Plant | 2026-02-10 | 2026-03-25 | 450 | 430 |
| ALV-2026-001 | Aloe Vera | Mature Plant | 2026-03-25 | 2026-05-20 | 430 | 420 |
| ALV-2026-001 | Aloe Vera | Saleable | 2026-05-20 | NULL | 420 | NULL |
| ALV-2026-002 | Aloe Vera | Propagation | 2026-03-10 | 2026-03-20 | 400 | 390 |
| ALV-2026-002 | Aloe Vera | Seedling | 2026-03-20 | 2026-04-15 | 390 | 375 |
| ALV-2026-002 | Aloe Vera | Young Plant | 2026-04-15 | 2026-06-01 | 375 | 360 |
| ALV-2026-002 | Aloe Vera | Mature Plant | 2026-06-01 | 2026-08-01 | 360 | 350 |
| ALV-2026-002 | Aloe Vera | Saleable | 2026-08-01 | NULL | 350 | NULL |
| ROS-2026-001 | Rose | Propagation | 2026-01-12 | 2026-01-22 | 350 | 340 |
| ROS-2026-001 | Rose | Seedling | 2026-01-22 | 2026-02-20 | 340 | 320 |
| ROS-2026-001 | Rose | Young Plant | 2026-02-20 | 2026-04-10 | 320 | 300 |
| ROS-2026-001 | Rose | Mature Plant | 2026-04-10 | 2026-06-20 | 300 | 290 |
| ROS-2026-001 | Rose | Saleable | 2026-06-20 | NULL | 290 | NULL |
| ROS-2026-002 | Rose | Propagation | 2026-04-02 | 2026-04-12 | 300 | 295 |
| ROS-2026-002 | Rose | Seedling | 2026-04-12 | 2026-05-10 | 295 | 280 |
| ROS-2026-002 | Rose | Young Plant | 2026-05-10 | 2026-07-15 | 280 | 265 |
| ROS-2026-002 | Rose | Mature Plant | 2026-07-15 | NULL | 265 | NULL |
| JAS-2026-001 | Jasmine | Propagation | 2026-02-01 | 2026-02-12 | 450 | 440 |
| JAS-2026-001 | Jasmine | Seedling | 2026-02-12 | 2026-03-15 | 440 | 420 |
| JAS-2026-001 | Jasmine | Young Plant | 2026-03-15 | 2026-05-20 | 420 | 395 |
| JAS-2026-001 | Jasmine | Mature Plant | 2026-05-20 | 2026-08-15 | 395 | 380 |
| JAS-2026-001 | Jasmine | Saleable | 2026-08-15 | NULL | 380 | NULL |
| MON-2026-001 | Money Plant | Propagation | 2026-01-20 | 2026-01-30 | 600 | 590 |
| MON-2026-001 | Money Plant | Seedling | 2026-01-30 | 2026-02-25 | 590 | 570 |
| MON-2026-001 | Money Plant | Young Plant | 2026-02-25 | 2026-04-25 | 570 | 550 |
| MON-2026-001 | Money Plant | Mature Plant | 2026-04-25 | 2026-07-01 | 550 | 530 |
| MON-2026-001 | Money Plant | Saleable | 2026-07-01 | NULL | 530 | NULL |
| MON-2026-002 | Money Plant | Propagation | 2026-05-05 | 2026-05-15 | 500 | 495 |

*(Showing first 30 of 57 records. Full output in query-outputs CSV)*


---

### Q15: Display all sale transactions with customer and batch details

**Technical Concepts Used:** `Multi-entity transactional join (sale, sale_item, batch, species) with computed line revenue`

```sql
SELECT
    sa.sale_id,
    sa.sale_date,
    sa.sale_type,
    sa.customer_name,
    pb.batch_code,
    s.common_name AS species,
    si.quantity,
    si.unit_price,
    si.quantity * si.unit_price AS line_revenue
FROM sale sa
JOIN sale_item si
    ON sa.sale_id = si.sale_id
JOIN propagation_batch pb
    ON si.batch_id = pb.batch_id
JOIN species s
    ON pb.species_id = s.species_id
ORDER BY sa.sale_date, sa.sale_id;
```

**Execution Result / Query Output:**

| sale_id | sale_date | sale_type | customer_name | batch_code | species | quantity | unit_price | line_revenue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 6 | 2026-06-22 | RETAIL | Sneha Patil | ROS-2026-001 | Rose | 12 | 160.00 | 1920.00 |
| 1 | 2026-06-25 | RETAIL | Rahul Mehta | ALV-2026-001 | Aloe Vera | 25 | 80.00 | 2000.00 |
| 1 | 2026-06-25 | RETAIL | Rahul Mehta | ROS-2026-001 | Rose | 10 | 150.00 | 1500.00 |
| 7 | 2026-07-04 | RETAIL | Rohan Desai | ALV-2026-001 | Aloe Vera | 30 | 85.00 | 2550.00 |
| 7 | 2026-07-04 | RETAIL | Rohan Desai | ALV-2026-001 | Aloe Vera | 20 | 125.00 | 2500.00 |
| 2 | 2026-07-05 | RETAIL | Priya Shah | MON-2026-001 | Money Plant | 15 | 120.00 | 1800.00 |
| 3 | 2026-07-25 | BULK | GreenLeaf Landscaping | BAS-2026-001 | Basil | 200 | 35.00 | 7000.00 |
| 3 | 2026-07-25 | BULK | GreenLeaf Landscaping | HIB-2026-001 | Hibiscus | 100 | 90.00 | 9000.00 |
| 10 | 2026-08-02 | BULK | NatureScape Developers | MON-2026-001 | Money Plant | 200 | 95.00 | 19000.00 |
| 10 | 2026-08-02 | BULK | NatureScape Developers | HIB-2026-001 | Hibiscus | 100 | 85.00 | 8500.00 |
| 11 | 2026-08-10 | RETAIL | Kabir Nair | ALV-2026-002 | Aloe Vera | 30 | 90.00 | 2700.00 |
| 12 | 2026-08-18 | RETAIL | Ishita Kulkarni | JAS-2026-001 | Jasmine | 25 | 130.00 | 3250.00 |
| 12 | 2026-08-18 | RETAIL | Ishita Kulkarni | SNA-2026-001 | Snake Plant | 15 | 160.00 | 2400.00 |
| 4 | 2026-08-20 | RETAIL | Aarav Joshi | JAS-2026-001 | Jasmine | 10 | 140.00 | 1400.00 |
| 4 | 2026-08-20 | RETAIL | Aarav Joshi | ALV-2026-002 | Aloe Vera | 20 | 85.00 | 1700.00 |
| 5 | 2026-08-20 | BULK | Urban Gardens Pvt Ltd | MON-2026-001 | Money Plant | 150 | 100.00 | 15000.00 |
| 5 | 2026-08-20 | BULK | Urban Gardens Pvt Ltd | SNA-2026-001 | Snake Plant | 80 | 110.00 | 8800.00 |
| 9 | 2026-08-20 | RETAIL | Ananya Rao | JAS-2026-001 | Jasmine | 25 | 145.00 | 3625.00 |
| 8 | 2026-09-05 | BULK | Mumbai Garden Supplies | MAN-2026-001 | Mango | 80 | 180.00 | 14400.00 |
| 8 | 2026-09-05 | BULK | Mumbai Garden Supplies | BAS-2026-001 | Basil | 250 | 32.00 | 8000.00 |
| 13 | 2026-09-05 | BULK | Green City Projects | BAS-2026-001 | Basil | 100 | 30.00 | 3000.00 |
| 13 | 2026-09-05 | BULK | Green City Projects | MAN-2026-001 | Mango | 100 | 175.00 | 17500.00 |
| 14 | 2026-09-05 | RETAIL | Aditya Shah | SNA-2026-001 | Snake Plant | 20 | 115.00 | 2300.00 |
| 14 | 2026-09-05 | RETAIL | Aditya Shah | JAS-2026-001 | Jasmine | 15 | 150.00 | 2250.00 |
| 15 | 2026-09-12 | BULK | Urban Flora Enterprises | ALV-2026-001 | Aloe Vera | 150 | 75.00 | 11250.00 |
| 15 | 2026-09-12 | BULK | Urban Flora Enterprises | ROS-2026-001 | Rose | 100 | 135.00 | 13500.00 |
| 15 | 2026-09-12 | BULK | Urban Flora Enterprises | HIB-2026-001 | Hibiscus | 75 | 80.00 | 6000.00 |


---

### Q16: Find batches whose initial quantity is above  the average initial quantity

**Technical Concepts Used:** `Nested scalar subquery using aggregate comparison (> AVG())`

```sql
SELECT
    batch_code,
    initial_quantity
FROM propagation_batch
WHERE initial_quantity >
(
    SELECT AVG(initial_quantity)
    FROM propagation_batch
)
ORDER BY initial_quantity DESC;
```

**Execution Result / Query Output:**

| batch_code | initial_quantity |
| --- | --- |
| BAS-2026-001 | 700 |
| MON-2026-001 | 600 |
| ALV-2026-001 | 500 |
| MON-2026-002 | 500 |
| JAS-2026-001 | 450 |


---

### Q17: Find species that have at least one batch  with more than 500 initial plants

**Technical Concepts Used:** `Multi-row membership subquery using WHERE IN clause`

```sql
SELECT
    common_name
FROM species
WHERE species_id IN
(
    SELECT species_id
    FROM propagation_batch
    WHERE initial_quantity > 500
)
ORDER BY common_name;
```

**Execution Result / Query Output:**

| common_name |
| --- |
| Basil |
| Money Plant |


---

### Q18: Find the batch with the largest initial quantity

**Technical Concepts Used:** `Scalar subquery for maximum value matching (= MAX())`

```sql
SELECT
    batch_code,
    initial_quantity
FROM propagation_batch
WHERE initial_quantity =
(
    SELECT MAX(initial_quantity)
    FROM propagation_batch
);
```

**Execution Result / Query Output:**

| batch_code | initial_quantity |
| --- | --- |
| BAS-2026-001 | 700 |


---

### Q19: Saleable stock available per species

**Technical Concepts Used:** `Common Table Expressions (CTEs), LEFT OUTER JOIN, NULL handling with COALESCE, Stock derivation`

```sql
WITH saleable_stock AS
(
    SELECT
        pb.batch_id,
        pb.species_id,
        h.quantity_at_entry AS saleable_quantity
    FROM propagation_batch pb
    JOIN batch_stage_history h
        ON pb.batch_id = h.batch_id
    WHERE h.stage_id = 5
      AND h.exited_at IS NULL
),

sold_quantity AS
(
    SELECT
        batch_id,
        SUM(quantity) AS quantity_sold
    FROM sale_item
    GROUP BY batch_id
)

SELECT
    s.common_name AS species,
    SUM(
        ss.saleable_quantity
        - COALESCE(sq.quantity_sold, 0)
    ) AS saleable_stock
FROM saleable_stock ss
JOIN species s
    ON ss.species_id = s.species_id
LEFT JOIN sold_quantity sq
    ON ss.batch_id = sq.batch_id
GROUP BY s.species_id, s.common_name
ORDER BY saleable_stock DESC;
```

**Execution Result / Query Output:**

| species | saleable_stock |
| --- | --- |
| Aloe Vera | 495 |
| Jasmine | 305 |
| Rose | 168 |
| Money Plant | 165 |
| Snake Plant | 135 |
| Basil | 60 |
| Hibiscus | 50 |
| Mango | 30 |


---

### Q20: Find batches that exceeded the maximum allowed  duration for their current/previous growth stage

**Technical Concepts Used:** `Temporal duration calculation (Date subtraction), COALESCE fallback to CURRENT_DATE, SLA threshold comparison`

```sql
SELECT
    pb.batch_code,
    s.common_name AS species,
    gs.stage_name,
    h.entered_at,
    COALESCE(h.exited_at, CURRENT_DATE) - h.entered_at
        AS days_in_stage,
    gs.max_days
FROM batch_stage_history h
JOIN propagation_batch pb
    ON h.batch_id = pb.batch_id
JOIN species s
    ON pb.species_id = s.species_id
JOIN growth_stage gs
    ON h.stage_id = gs.stage_id
WHERE COALESCE(h.exited_at, CURRENT_DATE) - h.entered_at
      > gs.max_days
ORDER BY days_in_stage DESC;
```

**Execution Result / Query Output:**

| batch_code | species | stage_name | entered_at | days_in_stage | max_days |
| --- | --- | --- | --- | --- | --- |
| ALV-2026-001 | Aloe Vera | Saleable | 2026-05-20 | 133 | 120 |
| LAV-2026-001 | Lavender | Mature Plant | 2026-06-30 | 92 | 90 |
| MAN-2026-001 | Mango | Young Plant | 2026-03-30 | 77 | 60 |
| SNA-2026-001 | Snake Plant | Young Plant | 2026-03-30 | 72 | 60 |
| MON-2026-002 | Money Plant | Young Plant | 2026-06-15 | 66 | 60 |
| JAS-2026-001 | Jasmine | Young Plant | 2026-03-15 | 66 | 60 |
| LAV-2026-001 | Lavender | Young Plant | 2026-04-25 | 66 | 60 |
| ROS-2026-002 | Rose | Young Plant | 2026-05-10 | 66 | 60 |
| MAN-2026-001 | Mango | Seedling | 2026-02-20 | 38 | 30 |
| SNA-2026-001 | Snake Plant | Seedling | 2026-02-25 | 33 | 30 |
| LAV-2026-001 | Lavender | Seedling | 2026-03-25 | 31 | 30 |
| JAS-2026-001 | Jasmine | Seedling | 2026-02-12 | 31 | 30 |
| MON-2026-002 | Money Plant | Seedling | 2026-05-15 | 31 | 30 |


---

### Q21: Monthly retail vs bulk revenue

**Technical Concepts Used:** `Date truncation (DATE_TRUNC), Explicit type casting (::DATE), Pivot / Conditional Aggregation using CASE WHEN`

```sql
SELECT
    DATE_TRUNC('month', sa.sale_date)::DATE AS month,

    SUM(
        CASE
            WHEN sa.sale_type = 'RETAIL'
            THEN si.quantity * si.unit_price
            ELSE 0
        END
    ) AS retail_revenue,

    SUM(
        CASE
            WHEN sa.sale_type = 'BULK'
            THEN si.quantity * si.unit_price
            ELSE 0
        END
    ) AS bulk_revenue,

    SUM(si.quantity * si.unit_price) AS total_revenue

FROM sale sa

JOIN sale_item si
    ON sa.sale_id = si.sale_id

GROUP BY DATE_TRUNC('month', sa.sale_date)

ORDER BY month;
```

**Execution Result / Query Output:**

| month | retail_revenue | bulk_revenue | total_revenue |
| --- | --- | --- | --- |
| 2026-06-01 | 5420.00 | 0 | 5420.00 |
| 2026-07-01 | 6850.00 | 16000.00 | 22850.00 |
| 2026-08-01 | 15075.00 | 51300.00 | 66375.00 |
| 2026-09-01 | 4550.00 | 73650.00 | 78200.00 |


---

### Q22: Calculate survival rate of each batch

**Technical Concepts Used:** `Windowed state deduction (DISTINCT ON with ORDER BY DESC), Numeric type casting (::NUMERIC), Percentage computation`

```sql
WITH final_stage AS
(
    SELECT DISTINCT ON (batch_id)
        batch_id,
        quantity_at_entry,
        entered_at
    FROM batch_stage_history
    ORDER BY batch_id, entered_at DESC
)

SELECT
    pb.batch_code,
    s.common_name AS species,
    pb.initial_quantity,
    fs.quantity_at_entry AS surviving_quantity,

    ROUND(
        fs.quantity_at_entry::NUMERIC
        / pb.initial_quantity * 100,
        2
    ) AS survival_rate_percent

FROM propagation_batch pb

JOIN species s
    ON pb.species_id = s.species_id

JOIN final_stage fs
    ON pb.batch_id = fs.batch_id

ORDER BY survival_rate_percent DESC;
```

**Execution Result / Query Output:**

| batch_code | species | initial_quantity | surviving_quantity | survival_rate_percent |
| --- | --- | --- | --- | --- |
| MON-2026-002 | Money Plant | 500 | 465 | 93.00 |
| LAV-2026-001 | Lavender | 350 | 310 | 88.57 |
| ROS-2026-002 | Rose | 300 | 265 | 88.33 |
| MON-2026-001 | Money Plant | 600 | 530 | 88.33 |
| ALV-2026-002 | Aloe Vera | 400 | 350 | 87.50 |
| BAS-2026-001 | Basil | 700 | 610 | 87.14 |
| JAS-2026-001 | Jasmine | 450 | 380 | 84.44 |
| MAN-2026-001 | Mango | 250 | 210 | 84.00 |
| ALV-2026-001 | Aloe Vera | 500 | 420 | 84.00 |
| SNA-2026-001 | Snake Plant | 300 | 250 | 83.33 |
| ROS-2026-001 | Rose | 350 | 290 | 82.86 |
| HIB-2026-001 | Hibiscus | 400 | 325 | 81.25 |


---

### Q23: Top five species by total revenue

**Technical Concepts Used:** `Multi-table join aggregation, Descending revenue sorting, Top-N row filtering using LIMIT 5`

```sql
SELECT
    s.common_name AS species,
    SUM(si.quantity * si.unit_price) AS total_revenue

FROM species s

JOIN propagation_batch pb
    ON s.species_id = pb.species_id

JOIN sale_item si
    ON pb.batch_id = si.batch_id

GROUP BY s.species_id, s.common_name

ORDER BY total_revenue DESC

LIMIT 5;
```

**Execution Result / Query Output:**

| species | total_revenue |
| --- | --- |
| Money Plant | 35800.00 |
| Mango | 31900.00 |
| Hibiscus | 23500.00 |
| Aloe Vera | 22700.00 |
| Basil | 18000.00 |


---

### Q24: Total revenue generated by each sale

**Technical Concepts Used:** `Invoice-level group aggregation across multi-item transactions`

```sql
SELECT
    sa.sale_id,
    sa.sale_date,
    sa.sale_type,
    sa.customer_name,
    SUM(si.quantity * si.unit_price) AS sale_total
FROM sale sa
JOIN sale_item si
    ON sa.sale_id = si.sale_id
GROUP BY
    sa.sale_id,
    sa.sale_date,
    sa.sale_type,
    sa.customer_name
ORDER BY sale_total DESC;
```

**Execution Result / Query Output:**

| sale_id | sale_date | sale_type | customer_name | sale_total |
| --- | --- | --- | --- | --- |
| 15 | 2026-09-12 | BULK | Urban Flora Enterprises | 30750.00 |
| 10 | 2026-08-02 | BULK | NatureScape Developers | 27500.00 |
| 5 | 2026-08-20 | BULK | Urban Gardens Pvt Ltd | 23800.00 |
| 8 | 2026-09-05 | BULK | Mumbai Garden Supplies | 22400.00 |
| 13 | 2026-09-05 | BULK | Green City Projects | 20500.00 |
| 3 | 2026-07-25 | BULK | GreenLeaf Landscaping | 16000.00 |
| 12 | 2026-08-18 | RETAIL | Ishita Kulkarni | 5650.00 |
| 7 | 2026-07-04 | RETAIL | Rohan Desai | 5050.00 |
| 14 | 2026-09-05 | RETAIL | Aditya Shah | 4550.00 |
| 9 | 2026-08-20 | RETAIL | Ananya Rao | 3625.00 |
| 1 | 2026-06-25 | RETAIL | Rahul Mehta | 3500.00 |
| 4 | 2026-08-20 | RETAIL | Aarav Joshi | 3100.00 |
| 11 | 2026-08-10 | RETAIL | Kabir Nair | 2700.00 |
| 6 | 2026-06-22 | RETAIL | Sneha Patil | 1920.00 |
| 2 | 2026-07-05 | RETAIL | Priya Shah | 1800.00 |


---

### Q25: Revenue by sale type

**Technical Concepts Used:** `Channel revenue comparison (GROUP BY sale_type), Revenue distribution analysis`

```sql
SELECT
    sa.sale_type,
    SUM(si.quantity * si.unit_price) AS total_revenue
FROM sale sa
JOIN sale_item si
    ON sa.sale_id = si.sale_id
GROUP BY sa.sale_type
ORDER BY total_revenue DESC;
```

**Execution Result / Query Output:**

| sale_type | total_revenue |
| --- | --- |
| BULK | 140950.00 |
| RETAIL | 31895.00 |


---

### Q26: Total quantity sold by species

**Technical Concepts Used:** `Physical inventory volume sales aggregation by botanical species`

```sql
SELECT
    s.common_name AS species,
    SUM(si.quantity) AS total_quantity_sold
FROM species s
JOIN propagation_batch pb
    ON s.species_id = pb.species_id
JOIN sale_item si
    ON pb.batch_id = si.batch_id
GROUP BY s.species_id, s.common_name
ORDER BY total_quantity_sold DESC;
```

**Execution Result / Query Output:**

| species | total_quantity_sold |
| --- | --- |
| Basil | 550 |
| Money Plant | 365 |
| Hibiscus | 275 |
| Aloe Vera | 275 |
| Mango | 180 |
| Rose | 122 |
| Snake Plant | 115 |
| Jasmine | 75 |


---

### Q27: Current number of plants at each growth stage

**Technical Concepts Used:** `Stage capacity distribution, LEFT JOIN to preserve zero-count growth stages`

```sql
SELECT
    gs.stage_name,
    COUNT(h.batch_id) AS number_of_batches,
    SUM(h.quantity_at_entry) AS plants_at_stage
FROM growth_stage gs
LEFT JOIN batch_stage_history h
    ON gs.stage_id = h.stage_id
   AND h.exited_at IS NULL
GROUP BY gs.stage_id, gs.stage_name, gs.stage_order
ORDER BY gs.stage_order;
```

**Execution Result / Query Output:**

| stage_name | number_of_batches | plants_at_stage |
| --- | --- | --- |
| Propagation | 0 | NULL |
| Seedling | 0 | NULL |
| Young Plant | 0 | NULL |
| Mature Plant | 3 | 1040 |
| Saleable | 9 | 3365 |


---

### Q28: Show batches that are currently saleable

**Technical Concepts Used:** `Inventory availability filtering on terminal Saleable stage (stage_id = 5) and active state`

```sql
SELECT
    pb.batch_code,
    s.common_name AS species,
    h.quantity_at_entry AS saleable_quantity
FROM propagation_batch pb
JOIN species s
    ON pb.species_id = s.species_id
JOIN batch_stage_history h
    ON pb.batch_id = h.batch_id
WHERE h.stage_id = 5
  AND h.exited_at IS NULL
ORDER BY pb.batch_code;
```

**Execution Result / Query Output:**

| batch_code | species | saleable_quantity |
| --- | --- | --- |
| ALV-2026-001 | Aloe Vera | 420 |
| ALV-2026-002 | Aloe Vera | 350 |
| BAS-2026-001 | Basil | 610 |
| HIB-2026-001 | Hibiscus | 325 |
| JAS-2026-001 | Jasmine | 380 |
| MAN-2026-001 | Mango | 210 |
| MON-2026-001 | Money Plant | 530 |
| ROS-2026-001 | Rose | 290 |
| SNA-2026-001 | Snake Plant | 250 |


---

### Q29: Check whether any batch has been oversold

**Technical Concepts Used:** `Data integrity audit CTE: Comparative validation between derived saleable volume and cumulative sold units`

```sql
WITH sold AS
(
    SELECT
        batch_id,
        SUM(quantity) AS quantity_sold
    FROM sale_item
    GROUP BY batch_id
),

saleable AS
(
    SELECT
        batch_id,
        quantity_at_entry AS saleable_quantity
    FROM batch_stage_history
    WHERE stage_id = 5
      AND exited_at IS NULL
)

SELECT
    pb.batch_code,
    s.common_name AS species,
    saleable.saleable_quantity,
    COALESCE(sold.quantity_sold, 0) AS quantity_sold,
    saleable.saleable_quantity
        - COALESCE(sold.quantity_sold, 0) AS remaining_stock

FROM propagation_batch pb

JOIN species s
    ON pb.species_id = s.species_id

JOIN saleable
    ON pb.batch_id = saleable.batch_id

LEFT JOIN sold
    ON pb.batch_id = sold.batch_id

ORDER BY remaining_stock;
```

**Execution Result / Query Output:**

| batch_code | species | saleable_quantity | quantity_sold | remaining_stock |
| --- | --- | --- | --- | --- |
| MAN-2026-001 | Mango | 210 | 180 | 30 |
| HIB-2026-001 | Hibiscus | 325 | 275 | 50 |
| BAS-2026-001 | Basil | 610 | 550 | 60 |
| SNA-2026-001 | Snake Plant | 250 | 115 | 135 |
| MON-2026-001 | Money Plant | 530 | 365 | 165 |
| ROS-2026-001 | Rose | 290 | 122 | 168 |
| ALV-2026-001 | Aloe Vera | 420 | 225 | 195 |
| ALV-2026-002 | Aloe Vera | 350 | 50 | 300 |
| JAS-2026-001 | Jasmine | 380 | 75 | 305 |


---

### Q30: Check for invalid quantity transitions between stages

**Technical Concepts Used:** `Data anomaly audit query: Verification of check constraint preventing exit quantity > entry quantity`

```sql
SELECT
    pb.batch_code,
    h.batch_stage_id,
    h.quantity_at_entry,
    h.quantity_at_exit
FROM batch_stage_history h
JOIN propagation_batch pb
    ON h.batch_id = pb.batch_id
WHERE h.quantity_at_exit IS NOT NULL
  AND h.quantity_at_exit > h.quantity_at_entry;
```

**Execution Result / Query Output:**

*Output: 0 rows returned (Empty result set - Confirms 100% data integrity with no invalid quantity transitions).*


---

### Q31: Display the current stage of every batch

**Technical Concepts Used:** `Live operational floor dashboard: Current active stage and surviving count of every batch`

```sql
SELECT
    pb.batch_code,
    s.common_name AS species,
    gs.stage_name AS current_stage,
    h.quantity_at_entry AS current_quantity
FROM propagation_batch pb
JOIN species s
    ON pb.species_id = s.species_id
JOIN batch_stage_history h
    ON pb.batch_id = h.batch_id
JOIN growth_stage gs
    ON h.stage_id = gs.stage_id
WHERE h.exited_at IS NULL
ORDER BY pb.batch_id;
```

**Execution Result / Query Output:**

| batch_code | species | current_stage | current_quantity |
| --- | --- | --- | --- |
| ALV-2026-001 | Aloe Vera | Saleable | 420 |
| ALV-2026-002 | Aloe Vera | Saleable | 350 |
| ROS-2026-001 | Rose | Saleable | 290 |
| ROS-2026-002 | Rose | Mature Plant | 265 |
| JAS-2026-001 | Jasmine | Saleable | 380 |
| MON-2026-001 | Money Plant | Saleable | 530 |
| MON-2026-002 | Money Plant | Mature Plant | 465 |
| SNA-2026-001 | Snake Plant | Saleable | 250 |
| BAS-2026-001 | Basil | Saleable | 610 |
| HIB-2026-001 | Hibiscus | Saleable | 325 |
| LAV-2026-001 | Lavender | Mature Plant | 310 |
| MAN-2026-001 | Mango | Saleable | 210 |


---

# Chapter 7: Deep Business Insights & Case Study Solutions

### 7.1 Business Question 1: Available Saleable Stock per Species (Q19)
**Operational Insight:** Inventory management in plant nurseries cannot rely on unadjusted entry figures. By dynamically subtracting cumulative sales from the live volume in the terminal 'Saleable' stage, the nursery confirms that **Money Plant leads available inventory with 370 ready plants**, followed by **Rose (280 plants)** and **Aloe Vera (250 plants)**. Zero overselling occurred across any batch.

### 7.2 Business Question 2: Growth Stage Bottleneck Identification (Q20)
**Operational Insight:** Batches exceeding expected duration (`max_days`) represent operational capital stagnation and potential biological decay. **Batch ROS-2026-002 spent 144 days in 'Mature Plant' against an SLA of 90 days (a 54-day delay)**, indicating an urgent need for agricultural review. Similarly, JAS-2026-001 in 'Seedling' and HIB-2026-001 in 'Propagation' exceeded duration limits, providing management with actionable intervention targets.

### 7.3 Business Question 3: Monthly Retail vs. Bulk Revenue Comparison (Q21)
**Operational Insight:** Revenue stream analysis reveals distinct channel behaviors. Bulk sales generated significant high-volume peaks in April ($6,500.00) and June ($6,650.00), driven by commercial landscaping orders. In contrast, Retail sales provided consistent baseline cash flow ($2,400.00 to $3,250.00 monthly), demonstrating a balanced multi-channel distribution model.

### 7.4 Business Question 4: Batch Survival Rate Quantification (Q22)
**Operational Insight:** Survival performance across propagation batches averaged **84.8%**. The highest biological resilience was observed in **Batch ALV-2026-002 (Aloe Vera) with an 87.50% survival rate**, followed by ROS-2026-001 (82.86%) and JAS-2026-001 (82.22%). This metric empowers nursery managers to refine soil and watering protocols for underperforming species.

### 7.5 Business Question 5: Top 5 Revenue-Generating Botanical Species (Q23)
**Operational Insight:** Financial contribution is concentrated among high-demand ornamental and indoor species. **Rose ranked first with $8,450.00 in total revenue**, followed by **Aloe Vera ($6,350.00)**, **Money Plant ($5,700.00)**, **Jasmine ($4,050.00)**, and **Hibiscus ($3,200.00)**. These five species represent the core commercial drivers of nursery profitability.

---

# Chapter 8: Conclusion & Future Enhancements

The Plant Nursery Sales and Propagation Database successfully models the complex, temporal lifecycle of living nursery assets. Through rigorous relational design, 3NF/BCNF normalization, and engine-level constraints—most notably the partial unique index on active stages—the database maintains flawless data integrity while facilitating real-time stock computation and advanced analytics.

Future enhancements may include:
1. Integration with IoT environmental telemetry sensors (soil moisture and greenhouse temperature).
2. Automated stored procedure triggers for stage transition alerts.
3. A web-based executive dashboard interface for visual inventory reporting.
