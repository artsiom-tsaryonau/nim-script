# nim-script

A script runner for Nim with inline //DEPS — Nimble, GitHub, and git remotes.

jbang-style single-file scripts. Dependencies live in `//DEPS` comments; Nimble packages install into an isolated dir inside each script's cache entry.

## Install

Put `ns` on your `PATH`. Requires **Bash 4.3+**, **nim**, **nimble**, and **curl** (for future gh fetches).

```bash
chmod +x ns
sudo ln -sf "$PWD/ns" /usr/local/bin/ns   # optional
ns selfcheck
```

## Usage

```bash
ns examples/hello.nim
ns clean examples/hello.nim
ns env init    # optional project-local .ns/
```

## //DEPS

Same comment style as [cx-script](https://github.com/artsiom-tsaryonau/cx-script). **No Conan/vcpkg** — Nimble `requires` only.

| Prefix | Example | Meaning |
| --- | --- | --- |
| `requires:` | `//DEPS requires:jsony` | Nimble package name |
| `gh:` | `//DEPS gh:owner/repo/ref` | → `requires "https://github.com/owner/repo#ref"` |
| `git:` | `//DEPS git:https://gitlab.com/user/repo.git#ref` | Any git URL |

## gh: vs git:

- **`gh:owner/repo/ref`** — GitHub shorthand (same as cx / zs).
- **`git:https://...#ref`** — full URL for other hosts.

## Shebang

```nim
#!/usr/bin/env ns
```

## Platforms

Tested target: **macOS** and **Fedora** with Homebrew/dnf `bash`, `nim`, `nimble`.
