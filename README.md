<img src="mark.svg" width="720" alt="VEXSTRIDE — Find what moves the model.">

# Know which inputs deserve your attention.

Vexstride is a MoonBit library and local CLI for **Morris parameter screening**. Define uncertain input ranges, generate a reproducible evaluation plan, run your model, and compare how strongly each parameter changes the output. Model results can arrive in separate CSV batches; missing, duplicate and foreign results are diagnosed before analysis.

面向数学建模与数值仿真：找出值得优先测准的参数，并检查参数影响是否稳定。核心计算由 MoonBit 完成，外部模型通过 CSV 接入。

## Try the complete workflow

Install [MoonBit](https://www.moonbitlang.com/download). The verified SDK is **moonc 0.10.20+65efd5b93 / moon 0.1.20261104**. No Python, Node.js or service account is needed for the library or CLI.

From the repository root:

```sh
moon update
moon run verify.mbtx --deny-warn
```

This runs three complete studies and writes reproducible artifacts under `.local-check/`:

- `heat.html`: steady wall heat-loss energy; compare area, transmittance, temperature difference and heating duration.
- `stock.html`: a fixed-policy, 60-day inventory model; compare demand, lead time, holding cost, unfilled-demand penalty and order fee.
- `spring.html`: analytic peak displacement after a step load; mass is correctly found to have zero influence on this particular output.

Open an HTML file directly in a browser. Reports are self-contained and load no remote assets. Study, plan, model-input CSV, result CSV and full-precision JSON report files are generated alongside them. These are deterministic worked examples, not measurements from deployed systems. Model equations and assumptions are in [the field notes](fieldnotes/README.md).

## Bring your own model

Create a UTF-8 `study.json`:

```json
{
  "factors": [
    {"id":"speed","name":"Flow speed","unit":"m/s","lower":1,"upper":4},
    {"id":"length","name":"Length","unit":"m","lower":2,"upper":6}
  ],
  "levels": 6,
  "trajectories": 32,
  "seed": 17
}
```

Generate the plan and physical model inputs:

```sh
moon run runner -- plan study.json > plan.json
moon run runner -- inputs plan.json > inputs.csv
```

Run your own simulator, spreadsheet or numerical program once per input row. Preserve the `plan_id` and `run_id` fields and return one finite scalar per row:

```csv
plan_id,run_id,value
vs1-<full-plan-fingerprint>,t0-s0,12.5
```

Use the actual fingerprint from your input CSV. The abbreviated row above illustrates the format; it is not a valid result file.

```sh
moon run runner -- missing plan.json part-a.csv part-b.csv
moon run runner -- merge plan.json part-a.csv part-b.csv > results.csv
moon run runner -- analyze plan.json results.csv > analysis.json
moon run runner -- report plan.json results.csv > report.html
```

Files are read only. Redirect stdout to save outputs. Keep outputs separate from inputs: shell redirection can truncate a file before the command reads it. CLI diagnostics do not echo file paths. Use a UTF-8 terminal; Windows PowerShell 5 redirection may need explicit UTF-8 handling.

The [exchange contract](handbook/exchange.md) defines encoding, limits, identities and exit codes. There is also a [tested MoonBit quick start](README.mbt.md). Registry publication is pending; local source use is currently verified.

## Interpret the result

| Indicator | Meaning |
| --- | --- |
| μ* | Mean absolute elementary effect: overall importance within the chosen parameter range. |
| μ | Mean signed elementary effect: positive and negative effects may cancel. |
| σ | Sample dispersion of elementary effects: suggests nonlinearity and/or interactions without separating them. |
| 95% interval | Empirical trajectory-bootstrap percentiles for μ*, not a coverage guarantee. |
| Top share | Fraction of resampled rankings won, splitting ties; not a probability of being the true best parameter. |

Effects are expressed per **normalized** input movement, so a parameter's chosen range matters. Input units are metadata, not the units of μ. Output units are those of the model's scalar output. The CLI and reports preserve factor order; compare μ* and the intervals to assess importance.

The first release supports deterministic models with independently varied continuous inputs. Bounds form a rectangular study domain. Correlated inputs, noise-aware screening, nonuniform distributions, infeasible-combination constraints, causal claims, optimization and Sobol variance decomposition are outside this release. Constant observed output is explicitly reported as unranked. See [numerical definitions](handbook/numerics.md).

## Verify the implementation

```sh
moon fmt --check
moon check --target wasm,wasm-gc,js --deny-warn
moon test --target wasm,wasm-gc,js --deny-warn
moon build --target wasm,wasm-gc,js --deny-warn
moon run verify.mbtx --deny-warn
```

The CLI targets Wasm with the MoonBit runtime; the computation library is tested on Wasm, Wasm-GC and JavaScript. CLI file access and verification scripts currently use experimental core async APIs, acknowledged in the package or reported by standalone script mode. This dependency does not change the statistical algorithm.

For an independent reference, install the test-only `SALib==1.5.2`, then run:

```sh
moon run oracle.mbtx --deny-warn -- python
```

Run `verify.mbtx` first. The oracle feeds the **same normalized X and Y** into SALib and compares μ, μ*, σ for all three studies. It deliberately excludes interval comparison because SALib uses a different bootstrap interval construction. Details and current evidence are in [validation](handbook/validation.md).

## Project map

`spec` owns domain types and budgets. `trails` creates plans and validates result identity. `effects` computes statistics. `exchange` reads and writes bounded CSV/JSON. `bulletin` presents reports. `runner` handles local files. `fieldnotes` contains reproducible application models. The root package is a small public facade.

[Related work and provenance](handbook/provenance.md) describe existing MoonBit projects and the algorithm references. [Development notes](DEVELOPMENT.md) record owner decisions, AI assistance and the remaining human review. Code is licensed under [Apache-2.0](LICENSE).
