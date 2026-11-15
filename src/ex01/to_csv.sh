#!/bin/bash
# to_csv.sh — преобразует сырые JSON-файлы MOEX в CSV
# Использование: ./to_csv.sh <директория с JSON-файлами>

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ $# -ne 1 ]; then
    echo "Использование: $0 <директория с JSON-файлами>" >&2
    exit 1
fi

SRC_DIR="$1"
if [ ! -d "$SRC_DIR" ]; then
    echo "Ошибка: '$SRC_DIR' не является директорией" >&2
    exit 1
fi

# Переходим в папку скрипта, чтобы jq работал с короткими путями
cd "$SCRIPT_DIR" || exit 1
mkdir -p csv_data

for f in "$SRC_DIR"/*.json; do
    [ -e "$f" ] || { echo "В '$SRC_DIR' нет JSON-файлов" >&2; exit 1; }

    name=$(basename "$f" .json)
    name="${name%_raw}"

    jq -r -f filter.jq "$f" > "csv_data/${name}.csv" \
        && echo "$name — ok" \
        || echo "Ошибка преобразования: $f" >&2
done

echo "Готово: CSV лежат в csv_data/"