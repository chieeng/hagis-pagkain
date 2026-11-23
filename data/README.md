# Question bank format (owner: Jian)

One file per biome: `items_forest.json`, `items_river.json`, `items_mountain.json`, `items_sky.json`.
Each file is a JSON array of items:

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Unique, e.g. `forest-001` |
| `biome` | yes | `forest`, `river`, `mountain` or `sky` |
| `pair` | yes | `din/rin`, `daw/raw`, `dito/rito`, `diyan/riyan`, `doon/roon` |
| `sentence` | yes | Sentence with `___` where the particle goes |
| `prev_word` | yes | The word right before the blank, exactly as it appears in the sentence |
| `answer` | yes | The KWF preferred form. The tests check it against `core/DRRule.gd` |
| `translation` | yes | English translation (for the team and adviser, not shown to learners) |
| `status` | yes | `draft` until checked against KWF and approved by the adviser, then `approved` |
| `note` | no | Source, reviewer, or why the item is there |

Rules:
- Only `approved` items go into the pilot/evaluation build (set `QuestionBank.include_drafts = false`).
- Each biome needs some exception items (`-ra`, `-ri`, `-raw`, `-ray`). They are mostly used in Sky.
- Do not write items that teach `-ro` or `-re` as exceptions. They are not KWF exceptions.
- AI-drafted items always start as `draft`.
