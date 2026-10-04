# Plant Nursery Sales and Propagation Database

## 1. Project Overview

This project implements a PostgreSQL database for managing the propagation, growth-stage history, stock, and sales of plants in a nursery.

The database is designed around six core entities:

- `species` — stores plant species information.
- `growth_stage` — defines the stages through which a propagated plant batch can progress.
- `propagation_batch` — stores each batch produced by the nursery.
- `batch_stage_history` — records the movement of each batch through growth stages and the quantity surviving at each stage.
- `sale` — stores sale-level information such as date, sale type, and customer.
- `sale_item` — stores the individual batches and quantities included in each sale.

The database supports the five main business questions in the case study:

1. How much saleable stock is available per species?
2. Which batches have stayed in one growth stage for too long?
3. How do retail sales compare with bulk sales each month?
4. What is the survival rate of each propagation batch?
5. Which five species generated the most revenue?

---

## 2. Technology

- Database: PostgreSQL
- Database management interface: pgAdmin 4
- SQL used for: schema creation, constraints, seed data, analysis queries, joins, aggregation, subqueries, CTEs, and window functions where applicable.

---

## 3. Database Design

### 3.1 `species`

Stores information that describes a plant species.

Important attributes:

- `species_id` — primary key.
- `common_name` — common name of the species.
- `scientific_name` — scientific name.
- `category` — broad category such as Flowering, Indoor, Herb, Fruit, or Succulent.

`common_name` and `scientific_name` are unique so that the same species is not accidentally inserted multiple times.

### 3.2 `growth_stage`

Stores the definitions of nursery growth stages.

Important attributes:

- `stage_id` — primary key.
- `stage_name` — name of the stage.
- `stage_order` — order of the stage in the growth process.
- `max_days` — expected maximum number of days for that stage.

The stage definition is separated from the history table because the meaning and expected duration of a stage should be stored once.

### 3.3 `propagation_batch`

Represents a batch of plants produced through propagation.

Important attributes:

- `batch_id` — primary key.
- `batch_code` — unique business identifier.
- `species_id` — foreign key to `species`.
- `propagation_date`.
- `initial_quantity`.
- `notes`.

A species can have multiple batches, while each batch belongs to one species.

### 3.4 `batch_stage_history`

Records the history of a propagation batch as it moves through growth stages.

Important attributes:

- `batch_stage_id` — primary key.
- `batch_id` — foreign key to `propagation_batch`.
- `stage_id` — foreign key to `growth_stage`.
- `entered_at`.
- `exited_at`.
- `quantity_at_entry`.
- `quantity_at_exit`.

This table is necessary because a batch can pass through multiple stages over time.

A partial unique index ensures that a batch can have only one active/current stage at a time:

```sql
CREATE UNIQUE INDEX uq_active_batch_stage
ON batch_stage_history(batch_id)
WHERE exited_at IS NULL;
```

### 3.5 `sale`

Stores information about a sales transaction.

Important attributes:

- `sale_id` — primary key.
- `sale_date`.
- `sale_type` — restricted to `RETAIL` or `BULK`.
- `customer_name`.

### 3.6 `sale_item`

Stores the individual items included in a sale.

Important attributes:

- `sale_item_id` — primary key.
- `sale_id` — foreign key to `sale`.
- `batch_id` — foreign key to `propagation_batch`.
- `quantity`.
- `unit_price`.

A separate sale-item table allows one sale to contain multiple batches and quantities.

---

## 4. Main Relationships

The database uses the following cardinalities:

### Species → Propagation Batch

**1:N**

One species can have many propagation batches, but each propagation batch belongs to one species.

### Propagation Batch → Batch Stage History

**1:N**

One propagation batch can have multiple stage-history records as it progresses through the nursery.

### Growth Stage → Batch Stage History

**1:N**

One growth-stage definition can be referenced by many batch-stage history records.

### Sale → Sale Item

**1:N**

One sale can contain multiple sale items.

### Propagation Batch → Sale Item

**1:N**

A batch can appear in multiple sale items because portions of the batch may be sold through different transactions.

---

## 5. Design Decisions

### 5.1 Separate `sale` and `sale_item`

A sale can contain multiple plant batches. Keeping all sale information in one table would create repeating groups or duplicate sale-level information.

Therefore:

- `sale` stores transaction-level information.
- `sale_item` stores individual items.

**Alternative rejected:** storing one batch, quantity, and price directly in `sale`.

**Reason rejected:** this would restrict a sale to one item or require repeated columns such as `batch_1`, `batch_2`, etc., which violates good relational design.

---

### 5.2 Separate `species` from `propagation_batch`

Species information describes the species, not an individual propagation batch.

**Alternative rejected:** storing `common_name`, `scientific_name`, and `category` directly in every batch.

**Reason rejected:** the same species information would be repeated across multiple batches and could create update anomalies.

---

### 5.3 Separate `growth_stage` from `batch_stage_history`

`growth_stage` defines what a stage means, while `batch_stage_history` records when a particular batch entered and left that stage.

**Alternative rejected:** storing stage name, order, and maximum days directly in every history record.

**Reason rejected:** stage definitions would be duplicated across many batches.

---

### 5.4 Use a stage-history table instead of a single current-stage column

A batch needs historical information because survival and stage-duration analysis depend on knowing previous stages.

**Alternative rejected:** storing only:

```text
batch_id
current_stage
current_quantity
```

**Reason rejected:** this would lose the batch's previous stages, entry/exit dates, and historical quantities.

---

### 5.5 Use `batch_stage_history` for quantity tracking

The project stores `quantity_at_entry` and `quantity_at_exit` for each stage.

