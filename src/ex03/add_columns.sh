#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Использование: $0 <директория с CSV> [файл sectors.txt] [директория вывода]" >&2
    exit 1
fi

input_dir="$1"
sectors_file="${2:-sectors.txt}"
output_dir="${3:-with_columns}"

[ -d "$input_dir" ] || { echo "Ошибка: директория '$input_dir' не найдена" >&2; exit 1; }
[ -f "$sectors_file" ] || { echo "Ошибка: файл '$sectors_file' не найден" >&2; exit 1; }

# Нормализуем секторы: убираем \r, приводим разделители к табу
tmp_sectors="$(mktemp)"
trap 'rm -f "$tmp_sectors"' EXIT
sed -E 's/\r$//; s/^([^[:space:];:,]+)[[:space:];:,]+(.*)$/\1\t\2/' \
    "$sectors_file" | grep -v '^[[:space:]]*$' > "$tmp_sectors"

mkdir -p "$output_dir"

for csv_file in "$input_dir"/*.csv; do
    [ -e "$csv_file" ] || { echo "Ошибка: в '$input_dir' нет .csv файлов" >&2; exit 1; }

    ticker="$(basename "$csv_file" .csv)"
    sector="$(awk -F'\t' -v t="$ticker" '$1 == t { print $2; exit }' "$tmp_sectors")"

    awk -v t="$ticker" -v s="$sector" '
        NR == 1 { print $0 ",\"TICKER\",\"SECTOR\""; next }
        { print $0 ",\"" t "\",\"" s "\"" }
    ' "$csv_file" > "$output_dir/$ticker.csv"
done

echo "Готово: файлы с колонками записаны в '$output_dir'"