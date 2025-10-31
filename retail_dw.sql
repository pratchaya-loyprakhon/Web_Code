-- ================================================
-- 1️⃣ สร้างฐานข้อมูลและใช้งาน
-- ================================================
CREATE DATABASE IF NOT EXISTS s67160225;
USE s67160225;

-- ================================================
-- 2️⃣ ตารางมิติ (Dimension Tables)
-- ================================================

-- ตาราง dim_date
CREATE TABLE IF NOT EXISTS dim_date (
  date_key DATE PRIMARY KEY,
  y INT NOT NULL,
  m INT NOT NULL,
  d INT NOT NULL,
  month_name VARCHAR(12) NOT NULL,
  weekday INT NOT NULL,
  weekday_name VARCHAR(12) NOT NULL,
  week_of_year INT NOT NULL
);

-- ตาราง dim_product
CREATE TABLE IF NOT EXISTS dim_product (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  product_name VARCHAR(100) NOT NULL,
  category VARCHAR(50) NOT NULL,
  brand VARCHAR(50) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL
);

-- ตาราง dim_store
CREATE TABLE IF NOT EXISTS dim_store (
  store_id INT PRIMARY KEY AUTO_INCREMENT,
  store_name VARCHAR(100) NOT NULL,
  region VARCHAR(50) NOT NULL,
  city VARCHAR(60) NOT NULL
);

-- ตาราง dim_customer
CREATE TABLE IF NOT EXISTS dim_customer (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_name VARCHAR(100) NOT NULL,
  gender ENUM('M','F') NOT NULL,
  sign_up_date DATE NOT NULL
);

-- ================================================
-- 3️⃣ ตาราง fact (Fact Table)
-- ================================================
CREATE TABLE IF NOT EXISTS fact_sales (
  sales_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  date_key DATE NOT NULL,
  product_id INT NOT NULL,
  store_id INT NOT NULL,
  customer_id INT NOT NULL,
  quantity INT NOT NULL,
  gross_amount DECIMAL(12,2) NOT NULL,
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  net_amount DECIMAL(12,2) NOT NULL,
  payment_method ENUM('Cash','Credit Card','Mobile Pay','QR PromptPay') NOT NULL,
  hour_of_day INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
  FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
  FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
  FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id)
);

-- ================================================
-- 4️⃣ เติมข้อมูลมิติ (Dimension Data)
-- ================================================
SET @@cte_max_recursion_depth = 2000;

-- เติม dim_date (ย้อนหลัง 2 ปี)
INSERT INTO dim_date (date_key, y, m, d, month_name, weekday, weekday_name, week_of_year)
SELECT
    dt,
    YEAR(dt),
    MONTH(dt),
    DAY(dt),
    DATE_FORMAT(dt, '%b'),
    WEEKDAY(dt)+1,
    DATE_FORMAT(dt, '%a'),
    WEEK(dt, 3)
FROM (
    WITH RECURSIVE d AS (
        SELECT DATE_SUB(CURDATE(), INTERVAL 729 DAY) AS dt
        UNION ALL
        SELECT DATE_ADD(dt, INTERVAL 1 DAY) FROM d WHERE dt < CURDATE()
    )
    SELECT * FROM d
) AS dates;

-- เติม dim_product
INSERT INTO dim_product (product_name, category, brand, unit_price) VALUES
 ('Iced Coffee 16oz','Beverage','CafeJoy', 45.00),
 ('Hot Americano','Beverage','CafeJoy', 40.00),
 ('Thai Milk Tea','Beverage','ChaThai', 35.00),
 ('Matcha Latte','Beverage','UjiLeaf', 55.00),
 ('Lemon Soda','Beverage','FizzUp', 30.00),
 ('Croissant','Bakery','Butter&Co', 42.00),
 ('Chocolate Donut','Bakery','SweetBite', 28.00),
 ('Ham Cheese Sandwich','Bakery','SnackBox', 55.00),
 ('Tuna Sandwich','Bakery','SnackBox', 58.00),
 ('Cheesecake','Dessert','CreamyHill', 85.00),
 ('Brownie','Dessert','CacaoFarm', 50.00),
 ('Pudding','Dessert','CreamyHill', 35.00),
 ('Granola Cup','Snack','FitLife', 49.00),
 ('Potato Chips','Snack','CrispyDay', 25.00),
 ('Mixed Nuts','Snack','Nutty', 60.00);

-- เติม dim_store
INSERT INTO dim_store (store_name, region, city) VALUES
 ('Bangsaen Beach Branch','East','Chonburi'),
 ('BUU Campus Branch','East','Chonburi'),
 ('CentralWorld Kiosk','Central','Bangkok'),
 ('Silom Office Tower','Central','Bangkok'),
 ('Chiang Mai Nimman','North','Chiang Mai'),
 ('Hatyai Central','South','Songkhla');

