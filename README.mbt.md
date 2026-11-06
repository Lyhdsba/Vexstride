# Library quick start

This example calls the public facade from a separate package scope.

```mbt check
///|
test "screen a signed linear model" {
  let study : @vexstride.Study = {
    factors: [
      { id: "x", name: "First input", unit: "", lower: 0.0, upper: 1.0, },
      { id: "y", name: "Second input", unit: "", lower: 0.0, upper: 1.0, },
    ],
    levels: 4,
    trajectories: 16,
    seed: 17,
  }
  let plan = @vexstride.generate(study)
  let outputs = @vexstride.evaluate(plan, x => 2.0 * x[0] - 5.0 * x[1])
  let report = @vexstride.analyze(plan, outputs)
  assert_true(report.metrics[0].mu_star.is_close(2.0))
  assert_true(report.metrics[1].mu.is_close(-5.0))
  assert_eq(@vexstride.missing(plan, outputs), [])
}
```
