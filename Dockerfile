# =============================================================================
# Stage 1: dev - Development environment with both OPAM switches
# =============================================================================
FROM ocaml/opam:ubuntu-24.04-ocaml-5.2 AS dev

# System dependencies
RUN sudo apt install -y build-essential autoconf

# Create oxcaml switch (5.2.0+ox) with OxCaml extensions
RUN opam switch create oxcaml 5.2.0+ox --repos with-extensions=git+https://github.com/oxcaml/opam-repository.git,default
RUN sudo ln -f /usr/bin/opam-2.3 /usr/bin/opam && opam init --reinit -ni

# Pin packages for oxcaml switch
RUN opam pin add --with-version 6.0.1+ox -n git+https://github.com/jonludlam/js_of_ocaml#oxcaml
RUN opam pin add -n git+https://github.com/jonludlam/js_top_worker#oxcaml
RUN opam pin add -n git+https://github.com/jonludlam/mime_printer#odoc_notebook

# Install packages for oxcaml switch
RUN opam install mime_printer js_top_worker js_top_worker-web core astring
# TODO: Re-enable when oxcaml_effect checksum is fixed upstream
# RUN opam install parallel

# Create standard 5.2.0 switch
RUN opam switch create 5.2.0
RUN opam update

# Pin packages for 5.2.0 switch
RUN opam pin add -n git+https://github.com/jonludlam/js_of_ocaml#fs_fake_fix
RUN opam pin add -n git+https://github.com/jonludlam/js_top_worker#learno
RUN opam pin add -n git+https://github.com/jonludlam/mime_printer#odoc_notebook
RUN opam pin add -n git+https://github.com/jonludlam/mdx#learno
RUN opam pin add -n git+https://github.com/jonludlam/merlin-js#odoc_notebook
RUN opam pin add -n git+https://github.com/jonludlam/jsoo-code-mirror#rework-interface
RUN opam pin add -n git+https://github.com/jonludlam/odoc#learno
RUN opam pin add -n git+https://github.com/jonludlam/odoc_notebook
RUN opam update

# Install packages for 5.2.0 switch
RUN opam install core base bos odoc_notebook odoc-driver patience_diff astring brr note js_top_worker-bin rresult opam-format
# Update apt cache for system dependencies needed by mariadb/caqti/cohttp
RUN sudo apt-get update && opam install mariadb caqti cohttp
RUN opam install syndic ptime ISO8601

# Update 5.2.0 switch (skip oxcaml upgrade - has dependency conflicts)
RUN opam update && opam upgrade -y

# Setup workspace directory
RUN sudo mkdir -p /build/_tmp/_odoc /build/_tmp/html/assets
RUN sudo chown opam:opam -R /build
WORKDIR /build

# =============================================================================
# Stage 2: build - Full production build
# =============================================================================
FROM dev AS build

# Pre-build package documentation (doesn't depend on user content)
RUN opam exec -- odoc_driver --odoc-dir _tmp/_odoc --odocl-dir _tmp/_odoc --html-dir _tmp/html --packages-dir reference --lib-map _tmp/_odoc/lib_map.json

# Pre-build JavaScript versions of opam packages
RUN opam exec -- jtw opam core cohttp patience_diff astring brr note mime_printer fpath rresult opam-format bos odoc.model --output _tmp/html/_opam
# TODO: Add parallel back when oxcaml_effect checksum is fixed upstream
RUN opam exec -- jtw opam --switch oxcaml --output _tmp/html/oxcaml core mime_printer astring

# Copy user content
COPY blog /build/blog
COPY notebooks /build/notebooks
COPY scripts /build/scripts
COPY static /build/static
COPY reference /build/reference
COPY notes /build/notes
COPY drafts /build/drafts
COPY dune-project index.mld /build/

# Generate notebooks from content
RUN opam exec -- odoc_notebook generate \
    $(find blog -name "*.mld") \
    $(find notes -name "*.mld") \
    $(find drafts -name "*.mld") \
    $(find notebooks -name "*.mld") \
    $(find notebooks -name "*.md") \
    index.mld reference/index.mld \
    --output _tmp/html --odoc-dir _tmp/_odoc

# Generate atom feed
RUN opam exec -- dune exec -- scripts/gen_atom.exe
RUN mv atom.xml _tmp/html

# Add slipshow presentations
RUN git clone https://github.com/jonludlam/focs-slipshow
RUN mkdir _tmp/html/slipshow
RUN cp focs-slipshow/slips/*.html _tmp/html/slipshow

# Create final archive
RUN cd _tmp/html && tar jcf /build/site.tar.bz2 .
