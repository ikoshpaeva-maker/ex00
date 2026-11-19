#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Использование: $0 <директория с .csv> [директория вывода]" >&2
    exit 1
fi

input_dir="$1"
output_dir="${2:-partitions}"

[ -d "$input_dir" ] || { echo "Ошибка: директория '$input_dir' не найдена" >&2; exit 1; }
mkdir -p "$output_dir"

for csv_file in "$input_dir"/*.csv; do
    [ -e "$csv_file" ] || { echo "Ошибка: в '$input_dir' нет .csv файлов" >&2; exit 1; }

    ticker="$(basename "$csv_file" .csv)"
    dir="$output_dir/$ticker"
    mkdir -p "$dir"

    head -n 1 "$csv_file" | tr -d '\r' > "$dir/header.csv"

    # Ищем номер колонки TRADEDATE в заголовке
    date_col="$(head -n 1 "$csv_file" | tr -d '\r"' | awk -F',' \
        '{ for (i = 1; i <= NF; i++) if ($i == "TRADEDATE") { print i; exit } }')"
    if [ -z "$date_col" ]; then
        echo "Ошибка: в '$csv_file' нет колонки TRADEDATE" >&2
        exit 1
    fi

    # Список месяцев (из колонки с датой)
    months="$(tail -n +2 "$csv_file" | tr -d '\r"' | awk -F',' -v col="$date_col" \
        '{ m = substr($col, 1, 7)
           if (m ~ /^[0-9]{4}-[0-9]{2}$/) print m }' | sort -u)"

    for m in $months; do
        mkdir -p "$dir/$m"
    done

    # Раскладываем строки по партициям
    tail -n +2 "$csv_file" | tr -d '\r"' | awk -F',' -v col="$date_col" -v dir="$dir" \
        '{ m = substr($col, 1, 7)
           if (m ~ /^[0-9]{4}-[0-9]{2}$/) print >> (dir "/" m "/data.csv") }'
done

echo "Готово: партиции записаны в '$output_dir'"