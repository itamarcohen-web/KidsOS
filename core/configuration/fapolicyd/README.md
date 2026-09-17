# fapolicyd configuration

- `35-kidsos-children.rules` → installed to `/etc/fapolicyd/rules.d/`,
  then compiled into `/etc/fapolicyd/compiled.rules` by `fagenrules`
  (run once at image build time, and again by `kidsos-file-guard` via
  `fapolicyd-cli --update` whenever `kidsos-approved.trust` changes).
- `/etc/fapolicyd/trust.d/kidsos-approved.trust` is **not** shipped here
  — it starts empty (no external apps pre-trusted) and is owned/managed
  entirely by `kidsos-file-guard` at runtime.

See `docs/TRUST_MODEL.md` for the enforcement model and
`docs/SECURITY_ARCHITECTURE.md` for the service that manages this file.
