#!/bin/bash
# One-time migration script: convert HTML <img> and <object> tags in .mld files
# to odoc {image!...} syntax.
#
# Only converts simple standalone figure blocks. Grid layouts and complex HTML
# structures are left as-is (a warning is printed).
#
# Usage: ./scripts/migrate_images.sh [--dry-run] [file.mld ...]
# If no files given, processes all .mld files under blog/, notes/, drafts/.

set -euo pipefail

DRY_RUN=false
FILES=()

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) FILES+=("$arg") ;;
    esac
done

if [ ${#FILES[@]} -eq 0 ]; then
    mapfile -t FILES < <(find blog notes drafts -name "*.mld" 2>/dev/null)
fi

convert_file() {
    local file="$1"
    local tmp="${file}.migrate_tmp"
    local changed=false

    # Use Python for reliable multiline regex processing
    python3 -c "
import re
import sys

with open('$file', 'r') as f:
    content = f.read()

original = content

# Pattern 1: Simple figure with img and figcaption
# {%html:
# <figure>
#         <img src=\"X\" alt=\"Y\" style=\"...\">
#         <figcaption>Z</figcaption>
# </figure>
# %}
pattern_figure = re.compile(
    r'\{%html:\s*\n'
    r'\s*<figure>\s*\n'
    r'\s*<img\s+src=\"([^\"]+)\"\s+alt=\"([^\"]+)\"(?:\s+style=\"[^\"]*\")?\s*/?>\s*\n'
    r'\s*<figcaption>([^<]+)</figcaption>\s*\n'
    r'\s*</figure>\s*\n'
    r'%\}',
    re.MULTILINE
)

def replace_figure(m):
    src = m.group(1)
    alt = m.group(2)
    caption = m.group(3).strip()
    # Use image with alt text, then caption as italic text
    return '{{image!' + src + '}' + alt + '}\n\n{i ' + caption + '}'

content = pattern_figure.sub(replace_figure, content)

# Pattern 2: Simple figure with img, no figcaption
pattern_figure_nocap = re.compile(
    r'\{%html:\s*\n'
    r'\s*<figure>\s*\n'
    r'\s*<img\s+src=\"([^\"]+)\"\s+alt=\"([^\"]+)\"(?:\s+style=\"[^\"]*\")?\s*/?>\s*\n'
    r'\s*</figure>\s*\n'
    r'%\}',
    re.MULTILINE
)

def replace_figure_nocap(m):
    src = m.group(1)
    alt = m.group(2)
    return '{{image!' + src + '}' + alt + '}'

content = pattern_figure_nocap.sub(replace_figure_nocap, content)

# Pattern 3: Standalone <object> SVG (no fallback img)
# {%html:
# <object type=\"image/svg+xml\" data=\"X\">
# </object>
# %}
pattern_object = re.compile(
    r'\{%html:\s*\n'
    r'\s*<object\s+type=\"image/svg\+xml\"\s+data=\"([^\"]+)\"\s*>\s*\n'
    r'\s*</object>\s*\n'
    r'%\}',
    re.MULTILINE
)

def replace_object(m):
    src = m.group(1)
    return '{image!' + src + '}'

content = pattern_object.sub(replace_object, content)

# Pattern 4: <object> SVG with <img> fallback inside a div
# {%html:
# <div ...>
#     <object data=\"X.svg\" type=\"image/svg+xml\" ...>
#         <img src=\"X.png\" alt=\"Y\" ...>
#     </object>
# </div>
# %}
pattern_object_fallback = re.compile(
    r'\{%html:\s*\n'
    r'\s*<div[^>]*>\s*\n'
    r'\s*(?:<!--[^>]*-->\s*\n\s*)?'
    r'\s*<object\s+data=\"([^\"]+)\"\s+type=\"image/svg\+xml\"[^>]*>\s*\n'
    r'\s*(?:<!--[^>]*-->\s*\n\s*)?'
    r'\s*<img\s+src=\"[^\"]+\"\s+alt=\"([^\"]+)\"[^>]*/?\s*>\s*\n'
    r'\s*</object>\s*\n'
    r'\s*</div>\s*\n'
    r'%\}',
    re.MULTILINE
)

def replace_object_fallback(m):
    src = m.group(1)
    alt = m.group(2)
    return '{{image!' + src + '}' + alt + '}'

content = pattern_object_fallback.sub(replace_object_fallback, content)

# Warn about remaining HTML image patterns that weren't converted
remaining_imgs = re.findall(r'<img\s+src=\"([^\"]+)\"', content)
remaining_objects = re.findall(r'<object[^>]*data=\"([^\"]+)\"', content)
for img in remaining_imgs:
    print(f'WARNING: {\"$file\"}: unconverted <img> referencing {img}', file=sys.stderr)
for obj in remaining_objects:
    print(f'WARNING: {\"$file\"}: unconverted <object> referencing {obj}', file=sys.stderr)

if content != original:
    print(f'MODIFIED: {\"$file\"}', file=sys.stderr)
    sys.stdout.write(content)
    sys.exit(0)
else:
    sys.exit(1)
" > "$tmp" && {
        if [ "$DRY_RUN" = true ]; then
            echo "Would modify: $file"
            diff "$file" "$tmp" || true
            rm -f "$tmp"
        else
            mv "$tmp" "$file"
            echo "Modified: $file"
        fi
    } || {
        # Exit code 1 means no changes
        rm -f "$tmp"
    }
}

for file in "${FILES[@]}"; do
    convert_file "$file"
done

echo "Done."
