FROM ocaml/opam:ubuntu-24.04-ocaml-5.2
RUN sudo apt install -y build-essential autoconf
RUN opam switch create oxcaml 5.2.0+flambda2 --repos with-extensions=git+https://github.com/jonludlam/opam-repository-js.git#with-extensions-jsoo-and-rename-new,default
RUN echo hi6
RUN opam pin add -n git+https://github.com/jonludlam/js_top_worker#oxcaml
RUN opam pin add -n git+https://github.com/jonludlam/mime_printer#odoc_notebook
RUN opam install mime_printer js_top_worker js_top_worker-web core astring
RUN opam install parallel
RUN opam switch create 5.2.0
RUN opam update
RUN opam pin add -n git+https://github.com/jonludlam/js_of_ocaml#fs_fake_fix
RUN opam pin add -n git+https://github.com/jonludlam/js_top_worker#learno
RUN opam pin add -n git+https://github.com/jonludlam/mime_printer#odoc_notebook
RUN opam pin add -n git+https://github.com/jonludlam/mdx#learno
RUN opam pin add -n git+https://github.com/jonludlam/merlin-js#odoc_notebook
RUN opam pin add -n git+https://github.com/jonludlam/jsoo-code-mirror#rework-interface
RUN echo boo
RUN opam pin add -n git+https://github.com/jonludlam/odoc#learno
RUN opam pin add -n git+https://github.com/jonludlam/odoc_notebook
RUN opam install core base bos odoc_notebook odoc-driver patience_diff astring brr note js_top_worker-bin rresult opam-format
RUN echo hi8
RUN opam update; opam upgrade -y
RUN opam update --switch oxcaml; opam upgrade -y --switch oxcaml
RUN sudo mkdir -p /build/_tmp/_odoc /build/_tmp/html/assets
RUN sudo chown opam:opam -R /build
RUN cd /build && opam exec -- odoc_driver --odoc-dir _tmp/_odoc --odocl-dir _tmp/_odoc --html-dir _tmp/html --packages-dir reference --lib-map _tmp/_odoc/lib_map.json
WORKDIR /build
RUN echo fooooopp
RUN opam update
RUN opam upgrade -y
RUN opam update --switch oxcaml; opam upgrade -y --switch oxcaml
RUN opam exec -- jtw opam core patience_diff astring brr note mime_printer fpath rresult opam-format bos --output _tmp/html/_opam
RUN opam exec -- jtw opam --switch oxcaml --output _tmp/html/oxcaml core mime_printer astring parallel
COPY blog /build/blog
COPY notebooks /build/notebooks
COPY scripts /build/scripts
COPY static /build/static
COPY reference /build/reference
COPY dune-project index.mld /build/
#RUN sudo chown opam:opam -R /build
RUN opam exec -- odoc_notebook generate `find blog -name "*.mld"` `find notebooks -name "*.mld"` `find notebooks -name "*.md"` index.mld reference/index.mld --output _tmp/html --odoc-dir _tmp/_odoc 
RUN opam install syndic ptime ISO8601
RUN opam exec -- dune exec -- scripts/gen_atom.exe
RUN mv atom.xml _tmp/html
RUN cd _tmp/html && tar jcf /build/site.tar.bz2 .
 






