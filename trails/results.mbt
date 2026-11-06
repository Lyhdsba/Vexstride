///|
/// Merge partial batches, rejecting repeated, unknown or foreign run IDs.
/// Returned observations always follow plan order, regardless of arrival order.
pub fn merge(
  plan : @spec.Plan,
  batches : Array[Array[@spec.Observation]],
) -> Array[@spec.Observation] raise @spec.Problem {
  validate(plan)
  let known : Map[String, Bool] = Map([])
  for run in plan.runs {
    known[run.id] = true
  }
  let received : Map[String, @spec.Observation] = Map([])
  for batch in batches {
    if batch.length() > plan.runs.length() {
      raise @spec.Invalid("result batch exceeds plan size")
    }
    for observation in batch {
      if observation.plan_id != plan.id {
        raise @spec.Invalid("result belongs to a different plan")
      }
      if !known.contains(observation.run_id) {
        raise @spec.Invalid("result references an unknown run")
      }
      if received.contains(observation.run_id) {
        raise @spec.Invalid("duplicate result: \{observation.run_id}")
      }
      if !observation.value.is_finite() {
        raise @spec.Invalid("result must be finite")
      }
      received[observation.run_id] = observation
    }
  }
  let ordered : Array[@spec.Observation] = []
  for run in plan.runs {
    if received.get(run.id) is Some(observation) {
      ordered.push(observation)
    }
  }
  ordered
}

///|
/// Missing rows are explicit; incomplete trajectories are never imputed.
pub fn missing(
  plan : @spec.Plan,
  observations : Array[@spec.Observation],
) -> Array[String] raise @spec.Problem {
  let ordered = merge(plan, [observations])
  let seen : Map[String, Bool] = Map([])
  for observation in ordered {
    seen[observation.run_id] = true
  }
  plan.runs.filter(run => !seen.contains(run.id)).map(run => run.id)
}
