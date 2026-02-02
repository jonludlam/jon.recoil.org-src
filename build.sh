#!/bin/bash
set -e

mkdir -p _tmp/_odoc _tmp/html/assets

# Run odoc_driver if not already done (generates package docs)
if [ ! -f _tmp/_odoc/lib_map.json ]; then
    echo "Running odoc_driver (first time setup)..."
    odoc_driver --odoc-dir _tmp/_odoc --odocl-dir _tmp/_odoc --html-dir _tmp/html --packages-dir reference --lib-map _tmp/_odoc/lib_map.json
fi

# Run jtw opam for standard switch if not already done
if [ ! -d _tmp/html/_opam ]; then
    echo "Running jtw opam for 5.2.0 switch (first time setup)..."
    jtw opam core cohttp patience_diff astring brr note mime_printer fpath rresult opam-format bos odoc.model --output _tmp/html/_opam
fi

# Run jtw opam for oxcaml switch if not already done
if [ ! -d _tmp/html/oxcaml ]; then
    echo "Running jtw opam for oxcaml switch (first time setup)..."
    # TODO: Add parallel back when oxcaml_effect checksum is fixed upstream
    jtw opam --switch 5.2.0+ox --output _tmp/html/oxcaml core mime_printer astring
fi

# Generate notebooks from content
dune exec -- odoc_notebook generate \
    blog notes drafts notebooks \
    index.mld reference/index.mld \
    --output _tmp/html --odoc-dir _tmp/_odoc

# Generate atom feed
dune exec -- scripts/gen_atom.exe
mv atom.xml _tmp/html/
