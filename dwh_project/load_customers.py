import duckdb
from datetime import datetime

RAW_PATH = "data/raw/customer_master.csv"
STAGING_PATH = "data/staging/customer_master.parquet"

con = duckdb.connect()  # in-memory: для staging база-файл не нужна

# 1. Читаем CSV и сразу приводим типы
con.sql(f"""
    CREATE TABLE raw_customers AS
    SELECT
        customer_id::VARCHAR                AS customer_id,
        trim(customer_name)::VARCHAR        AS customer_name,
        try_cast(customer_age AS INTEGER)   AS customer_age,
        gender::VARCHAR                     AS gender,
        customer_segment::VARCHAR           AS customer_segment,
        trim(customer_city)::VARCHAR        AS customer_city,
        trim(customer_state)::VARCHAR       AS customer_state,
        trim(customer_country)::VARCHAR     AS customer_country,
        trim(region)::VARCHAR               AS region,
        trim(customer_postal_code)::VARCHAR AS customer_postal_code,
        try_cast(customer_acquisition_cost AS DECIMAL(10, 2))
                                            AS customer_acquisition_cost
    FROM read_csv_auto('{RAW_PATH}', header = true)
""")

# 2. Отчёт о качестве сырых данных (покажем до очистки)
print("=== Сырые данные ===")
print(con.sql("""
    SELECT count(*) AS total_rows,
           count(DISTINCT customer_id) AS unique_ids,
           sum(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_ids,
           sum(CASE WHEN customer_age IS NULL THEN 1 ELSE 0 END) AS null_age
    FROM raw_customers
"""))

# 3. Очистка и обогащение
con.sql(f"""
    CREATE TABLE staging_customers AS
    SELECT
        customer_id,
        customer_name,
        customer_age,
        gender,
        customer_segment,
        customer_city,
        customer_state,
        customer_country,
        region,
        customer_postal_code,
        customer_acquisition_cost,
        '{RAW_PATH}'                            AS source_id,
        current_localtimestamp()::TIMESTAMP     AS load_ts
    FROM raw_customers
    WHERE customer_id IS NOT NULL
    QUALIFY row_number() OVER (PARTITION BY customer_id ORDER BY customer_id) = 1
""")

# 4. Отчёт после очистки
print("\n=== Staging ===")
print(con.sql("""
    SELECT count(*) AS rows_staged,
           count(DISTINCT customer_id) AS unique_ids,
           min(customer_age) AS min_age,
           max(customer_age) AS max_age
    FROM staging_customers
"""))

# 5. Сохраняем в Parquet
con.sql(f"""
    COPY staging_customers TO '{STAGING_PATH}' (FORMAT PARQUET)
""")
print(f"\nГотово: {STAGING_PATH}")

# 6. Пример: мини-профилировка для отчёта
print("\n=== Клиенты по сегментам ===")
print(con.sql("""
    SELECT customer_segment, count(*) AS cnt
    FROM staging_customers
    GROUP BY customer_segment
    ORDER BY cnt DESC
"""))