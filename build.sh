mkdir -p _tmp/_odoc   
odoc_driver --odoc-dir _tmp/_odoc --odocl-dir _tmp/_odoc --html-dir _tmp/html --packages-dir reference --lib-map _tmp/_odoc/lib_map.json
odoc_notebook opam core patience_diff astring brr note --output _tmp/html
mkdir -p _tmp/html/assets
odoc_notebook generate `find blog -name "*.mld"` `find notebooks -name "*.mld"` index.mld reference/index.mld --output _tmp/html --odoc-dir _tmp/_odoc




