# Architecture

How `ns` turns a script into a running binary.

## Bash baseline

Requires **Bash 4.3+** (`nameref`, solid arrays). `ns selfcheck` verifies bash version, nim, a no-deps compile/run, and the `//DEPS` regex.

Notable practices: `set -euo pipefail`, `type -P` for nim/nimble, `pwd -P`, mkdir locks (not `flock`), stamp re-check after lock, isolated `HOME` for nimble, no `eval` for path mutation.

```text
script.nim
    │
    ├─ cache base: NS_CACHE | $NS_ROOT/cache | ./.ns/cache | XDG ~/.cache/nim-script
    │
    ├─ warm?  (.ns_stamp == content|host|nim@ver|nimble@ver && binary exists)
    │         → prepare_run_env → cd $CALLER_PWD → exec
    │
    ├─ parse //DEPS lines
    │     requires:pkgname     → Nimble registry requires
    │     gh:…/…/ref           → requires "https://github.com/owner/repo#ref"
    │     git:https://…#ref    → requires "https://…#ref" (any git host)
    │
    ├─ strip shebang → copy as script.nim in cache
    │
    ├─ if any //DEPS: generate package.nimble
    │     HOME=<cache>/home → nimble install --depsOnly
    │     nimble build (fallback: nim c) → cache/script
    │
    └─ else: nim c -o:script --mm:orc
         then prepare_run_env → cd $CALLER_PWD → exec
```

Build uses **ORC** (`--mm:orc`). Generated `package.nimble` lives only in the cache workspace.

### CWD contract

Build artifacts live under the cache dir; **execution** restores the caller’s working directory and sets `NS_CWD` to that path. Scripts do not receive a synthetic `argv[1]` path.

### Run-time libraries

Nim produces a standalone binary by default. Nimble deps compile into the executable; no separate library path setup for typical scripts.

## Project env (`.ns/`)

```text
.ns/
  activate              # source this, or eval "$(ns env activate)"
  cache/                # per-script build workspaces + isolated nimble HOME
```

`ns env init` creates this layout. Presence of `./.ns` (or `NS_ROOT`) redirects cache without requiring activate.

Each script cache entry also has `<sha>/home/` — a private `HOME` for nimble so packages never land in `~/.nimble`.

**Still host-global:** `nim`, `nimble`, `curl`. **Cache-local:** nimble downloads, per-script build trees.

This is **not** a VM or a full sysroot. Recreate `.ns` on each machine with `ns env init`; don’t copy it across OS/arch.

## `//DEPS` contract

Every dependency **must** start with a prefix:

| Prefix | Role |
|--------|------|
| `requires:` | Nimble registry package (e.g. `jsony`) |
| `gh:` | GitHub shorthand → `requires "https://github.com/owner/repo#ref"` |
| `git:` | Any git host — full URL with `#ref` |

No Conan/vcpkg — Nimble `requires` only.

### `requires:` shape

- `requires:jsony` → appended to generated `package.nimble` as `requires "jsony"`.

### `gh:` shape

- **3** path segments (`owner/repo/ref`) → `requires "https://github.com/owner/repo#ref"`.
- **4+** segments are not supported (unlike cx/zs raw file fetch).

### `git:` shape

- `git:https://gitlab.com/user/repo.git#v1.0` → `requires "https://gitlab.com/user/repo.git#v1.0"`.
- URL must include `#ref`.

### `AS`

Parsed by the regex but **not applied** yet for Nimble git deps — package name comes from the remote repo.

### Brackets `[…]`

Not supported yet — `ns` errors if options appear in brackets.

## Why Nimble + isolated HOME

- **Nimble** owns the dependency *graph* for registry and git packages.
- **Isolated HOME** keeps downloads out of the user’s global `~/.nimble` — each script cache entry is self-contained.
- **Generated package.nimble** declares the ephemeral package; nothing checked into the script repo.
- Portable unit is `//DEPS` (+ optional project `.ns` layout), not downloaded package blobs in the script repo.

## Invalidation

| Change | Effect |
|--------|--------|
| Script bytes change | New `.ns_stamp` → rebuild |
| OS/arch or nim/nimble path/version | New stamp → rebuild |
| `//DEPS` lines change | Regenerate `package.nimble` → nimble install + build |
| Otherwise | warm `exec` |

## CLI

```bash
ns <script.nim> [args...]
ns clean <script>|--all
ns env init [dir]
ns env activate [dir]    # eval "$(ns env activate)"
ns selfcheck
```

## What we deliberately skip (for now)

- `AS` alias for git/gh deps
- Bracket options on deps
- Raw single-file `gh:` fetch (use Nimble git requires instead)
- Shared global dedup across scripts
- Bundled nim toolchain
- Replacing `//DEPS` with a second lock dialect