This allows survival to be calculated from the propagation history instead of maintaining a separate manually updated survival field.

**Alternative rejected:** storing only a single `survival_rate` column in `propagation_batch`.

**Reason rejected:** a stored percentage could become inconsistent with the actual quantities.

---

### 5.6 Calculate saleable stock instead of storing it

Saleable stock is derived from the quantity entering the current Saleable stage minus quantities sold from that batch.

**Alternative rejected:** storing a permanent `saleable_stock` column.

**Reason rejected:** the value is derived from existing data and could become inconsistent whenever a sale occurs.

---

### 5.7 Use surrogate primary keys

The tables use generated identity columns such as `species_id`, `batch_id`, and `sale_id` as primary keys.

**Alternative rejected:** using descriptive attributes such as names or dates as primary keys.

**Reason rejected:** descriptive values can change and may be long or difficult to use reliably as references. Stable generated identifiers make relationships simpler.

---

### 5.8 Keep `batch_code` as a separate unique business identifier

`batch_id` is the internal primary key, while `batch_code` represents a human-readable business identifier such as:

```text
ALV-2026-001
```

**Alternative rejected:** using `batch_code` as the only primary key.

**Reason rejected:** keeping a stable surrogate primary key separate from a business identifier makes foreign-key relationships simpler while still enforcing uniqueness of the business code.

---

### 5.9 Use `CHECK` constraints for domain rules

Examples include:

```sql
sale_type IN ('RETAIL', 'BULK')
```

and positive quantities.

**Reason:** invalid values should be rejected at the database level rather than relying entirely on application code.

---

### 5.10 Use foreign keys and referential actions

Foreign keys enforce valid relationships between tables.

`ON DELETE CASCADE` is used where dependent records should disappear with their parent, such as:

- sale → sale_item
- propagation_batch → batch_stage_history

`ON DELETE RESTRICT` is used where deleting the parent could invalidate important historical/business records, such as:

- species → propagation_batch
- growth_stage → batch_stage_history
- propagation_batch → sale_item

---

## 6. Normalization

The database was normalized through:

**UNF → 1NF → 2NF → 3NF**

The final schema was then checked for **BCNF**.

### UNF

The hypothetical starting design contained repeating groups such as multiple sale items and multiple stage-history records.

### 1NF

Repeating groups were removed and values were made atomic.

### 2NF

Partial dependencies were removed by separating sale-level, batch-level, and sale-line information.

### 3NF

Transitive dependencies were removed by separating species definitions and growth-stage definitions from batches and stage-history records.

### BCNF

The final relations were checked using their functional dependencies, primary keys, and unique constraints. The final design satisfies BCNF under the dependencies identified for this database.

The complete normalization working is provided separately in:

`Normalization_Plant_Nursery_Database.pdf`

---

## 7. Constraints and Data Integrity

The schema uses:

- Primary keys
- Foreign keys
- `NOT NULL`
- `UNIQUE`
- `CHECK`
- Partial unique index
- Referential actions
- Indexes for commonly joined/filtered columns

Examples of enforced rules include:

- Species names cannot be duplicated.
- Batch codes cannot be duplicated.
- Quantities must be positive where appropriate.
- Sale type must be `RETAIL` or `BULK`.
- A stage cannot have an exit date before its entry date.
- Exit quantity cannot exceed entry quantity.
- A batch can have only one active/current stage.

---

## 8. Query Coverage

The project includes a `queries.sql` file containing the SQL queries developed for the database and their corresponding outputs.

The queries cover the required SQL concepts, including:

- Filtering with `WHERE`
- Sorting with `ORDER BY`
- Aggregate functions
- `GROUP BY`
- `HAVING`
- `JOIN`
- `LEFT JOIN`
- Subqueries
- Conditional logic using `CASE`
- `COALESCE`
- CTEs
- Date-based analysis
- Window functions where applicable
- Business analysis queries

The five primary business questions are also answered in the query set.

---

## 9. Seed Data

The database contains realistic sample data rather than only a few demonstration rows.

The current seed data includes:

- 10 species
- 5 growth stages
- 12 propagation batches
- 57 batch-stage history records
- 15 sales
- 27 sale items

The data intentionally includes batches at different stages and with different survival quantities so that the analytical queries produce meaningful results.

---

## 10. Project Files

Recommended final project structure:

```text
Plant_Nursery_Database/
│
├── schema.sql
├── seed.sql
├── queries.sql
├── README.md
├── ER_Diagram.png
├── Normalization_Plant_Nursery_Database.pdf
│
└── query_outputs/
    ├── Q01.csv
    ├── Q02.csv
    ├── Q03.csv
    ├── ...
    ├── Q29.csv
    ├── Q30.csv
    └── Q31.csv
```

`Q30` returned zero rows. This is a valid result because that query checks for invalid quantity transitions, and no such invalid records exist in the seeded database.

---

## 11. How to Recreate the Database

Run the files in this order:

### Step 1 — Create the schema

Run:

```text
schema.sql
```

This creates the tables, constraints, indexes, and relationships.

### Step 2 — Insert the sample data

Run:

```text
seed.sql
```

This populates the database.

### Step 3 — Run the analysis queries

Run the queries in:

```text
queries.sql
```

The query output files in `query_outputs/` contain the saved PostgreSQL/pgAdmin results.

---

## 12. Conclusion

The final database separates independent entities and transactional/history data into appropriate relations, maintains referential integrity through primary and foreign keys, prevents invalid data through constraints, and supports the required nursery stock, propagation, survival, and sales analysis.

The design is normalized to 3NF and has been checked for BCNF.
