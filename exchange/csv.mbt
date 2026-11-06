///|
/// A bounded CSV reader: quoted commas, doubled quotes, CRLF and quoted newlines.
pub fn read_csv(text : String) -> Array[Array[String]] raise @spec.Problem {
  if text.length() > 16777216 {
    raise @spec.Invalid("CSV exceeds 16 Mi UTF-16 units")
  }
  let rows : Array[Array[String]] = []
  let mut row : Array[String] = []
  let field = StringBuilder()
  let mut quoted = false
  let mut closed = false
  let mut pending_lf = false
  let mut started = false
  for c in text.iter() {
    if pending_lf {
      pending_lf = false
      if c == '\n' {
        continue
      }
    }
    if quoted {
      if c == '"' {
        quoted = false
        closed = true
      } else {
        field.write_char(c)
      }
      continue
    }
    if closed && c == '"' {
      field.write_char('"')
      quoted = true
      closed = false
      continue
    }
    if c == ',' || c == '\n' || c == '\r' {
      row.push(field.to_string())
      field.reset()
      closed = false
      started = false
      if row.length() > 66 {
        raise @spec.Invalid("CSV exceeds 66 columns")
      }
      if c != ',' {
        rows.push(row)
        row = []
        if rows.length() > 32769 {
          raise @spec.Invalid("CSV exceeds 32769 rows")
        }
        pending_lf = c == '\r'
      }
      continue
    }
    if closed {
      raise @spec.Invalid("unexpected character after closing CSV quote")
    }
    if c == '"' {
      if started {
        raise @spec.Invalid("quote in unquoted CSV field")
      }
      quoted = true
    } else {
      field.write_char(c)
    }
    started = true
  }
  if quoted {
    raise @spec.Invalid("unclosed CSV quote")
  }
  if started || closed || !row.is_empty() {
    row.push(field.to_string())
    if row.length() > 66 {
      raise @spec.Invalid("CSV exceeds 66 columns")
    }
    rows.push(row)
    if rows.length() > 32769 {
      raise @spec.Invalid("CSV exceeds 32769 rows")
    }
  }
  rows
}

///|
fn quote(value : String) -> String {
  if value.contains_char(',') ||
    value.contains_char('"') ||
    value.contains_char('\r') ||
    value.contains_char('\n') {
    "\"" + value.replace_all(old="\"", new="\"\"") + "\""
  } else {
    value
  }
}

///|
pub fn write_csv(rows : Array[Array[String]]) -> String raise @spec.Problem {
  if rows.length() > 32769 {
    raise @spec.Invalid("CSV exceeds 32769 rows")
  }
  let out = StringBuilder()
  for row in rows {
    if row.length() > 66 {
      raise @spec.Invalid("CSV exceeds 66 columns")
    }
    out.write_string(row.map(quote).join(","))
    out.write_string("\r\n")
  }
  let text = out.to_string()
  if text.length() > 16777216 {
    raise @spec.Invalid("CSV exceeds 16 Mi UTF-16 units")
  }
  text
}

///|
/// Parameter IDs, not human labels, form the model input header.
pub fn inputs_csv(plan : @spec.Plan) -> String raise @spec.Problem {
  @trails.validate(plan)
  let header = ["plan_id", "run_id"]
  for factor in plan.study.factors {
    header.push(factor.id)
  }
  let rows = [header]
  for run in plan.runs {
    let row = [plan.id, run.id]
    for value in run.values {
      row.push(value.to_string())
    }
    rows.push(row)
  }
  write_csv(rows)
}

///|
pub fn results_csv(
  observations : Array[@spec.Observation],
) -> String raise @spec.Problem {
  let rows = [["plan_id", "run_id", "value"]]
  for observation in observations {
    if !observation.value.is_finite() {
      raise @spec.Invalid("result must be finite")
    }
    rows.push([
      observation.plan_id,
      observation.run_id,
      observation.value.to_string(),
    ])
  }
  write_csv(rows)
}

///|
/// Parsing and semantic validation are separate: use trails.merge for identity checks.
pub fn parse_results(
  text : String,
) -> Array[@spec.Observation] raise @spec.Problem {
  let rows = read_csv(text)
  if rows.is_empty() || rows[0] != ["plan_id", "run_id", "value"] {
    raise @spec.Invalid("expected CSV header plan_id,run_id,value")
  }
  let outputs : Array[@spec.Observation] = []
  for i in 1..<rows.length() {
    let row = rows[i]
    if row.length() != 3 {
      raise @spec.Invalid("result row \{i + 1} must contain three fields")
    }
    let value = @string.parse_double(row[2]) catch {
      _ => raise @spec.Invalid("invalid numeric result at row \{i + 1}")
    }
    if !value.is_finite() {
      raise @spec.Invalid("non-finite result at row \{i + 1}")
    }
    outputs.push({ plan_id: row[0], run_id: row[1], value, })
  }
  outputs
}
