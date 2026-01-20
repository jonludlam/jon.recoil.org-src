# jon.recoil.org

Source repository for [jon.recoil.org](https://jon.recoil.org), a personal website/blog built using OCaml and odoc.

## Development (Devcontainer)

### Starting Up

1. Open the repo in VS Code/Cursor
2. When prompted, click "Reopen in Container" (or use Command Palette → "Dev Containers: Reopen in Container")
3. First time: Docker builds the `dev` stage (~15-20 min). After that it's cached.

### Building the Site

```bash
./build.sh
```

On first run, this does three slow setup steps (only once):
1. `odoc_driver` → generates `_tmp/_odoc/lib_map.json`
2. `jtw opam` (5.2.0) → generates `_tmp/html/_opam/`
3. `jtw opam` (oxcaml) → generates `_tmp/html/oxcaml/`

After that, only the fast `odoc_notebook generate` runs.

### Previewing Locally

```bash
python3 -m http.server 8000 -d _tmp/html
```

Then open http://localhost:8000 (port 8000 is forwarded to your host).

### Edit-Build-Preview Cycle

1. Edit `.mld` files in `blog/`, `notebooks/`, `notes/`, etc.
2. Run `./build.sh`
3. Refresh browser

### Deploying

Use `deploy.sh` from **outside** the container (on your host) for production deploys - it does a clean Docker build to ensure reproducibility.

For faster deploys from inside the container (requires SSH keys):
```bash
./build.sh
cd _tmp/html && tar jcf ~/site.tar.bz2 .
scp ~/site.tar.bz2 jon@jon.recoil.org:
ssh jon@jon.recoil.org 'cd /var/www/jon.recoil.org && tar jxvf ~/site.tar.bz2'
```

### Resetting

To force a full rebuild:
```bash
rm -rf _tmp
./build.sh
```
