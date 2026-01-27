#!/bin/bash
# Setup project-specific OCaml packages for jon.recoil.org
set -ex

# The pinned packages require OCaml 5.2.0, not the default 5.3.0
# Check if 5.2.0 switch exists, create if not
if ! opam switch list | grep -q "^[[:space:]]*5.2.0[[:space:]]"; then
    echo "Creating 5.2.0 switch (required for build tools)..."
    opam switch create 5.2.0 ocaml.5.2.0 -y
fi

# Set 5.2.0 as the active switch for this project
opam switch set 5.2.0

# Initialize opam environment
eval $(opam env)

# Ensure opam env is loaded in future shell sessions
if ! grep -q "opam env" ~/.bashrc 2>/dev/null; then
    echo 'eval $(opam env)' >> ~/.bashrc
fi
if ! grep -q "opam env" ~/.zshrc 2>/dev/null; then
    echo 'eval $(opam env)' >> ~/.zshrc
fi

# Create workspace directories needed by build.sh
mkdir -p /workspace/_tmp/_odoc /workspace/_tmp/html/assets

# Pin and install packages for 5.2.0 switch (use -y for non-interactive)
opam pin add -y -n git+https://github.com/jonludlam/js_of_ocaml#fs_fake_fix
opam pin add -y -n git+https://github.com/jonludlam/js_top_worker#learno
opam pin add -y -n git+https://github.com/jonludlam/mime_printer#odoc_notebook
opam pin add -y -n git+https://github.com/jonludlam/mdx#learno
opam pin add -y -n git+https://github.com/jonludlam/merlin-js#odoc_notebook
opam pin add -y -n git+https://github.com/jonludlam/jsoo-code-mirror#rework-interface
opam pin add -y -n git+https://github.com/jonludlam/odoc#learno
opam pin add -y -n git+https://github.com/jonludlam/odoc_notebook
opam update
# Use opam-format 2.1.6 - newer versions removed OpamStd.String.starts_with used by pinned packages
opam install -y opam-format.2.1.6
opam install -y core base bos odoc_notebook odoc-driver patience_diff astring brr note js_top_worker-bin rresult
opam install -y mariadb caqti cohttp
opam install -y syndic ptime ISO8601

# Pin and install packages for oxcaml switch (5.2.0+ox)
# Note: Do NOT pin js_of_ocaml here - the oxcaml repo has a compatible version
opam pin add -y --switch 5.2.0+ox -n git+https://github.com/jonludlam/js_top_worker#oxcaml
opam pin add -y --switch 5.2.0+ox -n git+https://github.com/jonludlam/mime_printer#odoc_notebook
opam install --switch 5.2.0+ox -y mime_printer js_top_worker js_top_worker-web core astring
# TODO: Re-enable when oxcaml_effect checksum is fixed upstream
# opam install --switch 5.2.0+ox -y parallel

echo "Project setup complete!"
echo "Active switch is now 5.2.0"
echo "Run 'eval \$(opam env)' or start a new shell to use opam tools."
