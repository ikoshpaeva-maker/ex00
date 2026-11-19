#!/bin/bash
set -euo pipefail

input_dir="${1:-partitions}"
output_dir="${2:-rebuilt}"

[ -d "$input_dir" ] || { echo "Ошибка: директория '$input_dir' не найдена" >&2; exit 1; }
mkdir -p "$output_dir"

for ticker_dir in "$input_dir"/*/; do
    ticker="$(basename "$ticker_dir")"
    header="$ticker_dir/header.csv"
    [ -f "$header" ] || { echo "Ошибка: в '$ticker_dir' нет header.csv" >&2; exit 1; }

    date_col="$(tr -d '\r"' < "$header" | awk -F',' \
        '{ for (i = 1; i <= NF; i++) if ($i == "TRADEDATE") { print i; exit } }')"
    [ -n "$date_col" ] || { echo "Ошибка: нет колонки TRADEDATE в '$ticker_dir'" >&2; exit 1; }

    out="$output_dir/$ticker.csv"
    cp "$header" "$out"

    find "$ticker_dir" -mindepth 2 -maxdepth 2 -type f -name data.csv -exec cat {} + \
        | tr -d '\r' \
        | sort -t',' -k"${date_col},${date_col}r" >> "$out"
done

echo "Готово: файлы записаны в '$output_dir'"