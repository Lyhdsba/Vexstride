///|
/// Worked models are deterministic illustrations, not field measurements.
pub fn study(name : String) -> @spec.Study raise @spec.Problem {
  let factors : Array[@spec.Factor] = match name {
    "heat" =>
      [
        {
          id: "area",
          name: "Wall area",
          unit: "m2",
          lower: 50.0,
          upper: 150.0,
        },
        {
          id: "u_value",
          name: "Thermal transmittance",
          unit: "W/(m2 K)",
          lower: 0.2,
          upper: 1.2,
        },
        {
          id: "temperature",
          name: "Temperature difference",
          unit: "K",
          lower: 10.0,
          upper: 30.0,
        },
        {
          id: "hours",
          name: "Heating duration",
          unit: "h",
          lower: 4.0,
          upper: 12.0,
        },
      ]
    "stock" =>
      [
        {
          id: "demand",
          name: "Daily demand",
          unit: "units/day",
          lower: 10.0,
          upper: 25.0,
        },
        { id: "lead", name: "Lead time", unit: "days", lower: 1.0, upper: 7.0, },
        {
          id: "holding",
          name: "Daily holding cost",
          unit: "cost/unit/day",
          lower: 0.05,
          upper: 0.2,
        },
        {
          id: "shortage",
          name: "Unfilled-demand penalty",
          unit: "cost/unit",
          lower: 2.0,
          upper: 10.0,
        },
        {
          id: "ordering",
          name: "Order fee",
          unit: "cost/order",
          lower: 5.0,
          upper: 30.0,
        },
      ]
    "spring" =>
      [
        { id: "mass", name: "Mass", unit: "kg", lower: 1.0, upper: 5.0, },
        {
          id: "stiffness",
          name: "Spring stiffness",
          unit: "N/m",
          lower: 50.0,
          upper: 200.0,
        },
        {
          id: "damping",
          name: "Damping ratio",
          unit: "1",
          lower: 0.05,
          upper: 0.3,
        },
        { id: "force", name: "Step load", unit: "N", lower: 5.0, upper: 20.0, },
      ]
    _ => raise @spec.Invalid("unknown example; choose heat, stock or spring")
  }
  { factors, levels: 6, trajectories: 32, seed: 20261107, }
}

///|
/// Steady wall conduction energy, kWh. No solar gains, ventilation or thermal mass.
fn heat(x : Array[Double]) -> Double {
  x[0] * x[1] * x[2] * x[3] / 1000.0
}

///|
/// 60-day lost-sales inventory model. Lead days are floored.
/// Start with 150 units; reorder 200 when stock + pending stock < 100.
fn stock(x : Array[Double]) -> Double {
  let arrivals = Array::make(68, 0.0)
  let mut inventory = 150.0
  let mut pending = 0.0
  let mut cost = 0.0
  let lead = x[1].to_int()
  for day in 0..<60 {
    inventory += arrivals[day]
    pending -= arrivals[day]
    let served = if inventory < x[0] { inventory } else { x[0] }
    inventory -= served
    cost += (x[0] - served) * x[3] + inventory * x[2]
    if inventory + pending < 100.0 {
      arrivals[day + lead] += 200.0
      pending += 200.0
      cost += x[4]
    }
  }
  cost
}

///|
/// Analytic first peak after a step force in an underdamped linear oscillator.
/// Mass cancels from peak displacement; it changes timing, not the peak value.
fn spring(x : Array[Double]) -> Double {
  let zeta = x[2]
  let overshoot = @math.exp(
    -3.141592653589793 * zeta / (1.0 - zeta * zeta).sqrt(),
  )
  x[3] / x[1] * (1.0 + overshoot)
}

///|
/// Only use a named fixture model with its corresponding input columns.
pub fn evaluate(
  name : String,
  plan : @spec.Plan,
) -> Array[@spec.Observation] raise @spec.Problem {
  let expected = study(name)
  if plan.study.factors != expected.factors {
    raise @spec.Invalid("example model parameters do not match the plan")
  }
  match name {
    "heat" => @trails.evaluate(plan, heat)
    "stock" => @trails.evaluate(plan, stock)
    "spring" => @trails.evaluate(plan, spring)
    _ => raise @spec.Invalid("unknown example")
  }
}
