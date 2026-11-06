///|
async fn read(path : String) -> String {
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  if file.kind() != Regular {
    raise @spec.Invalid("input must be a regular file")
  }
  let size = file.size()
  if size > 16777216L {
    raise @spec.Invalid("input file exceeds 16 MiB")
  }
  let bytes = file.read_exactly(size.to_int())
  @utf8.decode(bytes)
}

///|
async fn stdout(text : String) -> Unit {
  @stdio.stdout.write(@utf8.encode(text))
}

///|
fn usage() -> String {
  let text =
    #|Vexstride — Find what moves the model.
    #|
    #|moon run runner -- <command> [arguments]
    #|  example <heat|stock|spring>          Print an example study JSON
    #|  plan <study.json>                   Print a validated design JSON
    #|  inputs <plan.json>                  Print model inputs as CSV
    #|  evaluate <heat|stock|spring> <plan>  Run a worked example, print results CSV
    #|  merge <plan> <results.csv>...        Merge partial results as CSV
    #|  missing <plan> <results.csv>...      List missing run IDs as JSON
    #|  analyze <plan> <results.csv>         Print the Morris report as JSON
    #|  report <plan> <results.csv>          Print a self-contained HTML report
    #|
    #|Redirect stdout to save output. Files are read only; diagnostics never echo paths.
    #|Exit codes: 0 success, 2 invalid study/results, 3 missing results, 64 usage, 74 input/output error.
    #|
  text
}

///|
async fn execute(args : Array[String]) -> Int32 {
  if args.is_empty() || args == ["--help"] || args == ["help"] {
    stdout(usage())
    return 0
  }
  match args {
    ["example", name] =>
      stdout(@json.to_json(@fieldnotes.study(name)).stringify(indent=2) + "\n")
    ["plan", path] => {
      let plan = @trails.generate(@exchange.study_from_json(read(path)))
      stdout(@exchange.plan_to_json(plan) + "\n")
    }
    ["inputs", path] =>
      stdout(@exchange.inputs_csv(@exchange.plan_from_json(read(path))))
    ["evaluate", name, path] => {
      let plan = @exchange.plan_from_json(read(path))
      stdout(@exchange.results_csv(@fieldnotes.evaluate(name, plan)))
    }
    ["merge" | "missing" as command, path, .. files] if files.length() > 0 => {
      if files.length() > 128 {
        raise @spec.Invalid("at most 128 partial result files")
      }
      let plan = @exchange.plan_from_json(read(path))
      let batches = []
      for file in files {
        batches.push(@exchange.parse_results(read(file)))
      }
      let merged = @trails.merge(plan, batches)
      if command == "merge" {
        stdout(@exchange.results_csv(merged))
      } else {
        let missing = @trails.missing(plan, merged)
        stdout(@json.to_json(missing).stringify() + "\n")
        return if missing.is_empty() { 0 } else { 3 }
      }
    }
    ["analyze" | "report" as command, path, results] => {
      let plan = @exchange.plan_from_json(read(path))
      let observations = @exchange.parse_results(read(results))
      let missing = @trails.missing(plan, observations)
      if !missing.is_empty() {
        @stdio.stderr.write(
          @utf8.encode(
            "Results incomplete; use missing to list absent run IDs.\n",
          ),
        )
        return 3
      }
      let report = @effects.analyze(plan, observations)
      if command == "analyze" {
        stdout(report.to_json().stringify(indent=2) + "\n")
      } else {
        stdout(@bulletin.html(plan, report))
      }
    }
    _ => {
      @stdio.stderr.write(@utf8.encode(usage()))
      return 64
    }
  }
  0
}

///|
async fn main {
  let raw = @env.args()
  let args = raw[1:].to_owned()
  let code = execute(args) catch {
    @spec.Invalid(message) => {
      @stdio.stderr.write(@utf8.encode("Vexstride: " + message + "\n"))
      2
    }
    _ => {
      @stdio.stderr.write(
        @utf8.encode(
          "Vexstride: cannot read or write data; check access, encoding and file type.\n",
        ),
      )
      74
    }
  }
  if code != 0 {
    @sys.exit(code)
  }
}
