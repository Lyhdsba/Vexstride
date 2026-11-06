///|
#derive(Debug)
pub(all) suberror Problem {
  Invalid(String)
}

///|
/// A continuous parameter. Bounds define the scope of the sensitivity study.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct Factor {
  id : String
  name : String
  unit : String
  lower : Double
  upper : Double
}

///|
/// Version 1 uses independent, uniformly explored continuous inputs.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct Study {
  factors : Array[Factor]
  levels : Int32
  trajectories : Int32
  seed : Int32
}

///|
/// A row carries a stable trajectory/step identity and both coordinate systems.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct Run {
  id : String
  trajectory : Int32
  step : Int32
  normalized : Array[Double]
  values : Array[Double]
}

///|
/// Plans are validated against the generator before analysis or exchange.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct Plan {
  schema : String
  id : String
  study : Study
  runs : Array[Run]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct Observation {
  plan_id : String
  run_id : String
  value : Double
}

///|
/// Limits bound design generation and analysis work before allocation.
pub fn Study::validate(self : Study) -> Unit raise Problem {
  let d = self.factors.length()
  if d < 1 || d > 64 {
    raise Invalid("factor count must be 1..64")
  }
  if self.levels < 4 || self.levels > 32 || self.levels % 2 != 0 {
    raise Invalid("levels must be even and in 4..32")
  }
  if self.trajectories < 2 || self.trajectories > 512 {
    raise Invalid("trajectories must be 2..512")
  }
  if self.trajectories * (d + 1) > 32768 {
    raise Invalid("design exceeds 32768 model evaluations")
  }
  if self.seed < 1 || self.seed > 2147483646 {
    raise Invalid("seed must be 1..2147483646")
  }
  let seen : Map[String, Bool] = Map([])
  for factor in self.factors {
    if !valid_id(factor.id) ||
      seen.contains(factor.id) ||
      factor.id == "plan_id" ||
      factor.id == "run_id" {
      raise Invalid(
        "factor IDs must be distinct ASCII identifiers (1..64 characters)",
      )
    }
    seen[factor.id] = true
    if factor.name.length() < 1 ||
      factor.name.length() > 128 ||
      factor.unit.length() > 32 {
      raise Invalid("factor name or unit exceeds text limits")
    }
    if !factor.lower.is_finite() ||
      !factor.upper.is_finite() ||
      factor.upper <= factor.lower ||
      !(factor.upper - factor.lower).is_finite() {
      raise Invalid("factor bounds must define a positive finite span")
    }
  }
}

///|
fn valid_id(id : String) -> Bool {
  if id.length() < 1 || id.length() > 64 {
    return false
  }
  for c in id.iter() {
    if !(c >= 'a' && c <= 'z') &&
      !(c >= 'A' && c <= 'Z') &&
      !(c >= '0' && c <= '9') &&
      c != '_' &&
      c != '-' {
      return false
    }
  }
  true
}

///|
pub fn Study::evaluations(self : Study) -> Int32 raise Problem {
  self.validate()
  self.trajectories * (self.factors.length() + 1)
}
