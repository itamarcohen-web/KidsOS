# External application trust model

## States

```
UNKNOWN/UNTRUSTED ──(parent approves exact hash)──> TRUSTED ──(parent revokes)──> UNTRUSTED
        │
        └─(child attempts execution)──> BLOCKED (fapolicyd denies the exec() syscall)
```

Everything not explicitly trusted defaults to **blocked**, per spec §20
("unknown applications should default to BLOCK until parent approval").

## Why hash-based trust resists the listed bypasses

fapolicyd's trust database keys on **file content** (SHA-256), not path
or name. `kidsos-file-guard`'s `TrustFile` call writes an entry shaped
like:

```
/home/kid/Downloads/game.AppImage 48213504 3f9a...c21
```

(fapolicyd's trust-file format: `<absolute path> <size> <sha256>`, three
space-separated fields, no literal `size`/`sha256` keywords.)

fapolicyd computes the hash of whatever is actually being executed at
`exec()` time and compares it against the trust database — this is a
kernel-level `fanotify` hook (`PERM` events), evaluated by the
`fapolicyd` daemon before the kernel allows the process to run, for
*every* process on the system (not just ones launched through a GUI).
That's what makes each listed bypass attempt fail:

| Bypass attempt | Why it still fails |
|---|---|
| Open a terminal, run `./game.AppImage` directly | Same `exec()` syscall, same fanotify hook — no GUI is involved in enforcement |
| Rename `game.AppImage` → `totally-safe.txt`, then `chmod +x` and run it | Hash is computed from content, not the name |
| Copy the file to another directory | Same bytes → same hash → same trust decision |
| Create a symlink to it | The kernel resolves the symlink to the real inode before `exec()`; fapolicyd hashes that real file |
| Use `dnf`/`rpm` directly instead of the KidsOS install flow | The child account has no `sudo`/`wheel` — `dnf install` fails at the polkit/privilege layer before fapolicyd is even relevant |
| Change the file extension | fapolicyd (and KidsOS's MIME-type detection) don't trust extensions either — `kidsos-installer` identifies file type via `libmagic`-style content sniffing, matching spec §21's "detect ELF/AppImage/scripts/packages," not `*.AppImage` string matching |

## Why re-approval is required after modification (spec §25)

`kidsos-installer::ApproveRequest` re-hashes the file at approval time
and once more immediately before triggering `TrustFile`, comparing both
against the hash captured when the request was **submitted**. If the
child (or anything else) has modified the file in between — even one
byte — the hashes differ and the approval is rejected outright; the
parent would need to approve the new version as a new request. This
mirrors exactly fapolicyd's own behavior: even if a stale approval
somehow got through to `TrustFile`, fapolicyd would still refuse to
execute a file whose current hash doesn't match the trust entry that
was written for the *previous* version's hash.

## MIME/content detection (spec §21–23)

`kidsos-installer` classifies a submitted external file using its
magic-byte signature, not its extension:

- ELF header (`\x7fELF`) → executable binary
- AppImage (ELF + an embedded AppImage type marker, or `.AppImage`
  filename as a hint only, never the sole signal) → external app
- `#!` shebang → script
- `ar` archive with `debian-binary` member → `.deb` package
- RPM lead magic (`\xed\xab\xee\xdb`) → `.rpm` package
- Everything else (PDF/DOCX/JPG/PNG/TXT signatures, or simply "not
  executable and not a known package format") → ordinary document,
  **not** subject to the approval flow at all, per spec §21.

Package files (`.deb`/`.rpm`) are routed the same way as any other
external executable request, but on approval `kidsos-installer` invokes
the appropriate privileged installer (`dnf`/`rpm` via a tightly-scoped
`QProcess` call, still gated by the same hash-revalidation) instead of
`TrustFile` + direct execution — a package install is a system-state
change, not just "let this one binary run."

## What this milestone does *not* claim

fapolicyd enforcement is a real, standard Fedora security mechanism —
but the exact rule syntax in `core/configuration/fapolicyd/kidsos.rules`
was written by hand against fapolicyd's documented rule grammar and
**has not been loaded into a running fapolicyd** in this development
environment (no Linux host available — see
`docs/KNOWN_LIMITATIONS.md`). Before relying on this, load the rules on
a real Fedora system (`fagenrules --load`, `fapolicyd-cli --list`) and
confirm with `fapolicyd-cli -t` (trust check) and by actually attempting
each bypass in the table above.
