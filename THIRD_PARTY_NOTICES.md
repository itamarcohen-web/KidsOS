# Third-party model notices

This file tracks the licensing/provenance review status of every AI
model KidsOS ships or has evaluated for the Local Safety AI System
(Milestone 4 — see `docs/SAFETY_AI.md`). Per that document's model
approval workflow, **no model may be marked `APPROVED_FOR_DISTRIBUTION`
in its `model.json` manifest without an entry here documenting the
review**, and a model must not be bundled into a shipped image if its
licensing terms are unclear for commercial deployment to a children's
product.

## Models currently bundled

**None.** `/usr/lib/kidsos/models/text-safety/` ships a hand-authored
keyword/pattern table (own work, not a trained model — see below).
`/usr/lib/kidsos/models/vision-safety/{nsfw,violence,self-harm,general-safety}/`
each ship only a placeholder `model.json` with `approvalStatus:
"UNREVIEWED"` and no model file.

### `text-safety` (`rules-0.1.json`)

| Field | Value |
|---|---|
| Type | Hand-authored regex/keyword table, not a trained model |
| Author | KidsOS project (own work) |
| Training data | None — this is not a trained model |
| License | KidsOS project's own license |
| Review status | N/A — not a third-party model |

## Candidate models evaluated for future vision-safety integration

### Public Hugging Face NSFW/violence classifiers (general note, not a specific model)

- **What**: public Hugging Face Hub hosts several image classifiers
  marketed for NSFW/violence detection; some are tagged with a
  permissive code license (e.g. Apache-2.0) on the model repository
  itself.
- **Why not bundled**: an Apache-2.0 (or similar) license on the
  *published weights/code* does not, by itself, establish or resolve:
  - what training data was used and under what terms,
  - whether that training data's license/consent permits this specific
    commercial redistribution use case,
  - measured false-positive/false-negative rates against KidsOS's
    actual target scenarios (game content, memes, educational/medical
    imagery — see the Context Engine's de-escalation examples in
    `docs/SAFETY_AI.md`),
  - hardware/performance suitability for the target device class.
- **Review status**: `UNREVIEWED`. No specific model has been
  identified, downloaded, or evaluated. This entry exists only to
  record that this category of candidate was considered and explicitly
  not pursued without a real review, per `docs/SAFETY_AI.md`'s model
  evaluation workflow (license review → dataset/provenance review →
  technical benchmark → false-positive benchmark → performance
  benchmark → commercial suitability review → approved/rejected).

## Runtime dependencies (not "models," but worth recording here for completeness)

| Package | Purpose | License |
|---|---|---|
| Tesseract OCR (`tesseract`, `tesseract-langpack-{eng,heb,ara}`) | Local OCR — spec §10 | Apache-2.0 |
| Leptonica (`leptonica-devel`) | Tesseract's image-processing dependency | BSD-2-Clause |
| ONNX Runtime (`onnxruntime`, `onnxruntime-devel`) | Local inference runtime — spec §8/§36 | MIT |

These are widely-used open-source *libraries*, not trained models with
their own dataset-provenance questions, and are installed as ordinary
Fedora RPM packages (see `recipes/recipe.yml`) rather than vendored.
