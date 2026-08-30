# vibpe gentoo overlay

Personal Gentoo overlay (repo name `vibpe`), pkgcheck-clean.

## Usage

`/etc/portage/repos.conf/vibpe.conf`:

```ini
[vibpe]
location = /var/db/repos/vibpe
sync-type = git
sync-uri = https://github.com/vibpe/gentoo-overlay.git
auto-sync = yes
```

## Layout

- `metadata/layout.conf` — `masters = gentoo`, thin manifests (DIST entries
  only, generated with `ebuild <pkg>.ebuild manifest`)
- Distfiles that Portage cannot fetch upstream (e.g. Go module `-deps`
  tarballs) are attached to releases of this repository
