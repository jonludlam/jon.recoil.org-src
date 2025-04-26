FROM ocaml/opam:ubuntu-24.04-ocaml-5.1
RUN opam pin add -n git+https://github.com/jonludlam/jsoo-code-mirror#rework-interface
RUN echo yooo
RUN opam pin add -n git+https://github.com/jonludlam/js_top_worker#learno
RUN opam pin add -n git+https://github.com/jonludlam/mdx#learno
RUN opam pin add -n git+https://github.com/jonludlam/merlin-js#odoc_notebook
RUN opam pin add -n git+https://github.com/jonludlam/mime_printer#odoc_notebook
RUN echo boo
RUN opam pin add -n git+https://github.com/jonludlam/odoc#learno
RUN opam pin add -n git+https://github.com/jonludlam/odoc_notebook
RUN opam install core base bos odoc_notebook odoc-driver patience_diff astring brr note
COPY blog /build/blog
COPY notebooks /build/notebooks
COPY scripts /build/scripts
COPY static /build/static
COPY reference /build/reference
COPY dune-project index.mld /build/
RUN sudo chown opam:opam -R /build
RUN mkdir -p /build/_tmp/_odoc /build/_tmp/html/assets
RUN cd /build && opam exec -- odoc_driver --odoc-dir _tmp/_odoc --odocl-dir _tmp/_odoc --html-dir _tmp/html --packages-dir reference --lib-map _tmp/_odoc/lib_map.json
RUN echo foo
RUN opam upgrade odoc_notebook
WORKDIR /build
RUN opam exec -- odoc_notebook opam core patience_diff astring brr note --output _tmp/html
RUN opam exec -- odoc_notebook generate `find blog -name "*.mld"` `find notebooks -name "*.mld"` index.mld reference/index.mld --output _tmp/html --odoc-dir _tmp/_odoc 
RUN opam install syndic ptime ISO8601
RUN opam exec -- dune exec -- scripts/gen_atom.exe
RUN mv atom.xml _tmp/html
RUN cd _tmp/html && tar jcf /build/site.tar.bz2 .
 






