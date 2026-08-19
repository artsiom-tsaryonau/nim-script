# nim-script

A script runner for Nim with inline //DEPS — Nimble, GitHub, and git remotes.

jbang-style single-file scripts. Every dep is explicit: `requires:`, `gh:`, or `git:`.

### Runner (put `ns` on PATH)

```bash
git clone git@github.com:artsiom-tsaryonau/nim-script.git
cd nim-script
chmod +x ns
export PATH="$PWD:$PATH"
# permanent: sudo ln -sf "$PWD/ns" /usr/local/bin/ns
# Needs Bash 4.3+ (nameref). On macOS: brew install bash
ns selfcheck
```

### Install (once per machine)

Host tools only — Bash, nim, nimble, curl. Package *trees* land in an isolated `HOME` inside each script's cache entry, not in `~/.nimble`.

**Fedora**

```bash
sudo dnf install bash nim curl git
# nimble ships with the nim package
```

**macOS**

```bash
brew install bash nim curl git
export PATH="$(brew --prefix bash)/bin:$PATH"   # stock /bin/bash is 3.2
# nimble ships with the nim formula
```

You do **not** need a checked-in `package.nimble`. `ns` generates one per script in the cache when `//DEPS` is present. You do **not** need different `//DEPS` per OS.

Still global by design: the `nim` compiler, `nimble`, and `curl`. Everything nimble *downloads* for a script lands under that script's cache entry (`<cache>/<sha>/home/`).

## Usage

```bash
ns examples/hello.nim
ns clean examples/hello.nim
```

Scripts use normal `.nim` extensions. The binary runs with **cwd = the directory where you invoked `ns`** (not the cache build dir). `NS_CWD` is set to the same path.

### Project env (optional)

```bash
ns env init                  # .ns/{cache,activate}
source .ns/activate          # or: eval "$(ns env activate)"
ns examples/hello.nim        # builds → .ns/cache
```

Layout:

```text
.ns/
  activate
  cache/                 # per-script builds + isolated nimble HOME
```

If `.ns/` exists in the current directory (or `NS_ROOT` is set), `ns` picks it up automatically. Add `.ns/` to `.gitignore`.

```bash
ns clean examples/hello.nim   # drop one script's build dir
ns clean --all                # wipe cache only
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the pipeline.

## `//DEPS`

Same comment style as [cx-script](https://github.com/artsiom-tsaryonau/cx-script). **No Conan/vcpkg** — Nimble `requires` only.

Prefix is **required**:

| Prefix | Ref | Backend |
|--------|-----|---------|
| `requires:` | `pkgname` | Nimble registry package |
| `gh:` | `owner/repo/ref` (3 parts) | GitHub → `requires "https://github.com/owner/repo#ref"` |
| `git:` | `https://host/…/repo.git#ref` | Any git URL → Nimble `requires` |

`gh:` is GitHub shorthand. `git:` is the same path with a **full repository URL** (GitLab, Codeberg, self-hosted, …).

```nim
//DEPS requires:jsony
//DEPS gh:owner/repo/ref
//DEPS git:https://gitlab.com/user/repo.git#v1.0
```

With no `//DEPS`, `ns` compiles with `nim c` directly. With deps, it generates `package.nimble`, runs `nimble install --depsOnly`, then builds.

**Note:** `nimble` must be on `PATH` whenever `//DEPS` is present.

## Shebang

```nim
#!/usr/bin/env ns
```

## Cache

Resolution order:

1. `NS_CACHE` if set  
2. `$NS_ROOT/cache` or `./.ns/cache` when a project env exists  
3. `${XDG_CACHE_HOME:-~/.cache}/nim-script`

Each script gets `<cache>/<sha256(abspath)>/`. Stamp is `content|host|nim@version|nimble@version`. Unchanged stamp → warm exec.

## Platforms

Tested target: **macOS** and **Fedora** with Homebrew/dnf `bash`, `nim`, and `nimble`.
