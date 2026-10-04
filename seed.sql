-- 1. SPECIES

INSERT INTO species
(common_name, scientific_name, category)
VALUES
('Aloe Vera', 'Aloe barbadensis miller', 'Succulent'),
('Rose', 'Rosa rubiginosa', 'Flowering'),
('Jasmine', 'Jasminum sambac', 'Flowering'),
('Money Plant', 'Epipremnum aureum', 'Indoor'),
('Snake Plant', 'Dracaena trifasciata', 'Indoor'),
('Basil', 'Ocimum basilicum', 'Herb'),
('Hibiscus', 'Hibiscus rosa-sinensis', 'Flowering'),
('Lavender', 'Lavandula angustifolia', 'Herb'),
('Mango', 'Mangifera indica', 'Fruit'),
('Lemon', 'Citrus limon', 'Fruit');

-- 2. GROWTH STAGES

INSERT INTO growth_stage
(stage_name, stage_order, max_days)
VALUES
('Propagation', 1, 14),
('Seedling', 2, 30),
('Young Plant', 3, 60),
('Mature Plant', 4, 90),
('Saleable', 5, 120);

-- 3. PROPAGATION BATCHES

INSERT INTO propagation_batch
(batch_code, species_id, propagation_date, initial_quantity, notes)
VALUES
('ALV-2026-001', 1, '2026-01-05', 500, 'Winter Aloe propagation'),
('ALV-2026-002', 1, '2026-03-10', 400, 'Spring Aloe batch'),

('ROS-2026-001', 2, '2026-01-12', 350, 'Red rose propagation'),
('ROS-2026-002', 2, '2026-04-02', 300, 'Mixed rose propagation'),

('JAS-2026-001', 3, '2026-02-01', 450, 'Jasmine nursery batch'),

('MON-2026-001', 4, '2026-01-20', 600, 'Indoor plant batch'),
('MON-2026-002', 4, '2026-05-05', 500, 'Summer money plant batch'),

('SNA-2026-001', 5, '2026-02-15', 300, 'Snake plant batch'),

('BAS-2026-001', 6, '2026-03-01', 700, 'Herb propagation batch'),

('HIB-2026-001', 7, '2026-01-25', 400, 'Hibiscus propagation'),

('LAV-2026-001', 8, '2026-03-15', 350, 'Lavender propagation'),

('MAN-2026-001', 9, '2026-02-10', 250, 'Mango sapling batch');

-- 4. BATCH STAGE HISTORY

-- Batch 1: ALV-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(1, 1, '2026-01-05', '2026-01-15', 500, 480),
(1, 2, '2026-01-15', '2026-02-10', 480, 450),
(1, 3, '2026-02-10', '2026-03-25', 450, 430),
(1, 4, '2026-03-25', '2026-05-20', 430, 420),
(1, 5, '2026-05-20', NULL, 420, NULL);

-- Batch 2: ALV-2026-002

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(2, 1, '2026-03-10', '2026-03-20', 400, 390),
(2, 2, '2026-03-20', '2026-04-15', 390, 375),
(2, 3, '2026-04-15', '2026-06-01', 375, 360),
(2, 4, '2026-06-01', '2026-08-01', 360, 350),
(2, 5, '2026-08-01', NULL, 350, NULL);

-- Batch 3: ROS-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(3, 1, '2026-01-12', '2026-01-22', 350, 340),
(3, 2, '2026-01-22', '2026-02-20', 340, 320),
(3, 3, '2026-02-20', '2026-04-10', 320, 300),
(3, 4, '2026-04-10', '2026-06-20', 300, 290),
(3, 5, '2026-06-20', NULL, 290, NULL);

-- Batch 4: ROS-2026-002
-- Currently stuck at Mature Plant

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(4, 1, '2026-04-02', '2026-04-12', 300, 295),
(4, 2, '2026-04-12', '2026-05-10', 295, 280),
(4, 3, '2026-05-10', '2026-07-15', 280, 265),
(4, 4, '2026-07-15', NULL, 265, NULL);

-- Batch 5: JAS-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(5, 1, '2026-02-01', '2026-02-12', 450, 440),
(5, 2, '2026-02-12', '2026-03-15', 440, 420),
(5, 3, '2026-03-15', '2026-05-20', 420, 395),
(5, 4, '2026-05-20', '2026-08-15', 395, 380),
(5, 5, '2026-08-15', NULL, 380, NULL);

-- Batch 6: MON-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(6, 1, '2026-01-20', '2026-01-30', 600, 590),
(6, 2, '2026-01-30', '2026-02-25', 590, 570),
(6, 3, '2026-02-25', '2026-04-25', 570, 550),
(6, 4, '2026-04-25', '2026-07-01', 550, 530),
(6, 5, '2026-07-01', NULL, 530, NULL);

