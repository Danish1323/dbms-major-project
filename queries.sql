-- ============================================================
-- SECTION 1: BASIC SELECT, FILTERING AND SORTING
-- ============================================================


-- Q01. Display all species

SELECT *
FROM species;


-- Q02. Display only flowering species

SELECT
    species_id,
    common_name,
    scientific_name
FROM species
WHERE category = 'Flowering';


-- Q03. Display species alphabetically

SELECT
    common_name,
    category
FROM species
ORDER BY common_name ASC;


-- Q04. Display batches with an initial quantity greater than 400

SELECT
    batch_code,
    species_id,
    propagation_date,
    initial_quantity
FROM propagation_batch
WHERE initial_quantity > 400
ORDER BY initial_quantity DESC;


-- Q05. Display batches propagated during 2026 before April

SELECT
    batch_code,
    propagation_date,
    initial_quantity
FROM propagation_batch
WHERE propagation_date < '2026-04-01'
ORDER BY propagation_date;


-- ============================================================
-- SECTION 2: AGGREGATE FUNCTIONS
-- ============================================================


-- Q06. Count the total number of species

SELECT COUNT(*) AS total_species
FROM species;


-- Q07. Find the total number of plants initially propagated

SELECT SUM(initial_quantity) AS total_initial_plants
FROM propagation_batch;


-- Q08. Find the average initial quantity per batch

SELECT
    ROUND(AVG(initial_quantity), 2) AS average_initial_quantity
FROM propagation_batch;


-- Q09. Find the minimum and maximum batch quantities

SELECT
    MIN(initial_quantity) AS smallest_batch,
    MAX(initial_quantity) AS largest_batch
FROM propagation_batch;


-- Q10. Count batches in each species

SELECT
    species_id,
    COUNT(*) AS batch_count
FROM propagation_batch
GROUP BY species_id
ORDER BY batch_count DESC;


-- Q11. Find species having more than one propagation batch

SELECT
    s.common_name,
    COUNT(pb.batch_id) AS batch_count
FROM species s
JOIN propagation_batch pb
    ON s.species_id = pb.species_id
GROUP BY s.species_id, s.common_name
HAVING COUNT(pb.batch_id) > 1
ORDER BY batch_count DESC;


-- ============================================================
-- SECTION 3: JOINS
-- ============================================================


-- Q12. Display every batch with its species name

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


-- Q13. Display every batch with its current growth stage

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


-- Q14. Display complete stage history of all batches

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


-- Q15. Display all sale transactions with customer and batch details

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


-- ============================================================
-- SECTION 4: SUBQUERIES
-- ============================================================


-- Q16. Find batches whose initial quantity is above
-- the average initial quantity

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


-- Q17. Find species that have at least one batch
-- with more than 500 initial plants

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


-- Q18. Find the batch with the largest initial quantity

SELECT
    batch_code,
    initial_quantity
FROM propagation_batch
WHERE initial_quantity =
(
    SELECT MAX(initial_quantity)
    FROM propagation_batch
);


-- ============================================================
-- SECTION 5: REQUIRED BUSINESS QUERY 1
-- HOW MUCH SALEABLE STOCK IS THERE PER SPECIES?
-- ============================================================


-- Q19. Saleable stock available per species

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


-- ============================================================
-- SECTION 6: REQUIRED BUSINESS QUERY 2
-- WHICH BATCHES HAVE STAYED IN ONE GROWTH STAGE TOO LONG?
-- ============================================================


-- Q20. Find batches that exceeded the maximum allowed
-- duration for their current/previous growth stage

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


-- ============================================================
-- SECTION 7: REQUIRED BUSINESS QUERY 3
-- HOW DID RETAIL SALES COMPARE WITH BULK SALES EACH MONTH?
-- ============================================================


-- Q21. Monthly retail vs bulk revenue

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


-- ============================================================
-- SECTION 8: REQUIRED BUSINESS QUERY 4
-- WHAT IS THE SURVIVAL RATE OF EACH PROPAGATION BATCH?
-- ============================================================


-- Q22. Calculate survival rate of each batch

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


-- ============================================================
-- SECTION 9: REQUIRED BUSINESS QUERY 5
-- WHICH FIVE SPECIES EARNED THE MOST REVENUE?
-- ============================================================


-- Q23. Top five species by total revenue

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


-- ============================================================
-- SECTION 10: ADDITIONAL BUSINESS ANALYSIS
-- ============================================================


-- Q24. Total revenue generated by each sale

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


-- Q25. Revenue by sale type

SELECT
    sa.sale_type,
    SUM(si.quantity * si.unit_price) AS total_revenue
FROM sale sa
JOIN sale_item si
    ON sa.sale_id = si.sale_id
GROUP BY sa.sale_type
ORDER BY total_revenue DESC;


-- Q26. Total quantity sold by species

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


-- Q27. Current number of plants at each growth stage

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


-- Q28. Show batches that are currently saleable

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


-- ============================================================
-- SECTION 11: DATA INTEGRITY CHECKS
-- ============================================================


-- Q29. Check whether any batch has been oversold

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


-- Q30. Check for invalid quantity transitions between stages

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


-- Q31. Display the current stage of every batch

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