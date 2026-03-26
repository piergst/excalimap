#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KROKI_URL="${KROKI_URL:-http://localhost:8000}"

usage() {
    echo "Usage: $0 <mindmap_folder> [options]"
    echo ""
    echo "Generate excalidraw mindmap and optionally export to SVG."
    echo ""
    echo "Options:"
    echo "  -t, --theme    Theme to use: dark (default), light"
    echo "  -s, --style    Style to use: classic (default), handraw"
    echo "  -e, --export   Export to SVG (starts Kroki automatically via podman-compose)"
    echo "  -h, --help     Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 mindmap/example"
    echo "  $0 mindmap/example -t light -s handraw"
    echo "  $0 mindmap/example -e"
    exit 0
}

start_kroki() {
    if curl -s "${KROKI_URL}/health" 2>/dev/null | grep -q "ok\|UP"; then
        return 0
    fi

    echo "[+] Starting Kroki..."
    podman-compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

    echo -n "[+] Waiting for Kroki"
    for i in $(seq 1 30); do
        if curl -s "${KROKI_URL}/health" 2>/dev/null | grep -q "ok\|UP"; then
            echo " ready"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo " timeout!"
    exit 1
}

if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

FOLDER="$1"
shift

THEME="dark"
STYLE="classic"
EXPORT=false

while [ $# -gt 0 ]; do
    case "$1" in
        -t|--theme) THEME="$2"; shift 2 ;;
        -s|--style) STYLE="$2"; shift 2 ;;
        -e|--export) EXPORT=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

NAME=$(echo "$FOLDER" | sed 's|/|_|g')
OUTFILE="output/${NAME}_${THEME}_${STYLE}.excalidraw"

echo "[+] Generating excalidraw: $OUTFILE"
python3 src/main.py -f "$FOLDER" -t "$THEME" -s "$STYLE" -o "$OUTFILE"

if [ "$EXPORT" = true ]; then
    mkdir -p output/svg

    start_kroki

    SVGFILE="output/svg/${NAME}_${THEME}_${STYLE}.svg"
    echo "[+] Exporting SVG: $SVGFILE"

    TMPFILE=$(mktemp)
    python3 -c "
import sys, json
with open(sys.argv[1]) as f:
    content = f.read()
json.dump({'diagram_source': content}, open(sys.argv[2], 'w'))
" "$OUTFILE" "$TMPFILE"

    curl -s -X POST "${KROKI_URL}/excalidraw/svg" \
        -H "Content-Type: application/json" \
        -d @"$TMPFILE" \
        -o "$SVGFILE"
    rm -f "$TMPFILE"

    if head -1 "$SVGFILE" | grep -q "<svg"; then
        echo "[+] SVG exported: $SVGFILE"
    else
        echo "[-] SVG export failed:"
        head -5 "$SVGFILE"
        exit 1
    fi
fi
