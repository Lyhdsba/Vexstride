///|
fn config() -> @spec.Study {
  {
    factors: [
      { id: "x", name: "x", unit: "", lower: 0.0, upper: 1.0, },
      { id: "y", name: "y", unit: "", lower: 0.0, upper: 1.0, },
    ],
    levels: 4,
    trajectories: 16,
    seed: 7,
  }
}

///|
test "analytic signed linear effects and stable ranking" {
  let plan = @trails.generate(config())
  let observations = @trails.evaluate(plan, x => 2.0 * x[0] - 5.0 * x[1])
  let report = @effects.analyze(plan, observations)
  assert_true(report.metrics[0].mu.is_close(2.0))
  assert_true(report.metrics[1].mu.is_close(-5.0))
  assert_true(report.metrics[1].mu_star.is_close(5.0))
  assert_true(report.metrics[0].sigma < 1.0e-12)
  assert_true(report.metrics[1].interval_low.is_close(5.0))
  assert_eq(report.metrics[1].top_share, Some(1.0))
  assert_eq(report.metrics[0].top_share, Some(0.0))
  let reversed = observations.copy()
  reversed.rev_in_place()
  assert_eq(report.to_json(), @effects.analyze(plan, reversed).to_json())
}

///|
test "constant output is explicit and is not given a meaningful winner" {
  let plan = @trails.generate(config())
  let report = @effects.analyze(plan, @trails.evaluate(plan, _ => 42.0))
  assert_true(report.constant_output)
  for metric in report.metrics {
    assert_eq(metric.mu_star, 0.0)
    assert_eq(metric.sigma, 0.0)
    assert_eq(metric.top_share, None)
  }
}

///|
test "one missing result or a duplicate blocks analysis" {
  let plan = @trails.generate(config())
  let results = @trails.evaluate(plan, x => x[0] * x[1])
  let partial = results.copy()
  ignore(partial.pop())
  assert_eq(@trails.missing(plan, partial), [
    results[results.length() - 1].run_id,
  ])
  try @effects.analyze(plan, partial) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("incomplete results accepted")
  }
  try @trails.merge(plan, [results, [results[0]]]) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("duplicate accepted")
  }
}
