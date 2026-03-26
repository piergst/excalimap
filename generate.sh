#!/bin/bash
set -e

KROKI_URL="${KROKI_URL:-http://localhost:8000}"

usage() {
    echo "Usage: $0 <mindmap_folder> [options]"
    echo ""
    echo "Generate excalidraw mindmap and optionally export to SVG."
    echo ""
    echo "Options:"
    echo "  -t, --theme    Theme to use: dark (default), light"
    echo "  -s, --style    Style to use: classic (default), handraw"
    echo "  -e, --export   Export to SVG (requires Kroki, see below)"
    echo "  -h, --help     Show this help"
    echo ""
    echo "SVG export requires a running Kroki instance:"
    echo "  podman-compose up -d"
    echo ""
    echo "Examples:"
    echo "  $0 mindmap/example"
    echo "  $0 mindmap/example -t light -s handraw"
    echo "  $0 mindmap/example -e"
    exit 0
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

    # Check Kroki is running
    if ! curl -s "${KROKI_URL}/health" | grep -q "ok\|UP" 2>/dev/null; then
        echo "[-] Kroki is not running at ${KROKI_URL}"
        echo "    Start it with: podman-compose up -d"
        exit 1
    fi

    SVGFILE="output/svg/${NAME}_${THEME}_${STYLE}.svg"
    echo "[+] Exporting SVG: $SVGFILE"

    # Kroki expects {"diagram_source": "<excalidraw json as string>"}
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
