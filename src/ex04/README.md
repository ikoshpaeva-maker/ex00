## Отчёт по заданию ex04: PostgreSQL

### Цель работы

Загрузить подготовленные в ex03 CSV-файлы с котировками акций MOEX в СУБД PostgreSQL: создать схему со своим именем, таблицы с корректными типами данных и ограничениями, импортировать данные и зафиксировать все SQL-команды в файле `koshpaeva.sql`.

### Исходные данные

- 20 CSV-файлов с котировками по тикерам: ABRD, AQUA, BAZA, CBOM, GCHE, IVAT, LKOH, PHOR, RAGR, ROSB, ROSN, SBER, SNGS, SVCB, T, TATN, TRNFP, VKCO, VTBR, YDEX.
- В каждом файле 26 колонок, включая `TICKER` и `SECTOR`, как требует задание.
- Суммарный объём загруженных данных — 29 462 строки.

### Установка клиента СУБД

Использован консольный клиент `psql` из дистрибутива PostgreSQL 17 для Windows. Работа велась через Git Bash (UCRT64). Дополнительно настроена среда выполнения: переменная `PGCLIENTENCODING=UTF8` для корректной работы с данными и пароль пользователя `postgres` через переменную `PGPASSWORD`.

### Создание схемы

Схема создана по шаблону задания:

```sql
CREATE SCHEMA IF NOT EXISTS moex.a_koshpaeva;
```

Локальная версия для отладки создавалась без префикса базы (`CREATE SCHEMA IF NOT EXISTS a_koshpaeva;`), финальная версия для удалённого сервера — с полным именем `moex.a_koshpaeva`.

### Создание таблиц

Для каждого тикера создана отдельная таблица `stock_prices_<ТИКЕР>` в соответствии с шаблоном `stock_prices_NAME`. Пример для тикера LKOH:

```sql
CREATE TABLE moex.a_koshpaeva.stock_prices_LKOH (
    boardid                 VARCHAR(16),
    trade_date              DATE,
    shortname               VARCHAR(128),
    secid                   VARCHAR(32),
    numtrades               BIGINT,
    value                   NUMERIC,
    open                    NUMERIC,
    low                     NUMERIC,
    high                    NUMERIC,
    legalcloseprice         NUMERIC,
    waprice                 NUMERIC,
    close                   NUMERIC,
    volume                  BIGINT,
    marketprice2            NUMERIC,
    marketprice3            NUMERIC,
    admittedquote           NUMERIC,
    mp2valtrd               NUMERIC,
    marketprice3tradesvalue NUMERIC,
    admittedvalue           NUMERIC,
    waval                   NUMERIC,
    tradingsession          NUMERIC,
    currencyid              VARCHAR(16),
    trendclspr              NUMERIC,
    trade_session_date      DATE,
    ticker                  VARCHAR(16),
    sector                  VARCHAR(128),
    PRIMARY KEY (ticker, trade_date)
);
```

Из ограничений: составной первичный ключ `(ticker, trade_date)` гарантирует уникальность записи котировки для каждой акции на каждую торговую дату. Числовые колонки цен и объёмов выполнены типами `NUMERIC` и `BIGINT`, даты — `DATE`, строки — `VARCHAR` ограниченной длины.

### Импорт данных

Загрузка CSV выполнена средствами PostgreSQL — командой `\copy` с параметрами формата CSV и строкой заголовка:

```sql
\copy moex.a_koshpaeva.stock_prices_LKOH FROM 'LKOH.csv' WITH (FORMAT csv, HEADER true, NULL '')
```

Перед каждой загрузкой таблица пересоздавалась через `DROP TABLE IF EXISTS`, что делает скрипт идемпотентным — его можно запускать повторно без ошибок.

### Проверка результата

После выполнения скрипта:

- схема и все 20 таблиц созданы (проверено запросом к `information_schema.tables`);
- данные загружены: по выводу `psql` таблицы получили от 235 (BAZA) до 1741 (крупные ликвидные бумаги) строк, суммарно 29 462;
- контрольная выборка подтверждает корректность загруженных дат, цен и объёмов:

```sql
SELECT trade_date, close, volume
FROM moex.a_koshpaeva.stock_prices_LKOH
ORDER BY trade_date
LIMIT 5;
```

### Вывод psql при выполнении

```text
CREATE SCHEMA
DROP TABLE
CREATE TABLE
COPY 1741
... (аналогично для всех 20 тикеров)
```

Предупреждения вида «таблица не существует» при первом запуске ожидаемы: они возникают при `DROP TABLE IF EXISTS` для ещё не созданных таблиц и не влияют на результат.

### Возникшие проблемы и их решение

1. **Файл скрипта не находился psql** — при запуске из другой директории `psql` ищет файл относительно текущего пути. Решение: файл скопирован в рабочую директорию с CSV, откуда выполнялись относительные пути к данным.
2. **Старая версия скрипта** — по ошибке запускался файл с единственной таблицей `moex_trades`; после пересборки скрипта загрузка прошла полностью.
3. **Несогласованность имён схем при конвертации файла** — при подготовке версии для удалённого сервера замена префиксов коснулась таблиц, но не строки создания схемы. Исправлено расширенной заменой, результат проверен через `head -3`.
4. **Кодировка вывода psql** — сообщения об ошибках выводились в неверной кодировке из-за локали консоли Git Bash; на результат выполнения не влияла.

### Итоги

- Создана схема `moex.a_koshpaeva` и 20 таблиц `stock_prices_<ТИКЕР>` с полями, типами данных и первичным ключом.
- Все CSV-файлы загружены в базу (29 462 строки суммарно).
- Все команды зафиксированы в файле `koshpaeva.sql` в папке `ex04` для сдачи.
- Версия скрипта для локальной отладки (схема `a_koshpaeva`) сохранена отдельно в `src/ex03/with_columns`.