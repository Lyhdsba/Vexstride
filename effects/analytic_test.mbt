///|
fn single() -> @spec.Plan raise @spec.Problem {
  @trails.generate({
    factors: [{ id: "x", name: "x", unit: "", lower: 0.0, upper: 1.0, }],
    levels: 4,
    trajectories: 2,
    seed: 1,
  })
}

///|
test "two-trajectory quadratic agrees with hand-derived moments" {
  let plan = single()
  assert_eq(plan.runs.map(run => run.normalized[0]), [
    0.0,
    2.0 / 3.0,
    1.0,
    1.0 / 3.0,
  ])
  let report = @effects.analyze(
    plan,
    @trails.evaluate(plan, x => x[0] * x[0]),
    resamples=500,
  )
  let metric = report.metrics[0]
  assert_true(metric.mu.is_close(1.0))
  assert_true(metric.mu_star.is_close(1.0))
  assert_true(metric.sigma.is_close(2.0.sqrt() / 3.0))
  assert_true(metric.interval_low.is_close(2.0 / 3.0))
  assert_true(metric.interval_high.is_close(4.0 / 3.0))
}

///|
test "signed cancellation must not erase absolute importance" {
  let plan = single()
  let report = @effects.analyze(
    plan,
    @trails.evaluate(plan, x => (x[0] - 0.5) * (x[0] - 0.5)),
  )
  assert_true(report.metrics[0].mu.abs() < 1.0e-14)
  assert_true(report.metrics[0].mu_star.is_close(1.0 / 3.0))
}

///|
test "budget, non-finite output and arithmetic overflow are explicit errors" {
  let plan = single()
  let observations = @trails.evaluate(plan, x => x[0])
  try @effects.analyze(plan, observations, resamples=19) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("bootstrap budget accepted")
  }
  try @effects.analyze(plan, observations, seed=0) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("bootstrap seed accepted")
  }
  try @trails.evaluate(plan, _ => 1.0 / 0.0) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("infinite output accepted")
  }
  let extreme = observations.mapi((i, result) => {
    ..result,
    value: if i % 2 == 0 {
      -1.0e308
    } else {
      1.0e308
    },
  })
  try @effects.analyze(plan, extreme) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("overflow accepted")
  }
}

///|
test "callback receives a copy and cannot corrupt a plan" {
  let plan = single()
  ignore(
    @trails.evaluate(plan, x => {
      x[0] = 99.0
      x[0]
    }),
  )
  @trails.validate(plan)
}
