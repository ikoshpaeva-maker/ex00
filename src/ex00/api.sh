#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Использование: $0 ТИКЕР1 ТИКЕР2 ..."
    exit 1
fi

BASE="https://iss.moex.com/iss/history/engines/stock/markets/shares/boards/TQBR/securities"
OUT_DIR="${ROOT}/raw_data"
FROM="2020-01-01"

mkdir -p "$OUT_DIR"

for ticker in "$@"; do
    file="${OUT_DIR}/${ticker}.csv"
    json_file="${OUT_DIR}/${ticker}_raw.json"   # <-- создаём переменную
    pages_file="${OUT_DIR}/${ticker}_pages.json"
    echo "Загружаю ${ticker} -> ${file}"

    # Пишем заголовок CSV
    echo "trade_date,open_price,low_price,high_price,close_price,volume" > "$file"

    start=0
    while : ; do
        resp=$(curl -s "${BASE}/${ticker}.json?iss.meta=off&iss.only=history,history.cursor&from=${FROM}&start=${start}")

        if [ -z "$resp" ]; then
            echo "Пустой ответ от API для ${ticker}, прерываю."
            exit 1
        fi

        # Сохраняем сырой JSON в файл через переменную
        echo "$resp" >> "$pages_file"              # <-- используем переменную

        echo "$resp" | jq -r '
            .history.columns as $c
            | .history.data[]
            | [ .[($c|index("TRADEDATE"))],
                .[($c|index("OPEN"))],
                .[($c|index("LOW"))],
                .[($c|index("HIGH"))],
                .[($c|index("CLOSE"))],
                .[($c|index("VOLUME"))] ]
            | @csv' >> "$file"

       count=$(echo "$resp" | jq '.history.data | length')
        if [ "$count" -lt 100 ]; then
            break
        fi
        start=$((start + 100))
        sleep 0.6
    done
     jq -s '{history: {columns: .[0].history.columns, data: ([.[].history.data] | add)}}' \
        "$pages_file" > "$json_file"
    rm -f "$pages_file"
done


echo "Готово. Файлы лежат в ${OUT_DIR}/"

