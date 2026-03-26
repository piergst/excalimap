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
    echo "  -e, --export   Export to SVG and PNG (requires Docker)"
    echo "  -h, --help     Show this help"
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
    if ! command -v docker &> /dev/null; then
        echo "[-] Docker is required for SVG/PNG export"
        echo "    See: https://github.com/realazthat/excalidraw-brute-export-cli"
        exit 1
    fi

    mkdir -p output/svg

    echo "[+] Exporting SVG: output/svg/${NAME}_${THEME}_${STYLE}.svg"
    docker run --rm -v "${PWD}/output:/data" my-excalidraw-brute-export-cli-image \
        -i "./${NAME}_${THEME}_${STYLE}.excalidraw" \
        --background 1 \
        --embed-scene 0 \
        --dark-mode 0 \
        --scale 1 \
        --format svg \
        -o "./svg/${NAME}_${THEME}_${STYLE}.svg"

    echo "[+] Exporting PNG: output/svg/${NAME}_${THEME}_${STYLE}.png"
    docker run --rm -v "${PWD}/output:/data" my-excalidraw-brute-export-cli-image \
        -i "./${NAME}_${THEME}_${STYLE}.excalidraw" \
        --background 1 \
        --embed-scene 0 \
        --dark-mode 0 \
        --scale 1 \
        --format png \
        -o "./svg/${NAME}_${THEME}_${STYLE}.png"

    if command -v mogrify &> /dev/null; then
        echo "[+] Creating thumbnail: output/svg/thumbnail_${NAME}_${THEME}_${STYLE}.png"
        cp "output/svg/${NAME}_${THEME}_${STYLE}.png" "output/svg/thumbnail_${NAME}_${THEME}_${STYLE}.png"
        mogrify -resize 500x "output/svg/thumbnail_${NAME}_${THEME}_${STYLE}.png"
    else
        echo "[!] mogrify (ImageMagick) not found, skipping thumbnail"
    fi

    echo "[+] Done!"
fi
