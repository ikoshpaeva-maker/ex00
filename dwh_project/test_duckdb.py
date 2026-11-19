import duckdb

# Подключаемся к базе (создастся файл shop.duckdb)
con = duckdb.connect("shop.duckdb")

# Простой тест: создаём таблицу и делаем SELECT
con.sql("CREATE TABLE test AS SELECT 1 AS x, 'hello' AS y")
result = con.sql("SELECT * FROM test").df()
print(result)