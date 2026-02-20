<<<<<<< HEAD
Drop table dim_customer;
CREATE TABLE dim_customer (
    customer_id            VARCHAR(50) PRIMARY KEY,
    signup_date            DATE,
    city                   VARCHAR(100),
    acquisition_channel    VARCHAR(100)
);
CREATE TABLE dim_delivery_partner (
    delivery_partner_id   VARCHAR(50) PRIMARY KEY,
    partner_name          VARCHAR(150),
    city                  VARCHAR(100),
    vehicle_type          VARCHAR(50),
    employment_type       VARCHAR(50),
    avg_rating            NUMERIC(3,2),
    is_active             BOOLEAN
);

drop table dim_menu_item;
CREATE TABLE dim_menu_item (
    menu_item_id        VARCHAR(50) PRIMARY KEY,
	restaurant_id       VARCHAR(50) NOT NULL	,
    item_name           VARCHAR(150) NOT NULL,
    category            VARCHAR(100),
	is_veg              BOOLEAN,
    price               NUMERIC(10,2)
     );


CREATE TABLE dim_restaurant (
    restaurant_id        VARCHAR(50) PRIMARY KEY,
    restaurant_name      VARCHAR(150),
    city                 VARCHAR(100),
    cuisine_type         VARCHAR(100),
    partner_type         VARCHAR(50),
    avg_prep_time_min    VARCHAR(50),
    is_active            BOOLEAN
);

DROP table delivery_data;
CREATE TABLE fact_delivery_performance (
    order_id VARCHAR(20) PRIMARY KEY,
    actual_delivery_time_mins INT,
    expected_delivery_time_mins INT,
    distance_km DECIMAL(4,1)
);

CREATE TABLE fact_order_items (
    order_id        VARCHAR(20),
    item_id         VARCHAR(20),
    menu_item_id    VARCHAR(50),
    restaurant_id   VARCHAR(20),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    item_discount   DECIMAL(10,2),
    line_total      DECIMAL(10,2),
    PRIMARY KEY (order_id, item_id)
);


CREATE TABLE fact_order (
    order_id             VARCHAR(20) PRIMARY KEY,
    customer_id          VARCHAR(20),
    restaurant_id        VARCHAR(20),
    delivery_partner_id  VARCHAR(20),
    order_timestamp      TIMESTAMP,
    subtotal_amount      DECIMAL(10,2),
    discount_amount      DECIMAL(10,2),
    delivery_fee         DECIMAL(10,2),
    total_amount         DECIMAL(10,2),
    is_cod               CHAR(1),
    is_cancelled         CHAR(1)
);

CREATE TABLE fact_ratings (
    order_id         VARCHAR(20),
    customer_id      VARCHAR(20),
    restaurant_id    VARCHAR(20),
    rating           NUMERIC(2,1),
    review_text      TEXT,
    review_timestamp TIMESTAMP,
    sentiment_score  NUMERIC(4,2),
    PRIMARY KEY (order_id, customer_id)
);
=======
Drop table dim_customer;
CREATE TABLE dim_customer (
    customer_id            VARCHAR(50) PRIMARY KEY,
    signup_date            DATE,
    city                   VARCHAR(100),
    acquisition_channel    VARCHAR(100)
);
CREATE TABLE dim_delivery_partner (
    delivery_partner_id   VARCHAR(50) PRIMARY KEY,
    partner_name          VARCHAR(150),
    city                  VARCHAR(100),
    vehicle_type          VARCHAR(50),
    employment_type       VARCHAR(50),
    avg_rating            NUMERIC(3,2),
    is_active             BOOLEAN
);

drop table dim_menu_item;
CREATE TABLE dim_menu_item (
    menu_item_id        VARCHAR(50) PRIMARY KEY,
	restaurant_id       VARCHAR(50) NOT NULL	,
    item_name           VARCHAR(150) NOT NULL,
    category            VARCHAR(100),
	is_veg              BOOLEAN,
    price               NUMERIC(10,2)
     );


CREATE TABLE dim_restaurant (
    restaurant_id        VARCHAR(50) PRIMARY KEY,
    restaurant_name      VARCHAR(150),
    city                 VARCHAR(100),
    cuisine_type         VARCHAR(100),
    partner_type         VARCHAR(50),
    avg_prep_time_min    VARCHAR(50),
    is_active            BOOLEAN
);

DROP table delivery_data;
CREATE TABLE fact_delivery_performance (
    order_id VARCHAR(20) PRIMARY KEY,
    actual_delivery_time_mins INT,
    expected_delivery_time_mins INT,
    distance_km DECIMAL(4,1)
);

CREATE TABLE fact_order_items (
    order_id        VARCHAR(20),
    item_id         VARCHAR(20),
    menu_item_id    VARCHAR(50),
    restaurant_id   VARCHAR(20),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    item_discount   DECIMAL(10,2),
    line_total      DECIMAL(10,2),
    PRIMARY KEY (order_id, item_id)
);


CREATE TABLE fact_order (
    order_id             VARCHAR(20) PRIMARY KEY,
    customer_id          VARCHAR(20),
    restaurant_id        VARCHAR(20),
    delivery_partner_id  VARCHAR(20),
    order_timestamp      TIMESTAMP,
    subtotal_amount      DECIMAL(10,2),
    discount_amount      DECIMAL(10,2),
    delivery_fee         DECIMAL(10,2),
    total_amount         DECIMAL(10,2),
    is_cod               CHAR(1),
    is_cancelled         CHAR(1)
);

CREATE TABLE fact_ratings (
    order_id         VARCHAR(20),
    customer_id      VARCHAR(20),
    restaurant_id    VARCHAR(20),
    rating           NUMERIC(2,1),
    review_text      TEXT,
    review_timestamp TIMESTAMP,
    sentiment_score  NUMERIC(4,2),
    PRIMARY KEY (order_id, customer_id)
);
>>>>>>> b1ea29bbdcfac95373899e08947112e6059ddcba
