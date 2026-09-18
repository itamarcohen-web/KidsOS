# Local Safety AI System (Milestone 4)

A fully local, privacy-preserving pipeline that periodically samples
the Child's screen, runs OCR + a local text-safety classifier + a
pluggable local vision-safety engine, escalates through a Context/Risk
engine, and stores structured `SafetyEvent`s. No cloud AI dependency
exists anywhere in this system — see "Offline guarantee" below.

## Two processes, split by a real security boundary

```
Child's own graphical session                 System (root/kidsos-service)
┌─────────────────────────────┐               ┌───────────────────────────┐
│ kidsos-safety-agent          │  ReportEvent  │ kidsos-safety              │
│  SafetyScheduler (120s)      │─────D-Bus────▶│  org.kidsos.Safety1        │
│  IScreenCaptureProvider      │  Heartbeat    │  SafetyEventStore (SQLite) │
│  TesseractOcrEngine          │               │  /var/lib/kidsos/safety/   │
│  RuleBasedTextClassifier     │               │  events.db (0600)          │
│  ILocalVisionEngine          │               │  SafetyPolicy              │
│  ContextEngine / RiskEngine  │               │  /etc/kidsos/              │
└─────────────────────────────┘               │  safety-policy.json         │
                                                └───────────────────────────┘
```

Why two processes: Wayland's screen-capture security model (the XDG
Desktop Portal) requires the capture request to originate from inside
the session being captured. `kidsos-safety-agent` therefore has to run
as the Child's own uid — which means it must never be the thing with
write access to the events database, or a compromised/patched agent
process could fabricate or suppress its own evidence. `kidsos-safety`
(unprivileged as `kidsos-service`, same pattern as `kidsos-policy`) is
the only thing that ever opens `events.db`; the agent only ever calls
`ReportEvent`/`Heartbeat` over D-Bus. See `docs/SECURITY_ARCHITECTURE.md`
for the exact D-Bus/polkit wiring.

**Known limitation**: because the agent necessarily runs in the
Child's own session, a technically sophisticated Child could kill or
patch it. This milestone's mitigation is `Restart=on-failure` on the
`kidsos-safety-agent.service` user unit. Parent-visible "agent has been
silent for N minutes" alerting is future work — see
`docs/KNOWN_LIMITATIONS.md`.

## The pipeline, per sample

```
SafetyScheduler (every 120s, monotonic-clock based, spec §43)
  │
  ▼
IScreenCaptureProvider.captureActiveScreen()
  │  WaylandPortalCapture (org.freedesktop.portal.Screenshot) on Wayland
  │  X11Capture (QScreen::grabWindow) on X11
  ▼
TesseractOcrEngine.recognize()  — eng/heb/ara, chosen from system locale
  │
  ▼
RuleBasedTextClassifier.AnalyzeText()  — Stage-1 gate (spec §7)
  │
  ├─ confidence below SafetyPolicy.safeThreshold → SAFE, discard,
  │  Heartbeat() only (nothing stored — spec §19)
  │
  ▼ (Suspicious)
ILocalVisionEngine.AnalyzeImage()  — Stage-2, only reached if Stage-1
  │  flagged something (spec §7: minimizes CPU/RAM cost)
  ▼
ContextEngine.adjust()  — sequence-aware escalation/de-escalation
  │  (spec §13/§14 worked examples, see below)
  ▼
RiskEngine.combine()  — final category/severity/confidence/explanation,
  │  using SafetyPolicy's centralized thresholds
  ▼
severity == Safe? → Heartbeat() only
severity != Safe? → ReportEvent() → SafetyEventStore (SQLite)
```

## Stage-1: `RuleBasedTextClassifier`

