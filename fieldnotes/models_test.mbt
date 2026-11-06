///|
test "all worked models return finite complete observations" {
  for name in ["heat", "stock", "spring"] {
    let study = @fieldnotes.study(name)
    let plan = @trails.generate(study)
    let results = @fieldnotes.evaluate(name, plan)
    assert_eq(results.length(), study.evaluations())
    assert_eq(@trails.missing(plan, results), [])
    for result in results {
      assert_true(result.value.is_finite() && result.value >= 0.0)
    }
  }
}

///|
test "spring peak is independent of mass at the same other parameters" {
  let study = @fieldnotes.study("spring")
  let plan = @trails.generate(study)
  let results = @fieldnotes.evaluate("spring", plan)
  for t in 0..<study.trajectories {
    for step in 1..<=4 {
      let index = t * 5 + step
      if plan.runs[index - 1].normalized[0] != plan.runs[index].normalized[0] {
        assert_eq(results[index - 1].value, results[index].value)
      }
    }
  }
}
