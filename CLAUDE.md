# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the source repository for jon.recoil.org, a personal website/blog built as a static site using OCaml. The site features interactive OCaml notebooks that execute code in the browser, technical blog posts, and educational content including Cambridge Foundations of Computer Science material.

## Build Commands

### Full Production Build (via Docker)
```bash
./deploy.sh  # Builds Docker image, extracts site.tar.bz2, deploys to server
```

### Local Development Build
```bash
./build.sh   # Runs odoc_driver + odoc_notebook to generate site
```

The build process:
1. `odoc_driver` compiles OCaml documentation to `_tmp/_odoc` and `_tmp/html`
2. `odoc_notebook opam` prepares OPAM packages for browser execution
3. `odoc_notebook generate` converts .mld files into interactive notebooks

### Working with odoc_notebook
```bash
cd odoc_notebook
dune build                    # Build the tool
dune test                     # Run tests
dune exec -- odoc_notebook generate file.mld --odoc-dir _tmp/_odoc  # Generate single notebook
```

See `odoc_notebook/CLAUDE.md` for detailed guidance on the notebook generation tool.

## Architecture

### Content Structure
- `blog/` - Blog posts organized by year/month in `.mld` format
- `notebooks/` - Interactive educational notebooks (foundations/, oxcaml/)
- `notes/` - Personal notes
- `drafts/` - Unpublished content
- `reference/` - Documentation index

### Key Components
- **odoc_notebook/** - The core tool that converts .mld files into interactive browser notebooks. Has its own dune project and CLAUDE.md.
- **scripts/** - Build utilities including `gen_atom.exe` for RSS feed generation
- **static/** - Static assets (images, CSS)

### Content Format
Content uses `.mld` (odoc markup language) files with code blocks annotated as:
- `{@ocaml}` - Static code display
- `{@ocamltop}` - Interactive toplevel cells
- `{@ocaml deferred-js}` - Client-side compiled code

### Two OPAM Switches in Docker
- `5.2.0` - Standard OCaml for most packages
- `oxcaml` (5.2.0+ox) - OxCaml extensions for parallelism tutorials

## Code Style

- OCamlFormat v0.27.0 (see `.ocamlformat`)
- Format with: `ocamlformat -i file.ml`
