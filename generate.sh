#!/bin/bash
set -e

usage() {
    echo "Usage: $0 <mindmap_folder> [options]"
    echo ""
    echo "Generate excalidraw mindmap and optionally export to SVG/PNG."
    echo ""
    echo "Options:"
    echo "  -t, --theme    Theme to use: dark (default), light"
    echo "  -s, --style    Style to use: classic (default), handraw"
    echo "  -e, --export   Export to SVG and PNG"
    echo "  -h, --help     Show this help"
    echo ""
    echo "Export uses npx excalidraw-brute-export-cli (requires Node.js >= 18)"
    echo "Install: npm install -g excalidraw-brute-export-cli"
    echo "         npx playwright install-deps && npx playwright install firefox"
    echo ""
    echo "Examples:"
    echo "  $0 mindmap/example"
    echo "  $0 mindmap/example -t light -s handraw"
    echo "  $0 mindmap/example -e"
    echo "  $0 mindmap/example -t dark -s classic -e"
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
    DARK_MODE=0
    if [ "$THEME" = "dark" ]; then
        DARK_MODE=1
    fi

    mkdir -p output/svg

    export_file() {
        local format="$1"
        local outpath="$2"
        echo "[+] Exporting ${format^^}: $outpath"
        npx excalidraw-brute-export-cli \
            -i "$OUTFILE" \
            --background 1 \
            --embed-scene 0 \
            --dark-mode "$DARK_MODE" \
            --scale 1 \
            --format "$format" \
            -o "$outpath"
    }

    export_file svg "output/svg/${NAME}_${THEME}_${STYLE}.svg"
    export_file png "output/svg/${NAME}_${THEME}_${STYLE}.png"

    if command -v mogrify &> /dev/null; then
        echo "[+] Creating thumbnail"
        cp "output/svg/${NAME}_${THEME}_${STYLE}.png" "output/svg/thumbnail_${NAME}_${THEME}_${STYLE}.png"
        mogrify -resize 500x "output/svg/thumbnail_${NAME}_${THEME}_${STYLE}.png"
    else
        echo "[!] mogrify (ImageMagick) not found, skipping thumbnail"
    fi

    echo "[+] Done!"
fi
