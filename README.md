# Excalimap

Mindmap creation from Markdown to Excalidraw, with SVG export.

## Prerequisites

**For .excalidraw generation only:**
- Python 3
- `pyyaml`, `pillow` (`pip install -r requirements.txt`)

**For SVG export:**
- Everything above
- `podman` and `podman-compose`
- `curl`

## Usage

```bash
# Generate .excalidraw file only
./generate.sh examples/demo

# Generate .excalidraw + SVG
./generate.sh examples/demo -e

# With theme and style options
./generate.sh examples/demo -t light -s handraw -e
```

Options:
- `-t, --theme` : `dark` (default) or `light`
- `-s, --style` : `classic` (default) or `handraw`
- `-e, --export` : export to SVG (starts Kroki automatically)

The `-e` flag starts a [Kroki](https://kroki.io/) instance via `podman-compose` if not already running, then exports to SVG.

```bash
# Stop Kroki when done
podman-compose down
```

Output files go to `output/<name>_<theme>_<style>/`:

```
output/demo_dark_classic/
  demo.excalidraw
  demo.svg
```

You can also open any `.excalidraw` file directly at https://excalidraw.com/

## Creating a mindmap

Create a folder in `examples/` with:
- `conf.yml` — configuration (title, layout, tools, colors)
- One or more `.md` files — the mindmap content

### conf.yml

The markdown describes the **content** (commands, info, links). The conf.yml describes the **layout and style** (grid, colors, icons).

```yml
main_title: Mindmap Demo
main_title_logo: ocd
matrix:
  - ['demo']
tools:
  excalidraw:
    icon: github
    link: https://excalidraw.com/
color_id:
  demo: "#D0CEE2"
  mindmap: "#FF0000"
container_color:
  Container title: demo
out:
  out box: demo
  Mindmap: mindmap
```

**`main_title` / `main_title_logo`** — the title displayed at the top of the mindmap + its icon (file name from `icon/` without .png).

**`matrix`** — the spatial layout. A grid that defines which .md files go where in the mindmap. Each cell is a .md file name (without extension), empty strings `''` leave gaps. Example from the AD mindmap:

```yml
matrix:
  - ['no_creds'   , 'valid_user', 'authenticated', 'admin'    , 'dom_admin']
  - ['low_hanging', 'mitm'      , ''             , 'lat_move' , 'trusts']
  - ['authors'    , 'crack_hash', ''             , 'adcs'     , 'persistence']
```

This produces a 3-row x 5-column grid. Each cell becomes a block in the mindmap.

**`tools`** — maps tool names to icons and links. When you write `` - `nmap -sV <ip>` `` in your markdown, the engine checks if `nmap` is in `tools`. If so, it displays the icon next to the command and adds a clickable link.

```yml
tools:
  nmap:
    icon: github        # icon/github.png
    link: https://github.com/nmap/nmap
  certipy:
    icon: github
    link: https://github.com/ly4k/Certipy
```

**`color_id`** — a named color palette, referenced by `container_color` and `out`.

```yml
color_id:
  nocreds: "#D0CEE2"
  creds: "#00ff00"
  mitm: "#ffff00"
```

**`container_color`** — assigns a color to `# Heading` containers. The key must match the heading text exactly.

```yml
container_color:
  No Credentials: nocreds     # -> #D0CEE2
  Man In The Middle: mitm     # -> #ffff00
```

**`out`** — assigns a color to `>>>` output box labels. The key must match the label text exactly.

```yml
out:
  Clear text Credentials: creds   # -> #00ff00
  Coerce SMB: mitm                # -> #ffff00
```

### Markdown syntax

```markdown
# Container title

## Mindmap >>> Mindmap
- Create a mindmap
  - `python3 main.py -f <folder>`
    - `excalidraw`

## Second subject
- Info
  - `command`
    - `sub command with link`
[https://example.com](https://example.com)
    - `command CVE` @CVE@
- Bloc CVE @CVE@

## Out box >>> out A >>> out B || out C >>> out D
- Level1
  - Level2
    - Level3
- `1 Command` >>> out box of command 2 & 2bis
  - `2 Command`
    - `3 Command` >>> out box of command 3
  - `2bis command`
- Level1
  - `Level2`
    - Level3
```

- `# Heading` — container (top-level box)
- `## Heading` — title (section within a container)
- `- text` — info node
- `` - `code` `` — command node (with tool icon if configured)
- `>>> label` — output box (colored per `out` config)
- `>>> A || B` — parallel output boxes
- `@CVE@` — marks a node as CVE (highlighted)
- `[url](url)` — adds a link to the previous node

## Examples

Two examples are included:
- `examples/demo/` — minimal demo showing all features
- `examples/ad/` — AD pentest "No Credentials" phase

## Result

- Dark / Classic : `./generate.sh examples/demo`
![demo_dark_classic](./doc/img/demo_dark_classic.png)

- Dark / Handraw : `./generate.sh examples/demo -s handraw`
![demo_dark_handraw](./doc/img/demo_dark_handraw.png)

- Light / Classic : `./generate.sh examples/demo -t light -s classic`
![demo_light_classic](./doc/img/demo_light_classic.png)

- Light / Handraw : `./generate.sh examples/demo -t light -s handraw`
![demo_light_handraw](./doc/img/demo_light_handraw.png)