A versioned keyword/pattern table
(`/usr/lib/kidsos/models/text-safety/rules-0.1.json` +
`model.json` manifest), not a trained model — this is the "small,
efficient model for the first prototype" spec §54 asks for. Every rule
is a regex pattern with a weight; the highest-weight match on the
OCR'd text becomes the raw category/confidence.
`ModelManager::verifyIntegrity()` SHA-256-checks the rules file against
`model.json` before it's ever loaded (spec §22/§36) —
`tests/validate_safety_model_manifests.py` catches a manifest/file hash
drift statically, and `tests/validate_text_safety_rules.py` exercises
the actual rule table against the synthetic fixtures in
`tests/fixtures/safety/text/` (spec §41's 11 scenarios).

## Stage-2: the modular vision architecture

```
IVisionSafetyModel   — AnalyzeImage(), GetCategory(), GetModelVersion(), GetModelMetadata()
ILocalVisionEngine   — manages whichever providers are available
  ├── MockVisionEngine   — deterministic: matches an image's SHA-256
  │                        against the fixtures in
  │                        tests/fixtures/safety/images/ and returns
  │                        fixed results. Opt-in only
  │                        (KIDSOS_SAFETY_MOCK_VISION=1) — never the
  │                        default, so a shipped image can't
  │                        accidentally claim mock output is real
  │                        detection. engineKind() always reports
  │                        "Mock / Development".
  └── OnnxVisionEngine   — real ONNX Runtime plumbing (onnxruntime,
                           onnxruntime-devel). Scans
                           /usr/lib/kidsos/models/vision-safety/{nsfw,violence}/
                           for a model.json + model.onnx; loads a
                           session only if the manifest is
                           APPROVED_FOR_DISTRIBUTION and
                           integrity-verified. **No model ships this
                           milestone** — every category reports
                           NOT_AVAILABLE until one is installed. The
                           self-harm category is hardcoded to always
                           report NOT_AVAILABLE regardless of what's on
                           disk (see below) — that exclusion is a
                           deliberate code-level decision, not a
                           missing feature.
```

Preprocessing contract `OnnxVisionEngine` assumes for any model that
*is* loaded: single input tensor, NCHW float32, 224×224, RGB values
scaled to `[0,1]`. This is documented, not verified — no model ships to
test it against.

### Why no vision model is bundled

Detecting sexual content, violence, or self-harm imagery from
screenshots needs a trained image classifier. This project can't train
one (no training data, no compute in this environment), and silently
bundling a third-party pretrained model is a licensing/provenance/
accuracy decision with real liability implications for a children's
product — not something to decide unilaterally. So this milestone
ships the complete pluggable architecture instead: `IVisionSafetyModel`
category interfaces, `ModelApprovalStatus`, integrity verification, and
`MockVisionEngine` for exercising the rest of the pipeline (Context
Engine → Risk Engine → SafetyEvent → storage) end to end. A real model
slots in later without touching anything upstream of
`ILocalVisionEngine`.

### `ModelApprovalStatus`

```
UNREVIEWED  → DEVELOPMENT_ONLY  → LEGAL_REVIEW_REQUIRED  → APPROVED_FOR_DISTRIBUTION
                                                          ↘ DISABLED
```

Only `APPROVED_FOR_DISTRIBUTION` may be loaded by `OnnxVisionEngine` in
what the dev diagnostic screen (Settings → Local AI Models, Parent-only
— see below) presents as production capability. Every model directory
under `/usr/lib/kidsos/models/vision-safety/` currently ships as a
placeholder `model.json` with `approvalStatus: "UNREVIEWED"` and no
`model.onnx` — see each directory's manifest for the specific
provenance notes.

### Model evaluation workflow (for a future candidate model)

```
Candidate model → license review → dataset/provenance review →
technical benchmark → false-positive benchmark → performance benchmark →
commercial suitability review → APPROVED_FOR_DISTRIBUTION / REJECTED
```

This is a human decision process, not something an AI coding session
can complete on its own — see `THIRD_PARTY_NOTICES.md` at the repo
root for the one candidate-model caveat already on record (public
Hugging Face NSFW/violence models exist, some tagged Apache-2.0, but an
Apache-2.0 *code/weights* license doesn't by itself resolve training-data
provenance for commercial use).

## Context Engine: two worked examples, actually implemented

- **Escalation** (spec §13): a second `PERSONAL_INFORMATION_REQUEST` in
  the same rolling window (10 samples / 15 minutes) raises confidence
  by +0.25 over Stage-1's raw score; a `SECRECY_REQUEST` following an
  earlier personal-information request in the window is reclassified
  as `GROOMING_INDICATORS` with confidence floored at 0.85.
- **De-escalation** (spec §14): a `Violence` vision hit inside an
  application `IActiveApplicationProvider::isKnownGame()` recognizes,
  with nothing else suspicious in the window, is capped at confidence
  0.2 (informational, not a real incident).

See `files/apps/safety-agent/src/engine/ContextEngine.cpp` for the
exact logic — it's plain conditional code, not a model, so it's fully
inspectable.

## What's genuinely verified vs. what needs a live VM

Verified by this repo's static checks
(`tests/validate_safety_model_manifests.py`,
`tests/validate_text_safety_rules.py`,
`tests/validate_mock_vision_fixtures.py`,
`tests/validate_dbus_consistency.py`) and by the GitHub Actions build
actually compiling and linking every new binary against real Tesseract/
ONNX Runtime/Qt6Sql headers: the D-Bus/polkit wiring is self-consistent,
the rule table classifies all 11 spec §41 scenarios correctly, model
manifests are well-formed and hash-correct, and the whole thing builds.

**Needs a live KDE Plasma Wayland session to actually confirm** (see
`docs/KNOWN_LIMITATIONS.md`):
- Whether `org.freedesktop.portal.Screenshot` with `interactive: false`
  silently succeeds for a non-interactive automated caller, or
  re-prompts every time.
- Whether `KWinActiveApplicationProvider`'s D-Bus-scripting-plus-journal
  readback actually resolves the active window's app id in practice.
- The 120-second scheduler's real-world behavior across an actual
  system suspend/resume cycle.
- Real CPU/RAM impact while a game/video/browser is in the foreground.

## Offline guarantee

Nothing in this pipeline makes a network request. `ISafetyEventExporter`
and `IParentSyncService` are real C++ interfaces with literal no-op
implementations (`NoOpSafetyEventExporter`, `NoOpParentSyncService`) —
`IParentSyncService::isEnabled()` returns `false`, so there is no code
path that could accidentally phone home. OCR, the text classifier, and
(if a model is ever installed) vision inference all run against locally
packaged data under `/usr/lib/kidsos/models/` — never fetched from a
URL at runtime (spec §9/§22/§51).

## What's never collected

No keylogging, no webcam/microphone recording, no covert/hidden
capture cadence beyond the documented 120-second interval, no password/
PIN/auth-secret storage. `SafetyEvent` (see
`files/core/services/common/safety/SafetyTypes.h`) never includes raw
screen content — only category/severity/confidence/summary/application/
timestamp. Raw frames live in RAM only, for the duration of one
sample's analysis, and are never written to disk for `SAFE`/`LOW`
results (spec §19/§20).
