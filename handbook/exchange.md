# Exchange and CLI contract

## Input study

Required fields are `factors`, `levels`, `trajectories`, `seed`. Each factor requires `id`, `name`, `unit`, `lower`, `upper`. IDs are distinct ASCII letters, digits, underscore or hyphen, 1..64 characters. `plan_id` and `run_id` are reserved. Names have 1..128 UTF-16 units and units at most 32. JSON object keys must be unique; nesting is capped at 16. Typed JSON decoding requires declared fields; additional fields are not part of the design identity.

The generated plan schema is `vexstride/morris/1`. It contains the complete study and ordered run rows. Each run contains `id`, `trajectory`, `step`, `normalized`, `values`. Coordinates and IDs must match a fresh generation of the recorded study. Do not edit generated plans manually.

The model-input CSV header is `plan_id,run_id,<factor IDs in order>`. Numerical cells are physical parameter values, not normalized coordinates. A run ID is `t<zero-based trajectory>-s<zero-based step>`.

## Results

The exact CSV header is `plan_id,run_id,value`. Each result must match a known run and full plan fingerprint. Results may arrive in any order and in up to 128 CLI batch files. A duplicate is rejected even when the repeated value is identical. Merging returns rows in plan order; it never performs last-write-wins updates.

Missing results are listed explicitly. Analysis requires all rows; no interpolation, zero filling or incomplete-trajectory deletion is performed. A failed external model run should remain missing until it is repaired and rerun. Output must be a finite scalar; NaN and infinities are rejected.

CSV accepts commas, doubled quotes, quoted newlines, CRLF and LF record separators. Characters after a closing quote other than a delimiter are rejected. Blank extra records are not silently discarded. The writer emits CRLF. UTF-8 decoding is strict; a BOM is accepted by the CLI's decoder. The parser operates on already decoded strings.

Library text readers and writers are capped at 16 Mi UTF-16 units. CSV is capped at 32769 records including the header and 66 columns. CLI input files are capped at 16 MiB **before reading**, and must be regular files. A large generated plan may exceed serialization budgets even if its mathematical evaluation count is allowed; reduce the trajectory count in that case.

## Commands and exit codes

`example`, `plan`, `inputs`, `evaluate`, `merge`, `missing`, `analyze`, `report` print their output on stdout. `evaluate` is only a helper for the three supplied deterministic models. The tool does not launch arbitrary external model executables.

| Exit | Meaning |
| --- | --- |
| 0 | Successful output; `missing` found no missing rows. |
| 2 | Invalid study, plan, result, numerical range or work budget. |
| 3 | Results incomplete; use `missing` for row IDs. |
| 64 | Invalid command or argument count. |
| 74 | File access, file type, encoding or output failure not classified as study data. |

`missing` writes a JSON array of absent run IDs even when it returns 3. Diagnostics use stderr and avoid file paths or raw operating-system exception messages. The launcher/compiler can still print its own diagnostics; this contract applies to the built CLI's handling of data files.

`analyze` prints full-precision JSON under schema `vexstride/effects/1`. `report` prints static HTML with the same calculation. HTML rounds moderate values for readability, retaining their complete value in hover text; it does not alter the stored JSON result.
