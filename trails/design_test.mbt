///|
fn study() -> @spec.Study {
  {
    factors: [
      { id: "x", name: "First", unit: "m", lower: 10.0, upper: 16.0, },
      { id: "y", name: "Second", unit: "s", lower: -2.0, upper: 2.0, },
    ],
    levels: 4,
    trajectories: 8,
    seed: 17,
  }
}

///|
test "each trajectory moves each parameter exactly once within bounds" {
  let config = study()
  let plan = @trails.generate(config)
  assert_eq(plan.runs.length(), 24)
  assert_eq(plan, @trails.generate(config))
  @trails.validate(plan)
  for t in 0..<8 {
    let changed : Array[Int32] = []
    for s in 1..<=2 {
      let a = plan.runs[t * 3 + s - 1]
      let b = plan.runs[t * 3 + s]
      let columns : Array[Int32] = []
      for j in 0..<2 {
        assert_true(b.normalized[j] >= 0.0 && b.normalized[j] <= 1.0)
        if a.normalized[j] != b.normalized[j] {
          columns.push(j)
          assert_true(
            (a.normalized[j] - b.normalized[j]).abs().is_close(2.0 / 3.0),
          )
        }
        let f = config.factors[j]
        assert_true(
          b.values[j].is_close(f.lower + b.normalized[j] * (f.upper - f.lower)),
        )
      }
      assert_eq(columns.length(), 1)
      changed.push(columns[0])
    }
    assert_true(changed[0] != changed[1])
  }
}

///|
test "budget and bounds reject invalid inputs" {
  let config = study()
  try @trails.generate({ ..config, levels: 3, }) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("odd levels accepted")
  }
  try @trails.generate({ ..config, seed: 0, }) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("zero seed accepted")
  }
  let invalid : @spec.Factor = { ..config.factors[0], upper: 10.0, }
  try @trails.generate({ ..config, factors: [invalid], }) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("zero width accepted")
  }
}

///|
test "changed rows and mismatched identities cannot pass validation" {
  let plan = @trails.generate(study())
  try @trails.validate({ ..plan, id: "other", }) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("identity accepted")
  }
  let changed = plan.runs.copy()
  changed[0] = { ..changed[0], values: [1.0, 2.0], }
  try @trails.validate({ ..plan, runs: changed, }) catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("changed rows accepted")
  }
}
