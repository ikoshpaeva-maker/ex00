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
    echo "Загружаю ${ticker} -> ${file}"
    echo "trade_date,open_price,low_price,high_price,close_price,volume" > "$file"

    start=0
    while : ; do
        resp=$(curl -s "${BASE}/${ticker}.json?iss.meta=off&iss.only=history,history.cursor&from=${FROM}&start=${start}")

        # страховка: если ответ пустой — сообщаем и выходим, а не молчим
        if [ -z "$resp" ]; then
            echo "Пустой ответ от API для ${ticker}, прерываю."
            exit 1
        fi

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

        next=$(echo "$resp" | jq -r '."history.cursor".NEXT // -1')
        if [ "$next" = "-1" ]; then
            break
        fi
        start=$next
    done
done

echo "Готово. Файлы лежат в ${OUT_DIR}/"