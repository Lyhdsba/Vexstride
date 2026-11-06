///|
fn parse(text : String) -> Json raise @spec.Problem {
  if text.length() > 16777216 {
    raise @spec.Invalid("JSON exceeds 16 Mi UTF-16 units")
  }
  @json.parse(text, max_nesting_depth=16, reject_duplicate_keys=true) catch {
    _ =>
      raise @spec.Invalid("invalid JSON, duplicate keys or excessive nesting")
  }
}

///|
pub fn study_from_json(text : String) -> @spec.Study raise @spec.Problem {
  let study : @spec.Study = @json.from_json(parse(text)) catch {
    _ => raise @spec.Invalid("invalid study fields")
  }
  study.validate()
  study
}

///|
pub fn plan_from_json(text : String) -> @spec.Plan raise @spec.Problem {
  let plan : @spec.Plan = @json.from_json(parse(text)) catch {
    _ => raise @spec.Invalid("invalid plan fields")
  }
  @trails.validate(plan)
  plan
}

///|
pub fn plan_to_json(plan : @spec.Plan) -> String raise @spec.Problem {
  @trails.validate(plan)
  let text = @json.to_json(plan).stringify()
  if text.length() > 16777216 {
    raise @spec.Invalid(
      "serialized plan exceeds text budget; reduce trajectories",
    )
  }
  text
}