-- สร้าง temporary table สำหรับอักษร
CREATE TEMPORARY TABLE tmp_chars (c CHAR(1));
INSERT INTO tmp_chars VALUES 
('A'),('B'),('C'),('D'),('E'),('F'),('G'),('H'),('I'),('J'),
('K'),('L'),('M'),('N'),('O'),('P'),('Q'),('R'),('S'),('T'),
('U'),('V'),('W'),('X'),('Y'),('Z');

-- เติม dim_customer (2,000 ลูกค้า)
INSERT INTO dim_customer (customer_name, gender, sign_up_date)
SELECT
  CONCAT('Cust-', n, '-', (SELECT c FROM tmp_chars ORDER BY RAND() LIMIT 1)) AS customer_name,
  IF(RAND() < 0.48, 'F', 'M') AS gender,
  DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*720) DAY) AS sign_up_date
FROM (
  WITH RECURSIVE nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n+1 FROM nums WHERE n < 2000
  )
  SELECT n FROM nums
) AS t;

-- ================================================
-- 5️⃣ เติมข้อมูลจำลอง fact_sales
-- ================================================
INSERT INTO fact_sales (
  date_key, product_id, store_id, customer_id,
  quantity, gross_amount, discount_amount, net_amount,
  payment_method, hour_of_day
)
SELECT
  d.date_key,
  FLOOR(1 + RAND()*15),  -- product_id
  FLOOR(1 + RAND()*6),   -- store_id
  FLOOR(1 + RAND()*2000),-- customer_id
  FLOOR(1 + RAND()*5) AS quantity,
  FLOOR(1 + RAND()*5) * p.unit_price AS gross_amount,
  ROUND(RAND()*5, 2) AS discount_amount,
  (FLOOR(1 + RAND()*5) * p.unit_price) - ROUND(RAND()*5, 2) AS net_amount,
  ELT(FLOOR(1 + RAND()*4), 'Cash', 'Credit Card', 'Mobile Pay', 'QR PromptPay') AS payment_method,
  FLOOR(RAND()*12)+8 AS hour_of_day -- ระหว่าง 8:00 - 20:00
FROM dim_date d
JOIN dim_product p ON p.product_id = FLOOR(1 + RAND()*15)
WHERE d.date_key BETWEEN DATE_SUB(CURDATE(), INTERVAL 90 DAY) AND CURDATE()
LIMIT 10000;

-- ================================================
-- 6️⃣ สร้าง Views สำหรับทำรายงาน/กราฟ
-- ================================================

-- ยอดขายรายวัน
CREATE OR REPLACE VIEW v_daily_sales AS
SELECT date_key, SUM(net_amount) AS net_sales, SUM(quantity) AS qty
FROM fact_sales
GROUP BY date_key;

-- ยอดขายรายเดือน
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT CONCAT(y,'-',LPAD(m,2,'0')) AS ym, SUM(net_amount) AS net_sales
FROM dim_date d
JOIN fact_sales f ON f.date_key = d.date_key
GROUP BY y,m
ORDER BY y,m;

-- ยอดขายตามหมวดสินค้า
CREATE OR REPLACE VIEW v_sales_by_category AS
SELECT p.category, SUM(f.net_amount) AS net_sales
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.category;

-- ยอดขายตามภูมิภาค
CREATE OR REPLACE VIEW v_sales_by_region AS
SELECT s.region, SUM(f.net_amount) AS net_sales
FROM fact_sales f
JOIN dim_store s ON s.store_id = f.store_id
GROUP BY s.region;

-- Top 10 สินค้าขายดี
CREATE OR REPLACE VIEW v_top_products AS
SELECT p.product_name, SUM(f.quantity) AS qty_sold, SUM(f.net_amount) AS net_sales
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.product_name
ORDER BY net_sales DESC
LIMIT 10;

-- ยอดขายตามวิธีชำระเงิน
CREATE OR REPLACE VIEW v_payment_share AS
SELECT payment_method, SUM(net_amount) AS net_sales
FROM fact_sales
GROUP BY payment_method;

-- ยอดขายรายชั่วโมง
CREATE OR REPLACE VIEW v_hourly_sales AS
SELECT hour_of_day, SUM(net_amount) AS net_sales
FROM fact_sales
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- เปรียบเทียบลูกค้าใหม่ vs ลูกค้าเดิม
CREATE OR REPLACE VIEW v_new_vs_returning AS
SELECT
  d.date_key,
  SUM(CASE WHEN c.sign_up_date = d.date_key THEN f.net_amount ELSE 0 END) AS new_customer_sales,
  SUM(CASE WHEN c.sign_up_date < d.date_key THEN f.net_amount ELSE 0 END) AS returning_sales
FROM fact_sales f
JOIN dim_customer c ON c.customer_id = f.customer_id
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY d.date_key;

-- ================================================
-- ✅ เสร็จสิ้น
-- ================================================
SELECT '✅ Data warehouse setup complete!' AS status;

