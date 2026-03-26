# Excalimap Restructure — Clean Project

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the ocd-mindmaps repo into a clean, standalone excalimap project with code in `src/`, keeping all features but removing AD-specific content.

**Architecture:** Move `excalimap/` contents to project root. Python source code goes into `src/`. Data directories (`icon/`, `mindmap/`, `output/`, `doc/`) stay at root. `sys.path` is adjusted in `main.py` so bare imports within `src/` continue to work.

**Tech Stack:** Python 3, pyyaml, pillow

---

### Task 1: Remove non-excalimap files from project root

**Files:**
- Delete: `src/Pentesting_Active_directory_dark.xmind`
- Delete: `img/` (all SVG/PNG mindmap outputs)
- Delete: `index.md` (GitHub Pages)
- Delete: `_config.yml` (GitHub Pages)
- Delete: `readme.md` (root readme, will be replaced by excalimap's README)

- [ ] **Step 1: Remove all non-excalimap root files**

```bash
git rm src/Pentesting_Active_directory_dark.xmind
git rm -r img/
git rm index.md
git rm _config.yml
git rm readme.md
```

Note: `LICENSE` is kept — it's the GPL-3.0 license for the project.

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove non-excalimap root files (Pages, xmind, images)"
```

---

### Task 2: Move excalimap contents to project root

**Files:**
- Move: `excalimap/*` → project root (using `git mv` for history)
- Delete: `excalimap/mindmap/ad/` (AD-specific content)
- Delete: `excalimap/gen_all.sh`, `excalimap/gen_all_svg.sh` (AD-specific scripts)

- [ ] **Step 1: Move excalimap contents to root using git mv**

```bash
# Move Python source files
git mv excalimap/main.py excalimap/config.py excalimap/parsermd.py excalimap/parserjson.py excalimap/utils.py .
git mv excalimap/models/ .
# Move data directories
git mv excalimap/icon/ .
git mv excalimap/mindmap/ .
git mv excalimap/output/ .
git mv excalimap/doc/ .
# Move config files
git mv excalimap/requirements.txt .
git mv excalimap/README.md ./README.md
# Create .gitignore from excalimap's (no root .gitignore existed before)
cp excalimap/.gitignore .gitignore
git add .gitignore
```

- [ ] **Step 2: Remove AD-specific content and leftover excalimap dir**

```bash
git rm -r mindmap/ad/
git rm excalimap/gen_all.sh excalimap/gen_all_svg.sh excalimap/.gitignore
rm -rf excalimap/
```

- [ ] **Step 3: Remove AD-specific icons, keep only github.png and ocd.png for example**

The example `conf.yml` references `main_title_logo: ocd` and tool icon `github`.

```bash
find icon/ -name '*.png' ! -name 'github.png' ! -name 'ocd.png' -delete
git add icon/
```

- [ ] **Step 4: Stage and commit**

```bash
git add -A
git commit -m "chore: move excalimap to project root and remove AD-specific content"
```

---

### Task 3: Restructure Python code into src/

**Files:**
- Move: `main.py` → `src/main.py`
- Move: `config.py` → `src/config.py`
- Move: `parsermd.py` → `src/parsermd.py`
- Move: `parserjson.py` → `src/parserjson.py`
- Move: `utils.py` → `src/utils.py`
- Move: `models/` → `src/models/` (including `models/__init__.py`)

- [ ] **Step 1: Create src/ and move Python files with git mv**

```bash
mkdir -p src
git mv main.py config.py parsermd.py parserjson.py utils.py src/
git mv models/ src/
```

This moves all Python files including `models/__init__.py`.

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: move Python source code into src/"
```

---

### Task 4: Fix imports and paths for new layout

All Python files use bare imports like `from config import Config` and `from models.command import Command`. Since code now lives in `src/`, we add `sys.path` adjustment in `main.py` so it can be run from project root as `python3 src/main.py -f mindmap/example`.

**Files:**
- Modify: `src/main.py` — add sys.path setup at top

- [ ] **Step 1: Update src/main.py — add sys.path**

At the very top of `src/main.py`, before other imports, add:
```python
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
```

The file already imports `sys` and `os.path` — merge with existing imports. Remove duplicate `import sys` and replace `import os.path` with `import os` (which covers `os.path`).

- [ ] **Step 2: Verify icon_path in config.py**

`Config.icon_path = './icon'` — this is relative to CWD (project root), which is correct when running `python3 src/main.py` from project root. No change needed.

- [ ] **Step 3: Test the generation works**

```bash
python3 src/main.py -f mindmap/example -o output/test.excalidraw
```

Expected: `Mindmap result in file : output/test.excalidraw` and a valid JSON file.

- [ ] **Step 4: Clean up test output and commit**

```bash
rm -f output/test.excalidraw
git add -A
git commit -m "fix: adjust sys.path in main.py for src/ layout"
```

---

### Task 5: Update README, .gitignore, and doc/

**Files:**
- Modify: `README.md` — update usage instructions for new `src/` path, fix image references to `doc/img/`
- Modify: `.gitignore` — ensure clean content

- [ ] **Step 1: Update README.md**

Update the usage section to reflect new path:
```bash
python3 src/main.py -f mindmap/example
```

The README references images at `./doc/img/demo_*.png` — these are now at `doc/img/` (moved from `excalimap/doc/`), so the relative paths remain correct.

Remove any OCD-specific references in the description. Keep the demo screenshots.

- [ ] **Step 2: Clean .gitignore**

Ensure final content is:
```
.venv
__pycache__
.idea
output/*.excalidraw
output/svg/*.svg
output/svg/*.png
```

- [ ] **Step 3: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: update README and .gitignore for new project structure"
```

---

### Task 6: Clean up planning artifacts

- [ ] **Step 1: Remove docs/superpowers/ directory**

```bash
rm -rf docs/
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "chore: remove planning artifacts"
```

---

### Task 7: Final verification

- [ ] **Step 1: Verify project structure**

```bash
find . -not -path './.git/*' -not -path './.git' -not -name '__pycache__' | sort
```

Expected structure:
```
.
./.gitignore
./LICENSE
./README.md
./doc/img/demo_dark_classic.png
./doc/img/demo_dark_handraw.png
./doc/img/demo_light_classic.png
./doc/img/demo_light_handraw.png
./icon/github.png
./icon/ocd.png
./mindmap/example/conf.yml
./mindmap/example/example.md
./output/.gitkeep
./requirements.txt
./src/config.py
./src/main.py
./src/models/__init__.py
./src/models/arrow.py
./src/models/command.py
./src/models/container.py
./src/models/icon.py
./src/models/info.py
./src/models/maintitle.py
./src/models/mapobject.py
./src/models/out.py
./src/models/title.py
./src/parsermd.py
./src/parserjson.py
./src/utils.py
```

- [ ] **Step 2: Run generation and verify output**

```bash
python3 src/main.py -f mindmap/example -o output/test.excalidraw
python3 -c "import json; json.load(open('output/test.excalidraw')); print('OK')"
rm output/test.excalidraw
```

- [ ] **Step 3: Verify all 4 theme/style combinations**

```bash
python3 src/main.py -f mindmap/example -t dark -s classic -o output/test_dc.excalidraw
python3 src/main.py -f mindmap/example -t dark -s handraw -o output/test_dh.excalidraw
python3 src/main.py -f mindmap/example -t light -s classic -o output/test_lc.excalidraw
python3 src/main.py -f mindmap/example -t light -s handraw -o output/test_lh.excalidraw
echo "All 4 combinations generated successfully"
rm output/test_*.excalidraw
```
