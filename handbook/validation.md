# Validation record

Local verification on 2026-11-07 used moonc `0.10.20+65efd5b93`, Moon `0.1.20261104`, the matching core library and `moonbitlang/x@0.5.5`. These results describe this tested SDK, not every past or future compiler.

## Observed checks

| Check | Observed outcome |
| --- | --- |
| Strict check, build and test on Wasm, Wasm-GC and JavaScript | Passed; 21 tests on each computation target. The Wasm CLI is skipped on unsupported targets. |
| Deterministic recurrence and Morris moves | Golden Park-Miller vector, single-factor coordinates, one-change-per-step and each-factor-once checks passed. |
| Analytic summaries | Signed linear effects, quadratic mean/dispersion, cancellation, constant output and overflow checks passed. |
| CSV and JSON | Quoting, line endings, round trips, duplicate keys, identity and non-finite-result checks passed. |
| Three real-file workflows | Heat 160, stock 192, spring 160 evaluations; complete input/output exchange, result merging and report generation passed. |
| CLI failure cases | Exit 2 for invalid/duplicate/oversized data; 3 for missing results; 64 for usage; 74 for inaccessible files and malformed UTF-8. |
| UTF-8 BOM | Initial test found rejection; explicit BOM stripping fixed it and the resulting plan matches the BOM-free input. |
| Separate source consumer | Public facade used successfully from a separate module; price/quantity model result exchange and screening passed. |
| Standalone mathematical note | Independently checked and tested outside the module with MoonBit single-file mode, then included as executable documentation. |
| HTML | Desktop browser inspection of the generated heat report; readable charts, table, assumptions and full-precision hover values. Metadata escaping is tested. |

## Independent numerical reference

`SALib==1.5.2` ran outside the production dependency graph. `oracle.mbtx` exports the **same** normalized design matrices and output vectors as the MoonBit runs, then invokes SALib's Morris analysis CLI.

All 13 factors across the three studies agreed for μ, μ* and sample σ, using absolute and relative comparison tolerances `1e-6` to account for the reference CLI's printed precision. This is a differential test of those summaries for these designs, not a proof for every model.

Bootstrap intervals were not compared to SALib: Vexstride uses empirical percentile endpoints, while SALib's displayed μ* interval estimate uses a different construction. A two-trajectory quadratic fixture checks the percentile endpoints against a hand-derived discrete resampling distribution. The zero-effect mass parameter in the spring fixture supplies an independent physical-model invariant.

## Reproduction

```sh
moon fmt --check
moon check --target wasm,wasm-gc,js --deny-warn
moon build --target wasm,wasm-gc,js --deny-warn
moon test --target wasm,wasm-gc,js --deny-warn
moon run verify.mbtx --deny-warn
moon run oracle.mbtx --deny-warn -- python
moon -C consumer run . --deny-warn
```

The final command for the oracle requires Python with SALib 1.5.2 installed. Scripts report that core async APIs are experimental in this toolchain. No warning suppression is used for numerical code.

## Not yet established

Remote GitHub Actions execution, Mooncakes publication and a registry-installed consumer remain pending release authorization. A successful source consumer does not prove registry availability. Owner line-by-line review, a personally written contest application and a real user's external-model trial remain open. No measured throughput, optimality, statistical coverage guarantee or production deployment is claimed.
