///|
/// Generate r independent Morris trajectories, each with d+1 evaluations.
/// The normalized step is levels / (2 * (levels - 1)).
pub fn generate(study : @spec.Study) -> @spec.Plan raise @spec.Problem {
  study.validate()
  let factors = study.factors.copy()
  let copied : @spec.Study = { ..study, factors, }
  let rng = @draw.Generator::new(study.seed)
  let d = factors.length()
  let step = study.levels / 2
  let divisor = (study.levels - 1).to_double()
  let runs : Array[@spec.Run] = []
  for t in 0..<study.trajectories {
    let coordinates : Array[Int32] = []
    let signs : Array[Int32] = []
    let order = Array::makei(d, i => i)
    for _ in 0..<d {
      let base = rng.bounded(study.levels - step)
      let positive = rng.bounded(2) == 1
      coordinates.push(if positive { base } else { base + step })
      signs.push(if positive { 1 } else { -1 })
    }
    for i = d - 1; i > 0; i = i - 1 {
      let j = rng.bounded(i + 1)
      let old = order[i]
      order[i] = order[j]
      order[j] = old
    }
    for s in 0..<=d {
      let normalized = coordinates.map(x => x.to_double() / divisor)
      let values = Array::makei(d, i => {
        let f = factors[i]
        f.lower + normalized[i] * (f.upper - f.lower)
      })
      runs.push({
        id: "t\{t}-s\{s}",
        trajectory: t,
        step: s,
        normalized,
        values,
      })
      if s < d {
        let column = order[s]
        coordinates[column] += signs[column] * step
      }
    }
  }
  // Ordered arrays, not JSON object iteration, define the identity preimage.
  let columns : Array[Json] = factors.map(f => {
    Json::array([
      @json.to_json(f.id),
      @json.to_json(f.name),
      @json.to_json(f.unit),
      @json.to_json(f.lower),
      @json.to_json(f.upper),
    ])
  })
  let payload = Json::array([
    @json.to_json("vexstride/morris/1"),
    Json::array(columns),
    @json.to_json(study.levels),
    @json.to_json(study.trajectories),
    @json.to_json(study.seed),
  ]).stringify()
  let id = "vs1-" +
    @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(payload)))
  { schema: "vexstride/morris/1", id, study: copied, runs, }
}

///|
/// Reject forged/stale plans, changed coordinates and unsupported schemas.
pub fn validate(plan : @spec.Plan) -> Unit raise @spec.Problem {
  let expected = generate(plan.study)
  if plan != expected {
    raise @spec.Invalid(
      "plan does not match its versioned design; regenerate it",
    )
  }
}

///|
/// Run an in-process model; non-finite outputs are rejected immediately.
pub fn evaluate(
  plan : @spec.Plan,
  model : (Array[Double]) -> Double,
) -> Array[@spec.Observation] raise @spec.Problem {
  validate(plan)
  let outputs : Array[@spec.Observation] = []
  for run in plan.runs {
    let value = model(run.values.copy())
    if !value.is_finite() {
      raise @spec.Invalid("model returned a non-finite value")
    }
    outputs.push({ plan_id: plan.id, run_id: run.id, value, })
  }
  outputs
}
