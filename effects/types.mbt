///|
/// Effects are per unit normalized parameter movement, in output units.
#derive(Debug, ToJson)
pub(all) struct Metric {
  id : String
  name : String
  unit : String
  mu : Double
  mu_star : Double
  sigma : Double
  interval_low : Double
  interval_high : Double
  top_share : Double?
}

///|
#derive(Debug, ToJson)
pub(all) struct Report {
  schema : String
  plan_id : String
  trajectories : Int32
  evaluations : Int32
  levels : Int32
  resamples : Int32
  bootstrap_seed : Int32
  constant_output : Bool
  metrics : Array[Metric]
}

///|
pub extend Metric with @debug.Debug::{to_repr}

///|
pub extend Metric with @json.ToJson::{to_json}

///|
pub extend Report with @debug.Debug::{to_repr}

///|
pub extend Report with @json.ToJson::{to_json}
