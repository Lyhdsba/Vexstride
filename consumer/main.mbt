///|
/// A downstream module uses only the public facade, with its own model.
fn main raise {
  let study : @vexstride.Study = {
    factors: [
      {
        id: "price",
        name: "Unit price",
        unit: "cost/unit",
        lower: 2.0,
        upper: 5.0,
      },
      {
        id: "quantity",
        name: "Quantity",
        unit: "units",
        lower: 10.0,
        upper: 20.0,
      },
    ],
    levels: 6,
    trajectories: 24,
    seed: 97,
  }
  let plan = @vexstride.generate(study)
  let results = @vexstride.evaluate(plan, x => x[0] * x[1])
  let csv = @vexstride.results_csv(results)
  let loaded = @vexstride.parse_results(csv)
  let report = @vexstride.analyze(plan, loaded)
  assert_eq(@vexstride.missing(plan, loaded), [])
  for metric in report.metrics {
    assert_true(metric.mu > 0.0 && metric.mu_star > 0.0)
    assert_true(metric.interval_low <= metric.interval_high)
  }
  println(
    "Separate consumer: price/quantity model screened through the public API.",
  )
}
