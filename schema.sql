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