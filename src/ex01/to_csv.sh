#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Использование: $0 <директория с .json> [директория вывода]" >&2
    exit 1
fi

input_dir="$1"
output_dir="${2:-csv_data}"

if [ ! -d "$input_dir" ]; then
    echo "Ошибка: директория '$input_dir' не найдена" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$output_dir"

for json_file in "$input_dir"/*.json; do
    if [ ! -e "$json_file" ]; then
        echo "Ошибка: в '$input_dir' нет .json файлов" >&2
        exit 1
    fi

    name="$(basename "$json_file" .json)"
    name="${name%_raw}"

    rel_json="$(realpath --relative-to="$script_dir" "$json_file")"
    rel_out="$(realpath -m --relative-to="$script_dir" "$output_dir")"
    ( cd "$script_dir" && jq -r -f filter.jq "$rel_json" > "$rel_out/$name.csv" )
done

echo "Готово: CSV-файлы записаны в '$output_dir'"