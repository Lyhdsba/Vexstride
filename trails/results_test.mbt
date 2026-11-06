///|
test "foreign, unknown and non-finite results are rejected" {
  let plan = @trails.generate(study())
  let good = @trails.evaluate(plan, x => x[0] + x[1])
  let bad = [
    { ..good[0], plan_id: "foreign", },
    { ..good[0], run_id: "t999-s0", },
    { ..good[0], value: 0.0 / 0.0, },
  ]
  for observation in bad {
    try @trails.merge(plan, [[observation]]) catch {
      @spec.Invalid(_) => ()
    } noraise {
      _ => fail("bad result accepted")
    }
  }
  let one = good[0:12].to_owned()
  let two = good[12:].to_owned()
  one.rev_in_place()
  assert_eq(@trails.merge(plan, [two, one]), good)
}

///|
test "seeded plans change identity when scope or design changes" {
  let original = study()
  let plan = @trails.generate(original)
  assert_true(plan.id != @trails.generate({ ..original, seed: 18, }).id)
  let changed = original.factors.copy()
  changed[0] = { ..changed[0], upper: 20.0, }
  assert_true(plan.id != @trails.generate({ ..original, factors: changed, }).id)
  try
    @trails.generate({ ..original, factors: [{ ..changed[0], id: "run_id", }], })
  catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("reserved CSV column accepted")
  }
}