-- Batch 7: MON-2026-002
-- Currently at Mature Plant

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(7, 1, '2026-05-05', '2026-05-15', 500, 495),
(7, 2, '2026-05-15', '2026-06-15', 495, 480),
(7, 3, '2026-06-15', '2026-08-20', 480, 465),
(7, 4, '2026-08-20', NULL, 465, NULL);

-- Batch 8: SNA-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(8, 1, '2026-02-15', '2026-02-25', 300, 290),
(8, 2, '2026-02-25', '2026-03-30', 290, 275),
(8, 3, '2026-03-30', '2026-06-10', 275, 260),
(8, 4, '2026-06-10', '2026-08-10', 260, 250),
(8, 5, '2026-08-10', NULL, 250, NULL);

-- Batch 9: BAS-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(9, 1, '2026-03-01', '2026-03-10', 700, 680),
(9, 2, '2026-03-10', '2026-04-01', 680, 650),
(9, 3, '2026-04-01', '2026-05-15', 650, 625),
(9, 4, '2026-05-15', '2026-07-10', 625, 610),
(9, 5, '2026-07-10', NULL, 610, NULL);

-- Batch 10: HIB-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(10, 1, '2026-01-25', '2026-02-05', 400, 385),
(10, 2, '2026-02-05', '2026-03-05', 385, 360),
(10, 3, '2026-03-05', '2026-05-01', 360, 340),
(10, 4, '2026-05-01', '2026-07-20', 340, 325),
(10, 5, '2026-07-20', NULL, 325, NULL);

-- Batch 11: LAV-2026-001
-- Currently at Mature Plant

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(11, 1, '2026-03-15', '2026-03-25', 350, 340),
(11, 2, '2026-03-25', '2026-04-25', 340, 325),
(11, 3, '2026-04-25', '2026-06-30', 325, 310),
(11, 4, '2026-06-30', NULL, 310, NULL);

-- Batch 12: MAN-2026-001

INSERT INTO batch_stage_history
(batch_id, stage_id, entered_at, exited_at,
 quantity_at_entry, quantity_at_exit)
VALUES
(12, 1, '2026-02-10', '2026-02-20', 250, 245),
(12, 2, '2026-02-20', '2026-03-30', 245, 230),
(12, 3, '2026-03-30', '2026-06-15', 230, 220),
(12, 4, '2026-06-15', '2026-09-01', 220, 210),
(12, 5, '2026-09-01', NULL, 210, NULL);

-- 5. SALES

INSERT INTO sale
(sale_date, sale_type, customer_name)
VALUES
('2026-06-25', 'RETAIL', 'Rahul Mehta'),
('2026-07-05', 'RETAIL', 'Priya Shah'),
('2026-07-25', 'BULK', 'GreenLeaf Landscaping'),
('2026-08-20', 'RETAIL', 'Aarav Joshi'),
('2026-08-20', 'BULK', 'Urban Gardens Pvt Ltd'),
('2026-06-22', 'RETAIL', 'Sneha Patil'),
('2026-07-04', 'RETAIL', 'Rohan Desai'),
('2026-09-05', 'BULK', 'Mumbai Garden Supplies'),
('2026-08-20', 'RETAIL', 'Ananya Rao'),
('2026-08-02', 'BULK', 'NatureScape Developers'),
('2026-08-10', 'RETAIL', 'Kabir Nair'),
('2026-08-18', 'RETAIL', 'Ishita Kulkarni'),
('2026-09-05', 'BULK', 'Green City Projects'),
('2026-09-05', 'RETAIL', 'Aditya Shah'),
('2026-09-12', 'BULK', 'Urban Flora Enterprises');

-- 6. SALE ITEMS

INSERT INTO sale_item
(sale_id, batch_id, quantity, unit_price)
VALUES

-- Sale 1
(1, 1, 25, 80.00),
(1, 3, 10, 150.00),

-- Sale 2
(2, 6, 15, 120.00),

-- Sale 3
(3, 9, 200, 35.00),
(3, 10, 100, 90.00),

-- Sale 4
(4, 2, 20, 85.00),
(4, 5, 10, 140.00),

-- Sale 5
(5, 6, 150, 100.00),
(5, 8, 80, 110.00),

-- Sale 6
(6, 3, 12, 160.00),

-- Sale 7
(7, 1, 30, 85.00),
(7, 1, 20, 125.00),

-- Sale 8
(8, 9, 250, 32.00),
(8, 12, 80, 180.00),

-- Sale 9
(9, 5, 25, 145.00),

-- Sale 10
(10, 6, 200, 95.00),
(10, 10, 100, 85.00),

-- Sale 11
(11, 2, 30, 90.00),

-- Sale 12
(12, 5, 25, 130.00),
(12, 8, 15, 160.00),

-- Sale 13
(13, 9, 100, 30.00),
(13, 12, 100, 175.00),

-- Sale 14
(14, 8, 20, 115.00),
(14, 5, 15, 150.00),

-- Sale 15
(15, 1, 150, 75.00),
(15, 3, 100, 135.00),
(15, 10, 75, 80.00);