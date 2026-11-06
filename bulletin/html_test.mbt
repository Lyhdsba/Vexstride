///|
test "HTML escapes metadata and has no remote dependencies" {
  let plan = @trails.generate({
    factors: [
      {
        id: "x",
        name: "<script>alert('x')</script>",
        unit: "<m>&",
        lower: 0.0,
        upper: 1.0,
      },
    ],
    levels: 4,
    trajectories: 2,
    seed: 1,
  })
  let results = @trails.evaluate(plan, x => x[0])
  let html = @bulletin.html(plan, @effects.analyze(plan, results))
  assert_true(html.contains("&lt;script&gt;"))
  assert_true(!html.contains("<script>"))
  assert_true(!html.contains("https://"))
  assert_true(html.contains("Content-Security-Policy"))
}
