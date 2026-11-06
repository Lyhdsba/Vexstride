///|
/// Scale before centering to protect moments from unnecessary overflow.
fn moments(
  samples : Array[Double],
) -> (Double, Double, Double) raise @spec.Problem {
  let mut scale = 0.0
  for value in samples {
    if !value.is_finite() {
      raise @spec.Invalid("non-finite elementary effect")
    }
    if value.abs() > scale {
      scale = value.abs()
    }
  }
  if scale == 0.0 {
    return (0.0, 0.0, 0.0)
  }
  let mut mean = 0.0
  let mut absolute = 0.0
  let mut m2 = 0.0
  for i in 0..<samples.length() {
    let x = samples[i] / scale
    let count = (i + 1).to_double()
    let delta = x - mean
    mean += delta / count
    m2 += delta * (x - mean)
    absolute += (x.abs() - absolute) / count
  }
  let sigma = (m2 / (samples.length() - 1).to_double()).sqrt() * scale
  let result = (mean * scale, absolute * scale, sigma)
  if !result.0.is_finite() || !result.1.is_finite() || !result.2.is_finite() {
    raise @spec.Invalid("effect summary exceeds finite numeric range")
  }
  result
}

///|
/// Linear interpolation of the empirical quantile (R type 7).
fn percentile(sorted : Array[Double], probability : Double) -> Double {
  let position = (sorted.length() - 1).to_double() * probability
  let lo = position.to_int()
  let hi = if lo + 1 < sorted.length() { lo + 1 } else { lo }
  let fraction = position - lo.to_double()
  // Convex combination avoids overflow in hi - lo.
  sorted[lo] * (1.0 - fraction) + sorted[hi] * fraction
}

///|
/// Complete-trajectory bootstrap with percentile 95% intervals.
/// Resampling indices are shared across factors, preserving paired evidence.
pub fn analyze(
  plan : @spec.Plan,
  observations : Array[@spec.Observation],
  resamples~ : Int32 = 200,
  seed~ : Int32 = 7919,
) -> Report raise @spec.Problem {
  let ordered = @trails.merge(plan, [observations])
  let d = plan.study.factors.length()
  let r = plan.study.trajectories
  if ordered.length() != plan.runs.length() {
    raise @spec.Invalid(
      "results incomplete; inspect missing runs before analysis",
    )
  }
  if resamples < 20 || resamples > 2000 || seed < 1 || seed > 2147483646 {
    raise @spec.Invalid(
      "bootstrap requires 20..2000 resamples and a valid positive seed",
    )
  }
  if d * r * resamples > 8000000 {
    raise @spec.Invalid("bootstrap exceeds 8000000 factor-trajectory draws")
  }
  let effects : Array[Array[Double]] = Array::makei(d, _ => [])
  let mut constant_output = true
  let first = ordered[0].value
  for result in ordered {
    if result.value != first {
      constant_output = false
    }
  }
  for t in 0..<r {
    for s in 1..<=d {
      let before = t * (d + 1) + s - 1
      let after = before + 1
      let a = plan.runs[before]
      let b = plan.runs[after]
      for j in 0..<d {
        let delta = b.normalized[j] - a.normalized[j]
        if delta != 0.0 {
          let value = (ordered[after].value - ordered[before].value) / delta
          if !value.is_finite() {
            raise @spec.Invalid(
              "elementary effect exceeds finite numeric range",
            )
          }
          effects[j].push(value)
        }
      }
    }
  }
  let summaries = effects.map(samples => moments(samples))
  let draws : Array[Array[Double]] = Array::makei(d, _ => [])
  let top : Array[Double] = Array::make(d, 0.0)
  let rng = @draw.Generator::new(seed)
  for _ in 0..<resamples {
    let indices = Array::makei(r, _ => rng.bounded(r))
    let means : Array[Double] = []
    for j in 0..<d {
      let sampled = indices.map(i => effects[j][i])
      let (_, mean_abs, _) = moments(sampled)
      draws[j].push(mean_abs)
      means.push(mean_abs)
    }
    let mut best = 0.0
    for mean in means {
      if mean > best {
        best = mean
      }
    }
    let mut ties = 0
    for mean in means {
      if mean.is_close(best, relative_tolerance=1.0e-12, absolute_tolerance=0.0) {
        ties += 1
      }
    }
    for j in 0..<d {
      if means[j].is_close(
          best,
          relative_tolerance=1.0e-12,
          absolute_tolerance=0.0,
        ) {
        top[j] += 1.0 / ties.to_double()
      }
    }
  }
  let metrics = Array::makei(d, j => {
    draws[j].sort()
    let f = plan.study.factors[j]
    let (mu, mu_star, sigma) = summaries[j]
    Metric::{
      id: f.id,
      name: f.name,
      unit: f.unit,
      mu,
      mu_star,
      sigma,
      interval_low: percentile(draws[j], 0.025),
      interval_high: percentile(draws[j], 0.975),
      top_share: if constant_output {
        None
      } else {
        Some(top[j] / resamples.to_double())
      },
    }
  })
  {
    schema: "vexstride/effects/1",
    plan_id: plan.id,
    trajectories: r,
    evaluations: ordered.length(),
    levels: plan.study.levels,
    resamples,
    bootstrap_seed: seed,
    constant_output,
    metrics,
  }
}
