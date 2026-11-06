///|
test "CSV quote and newline preservation" {
  let rows = [["a,b", "quote\"inside", "line\r\nbreak"], ["", "z", ""]]
  assert_eq(@exchange.read_csv(@exchange.write_csv(rows)), rows)
  assert_eq(@exchange.read_csv("a,b\n1,2\n"), [["a", "b"], ["1", "2"]])
  assert_eq(@exchange.read_csv("a,b\r\n1,2"), [["a", "b"], ["1", "2"]])
  assert_eq(@exchange.read_csv(""), [])
  try @exchange.read_csv("\"unclosed") catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("unclosed quote accepted")
  }
  try @exchange.read_csv("\"a\"garbage,b") catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("trailing garbage accepted")
  }
}

///|
test "JSON exchange and quoted result identifiers round trip" {
  let study : @spec.Study = {
    factors: [
      { id: "x", name: "Label <&>", unit: "m", lower: -1.0, upper: 3.0, },
    ],
    levels: 4,
    trajectories: 3,
    seed: 19,
  }
  let plan = @trails.generate(study)
  assert_eq(@exchange.plan_from_json(@exchange.plan_to_json(plan)), plan)
  let results = @trails.evaluate(plan, x => x[0] * x[0])
  assert_eq(@exchange.parse_results(@exchange.results_csv(results)), results)
  assert_eq(@exchange.read_csv(@exchange.inputs_csv(plan))[0], [
    "plan_id", "run_id", "x",
  ])
}

///|
test "malformed results and duplicate JSON keys reject" {
  try @exchange.parse_results("plan_id,run_id,value\np,r,NaN\n") catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("NaN accepted")
  }
  try @exchange.study_from_json("{\"levels\":4,\"levels\":6}") catch {
    @spec.Invalid(_) => ()
  } noraise {
    _ => fail("duplicate key accepted")
  }
}
