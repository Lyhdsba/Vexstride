///|
/// Escape all user-provided text before entering HTML or SVG contexts.
fn escape(text : String) -> String {
  text
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
}

///|
/// Compact display only; JSON and hover text retain the full numeric value.
fn number(value : Double) -> String {
  if value == 0.0 {
    return "0"
  }
  if value.abs() < 0.0001 || value.abs() >= 1000000000.0 {
    return value.to_string()
  }
  let scaled = (value.abs() * 10000.0).round().to_int64()
  let whole = scaled / 10000L
  let fraction = scaled % 10000L
  let sign = if value < 0.0 { "-" } else { "" }
  if fraction == 0L {
    return sign + whole.to_string()
  }
  let pad = if fraction < 10L {
    "000"
  } else if fraction < 100L {
    "00"
  } else if fraction < 1000L {
    "0"
  } else {
    ""
  }
  sign +
  whole.to_string() +
  "." +
  (pad + fraction.to_string()).trim_end(chars="0").to_owned()
}

///|
fn display(value : Double) -> String {
  "<abbr title=\"\{value}\">\{number(value)}</abbr>"
}

///|
/// Self-contained report; no network requests, embedded scripts or fonts.
pub fn html(plan : @spec.Plan, report : @effects.Report) -> String {
  let out = StringBuilder()
  let header =
    #|<!doctype html><html lang="en"><head><meta charset="utf-8">
    #|<meta name="viewport" content="width=device-width,initial-scale=1">
    #|<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'">
    #|<title>Vexstride — Model sensitivity</title><style>
    #|*{box-sizing:border-box}body{margin:0;background:#11171d;color:#eeeae2;font:16px/1.6 system-ui,sans-serif}
    #|main{max-width:1100px;margin:auto;padding:48px 32px}.brand{display:flex;align-items:center;gap:18px;letter-spacing:.22em;font-weight:800}
    #|.brand svg{width:58px;height:58px}.eyebrow{color:#ff7955;text-transform:uppercase;letter-spacing:.18em;font-size:12px;margin-top:54px}
    #|h1{font-size:clamp(36px,6vw,64px);line-height:1.08;max-width:850px;margin:16px 0 24px;letter-spacing:-.04em}
    #|p{color:#aeb9c4}.stats{display:flex;flex-wrap:wrap;gap:32px;border-top:1px solid #34414b;border-bottom:1px solid #34414b;padding:24px 0;margin:36px 0}
    #|.stats strong{display:block;font-size:28px;color:#fff}.stats span{font-size:12px;color:#aeb9c4}h2{font-size:24px;margin:40px 0 14px}
    #|.barrow{display:grid;grid-template-columns:minmax(120px,230px) 1fr;gap:16px;margin:20px 0}.track{background:#26313b;height:16px;margin-top:6px}.fill{background:#ff7955;height:100%;min-width:0}
    #|small{color:#9daab6;overflow-wrap:anywhere}table{width:100%;border-collapse:collapse;font-size:14px}th{text-align:left;color:#aeb9c4;font-weight:500}td,th{padding:12px;border-bottom:1px solid #34414b}td:first-child,th:first-child{padding-left:0}
    #|.scroll{overflow-x:auto}.note{border-left:3px solid #ff7955;background:#1c2630;padding:18px 24px;margin:24px 0;color:#dbe0e5}code{overflow-wrap:anywhere;color:#b4c0cb}footer{margin-top:44px;color:#98a5b1;font-size:12px}
    #|@media(max-width:600px){main{padding:28px 20px}.barrow{grid-template-columns:1fr;gap:4px}.stats{gap:20px}td,th{padding:9px}}
    #|</style></head><body><main><div class="brand">
    #|<svg viewBox="0 0 64 64" aria-hidden="true"><path d="M5 14L24 51L48 10M40 51L56 27L63 27" fill="none" stroke="#ff7955" stroke-width="5"/></svg>VEXSTRIDE</div>
    #|<div class="eyebrow">Morris screening / Study report</div><h1>Find what moves<br>the model.</h1>
    #|<p>Parameter influence within the ranges you chose. Deterministic model, independent continuous inputs.</p>
  out.write_string(header)
  out.write_string(
    "<div class=\"stats\"><div><strong>\{report.metrics.length()}</strong><span>PARAMETERS</span></div><div><strong>\{report.evaluations}</strong><span>MODEL EVALUATIONS</span></div><div><strong>\{report.trajectories}</strong><span>TRAJECTORIES</span></div><div><strong>\{report.resamples}</strong><span>BOOTSTRAP DRAWS</span></div></div>",
  )
  if report.constant_output {
    out.write_string(
      "<div class=\"note\">All observed outputs are equal. No parameter can be ranked from this study. Check the model, output precision and selected ranges.</div>",
    )
  }
  out.write_string(
    "<h2>Influence, not guesswork.</h2><p>Mean absolute elementary effect (μ*), in output units per normalized input step. Parameters retain their original order.</p>",
  )
  let mut maximum = 0.0
  for metric in report.metrics {
    if metric.mu_star > maximum {
      maximum = metric.mu_star
    }
  }
  for metric in report.metrics {
    let width = if maximum > 0.0 {
      metric.mu_star / maximum * 100.0
    } else {
      0.0
    }
    out.write_string(
      "<div class=\"barrow\"><div>\{escape(metric.name)}<br><small>\{escape(metric.id)}</small></div><div><div class=\"track\"><div class=\"fill\" style=\"width:\{width}%\"></div></div><small>μ* = \{display(metric.mu_star)}</small></div></div>",
    )
  }
  out.write_string(
    "<h2>Read the evidence.</h2><div class=\"scroll\"><table><thead><tr><th>Parameter</th><th>μ</th><th>μ*</th><th>σ</th><th>95% interval for μ*</th><th>Top share</th></tr></thead><tbody>",
  )
  for metric in report.metrics {
    let share = match metric.top_share {
      Some(x) => number(x * 100.0) + "%"
      None => "unranked"
    }
    out.write_string(
      "<tr><td>\{escape(metric.id)}</td><td>\{display(metric.mu)}</td><td>\{display(metric.mu_star)}</td><td>\{display(metric.sigma)}</td><td>[\{display(metric.interval_low)}, \{display(metric.interval_high)}]</td><td>\{share}</td></tr>",
    )
  }
  out.write_string(
    "</tbody></table></div><p>μ records signed influence. A large σ suggests nonlinearity and/or interactions; it does not separate them. Top share is the fraction of bootstrap wins, splitting ties; it is not a probability of being the true best parameter.</p><h2>Your assumptions travel with the result.</h2><div class=\"scroll\"><table><thead><tr><th>Parameter</th><th>Lower bound</th><th>Upper bound</th><th>Input unit</th></tr></thead><tbody>",
  )
  for factor in plan.study.factors {
    out.write_string(
      "<tr><td>\{escape(factor.id)}</td><td>\{factor.lower}</td><td>\{factor.upper}</td><td>\{escape(factor.unit)}</td></tr>",
    )
  }
  out.write_string(
    "</tbody></table></div><div class=\"note\">Intervals are empirical 2.5%–97.5% trajectory-bootstrap percentiles, not a guarantee of coverage. Rankings depend on model, ranges and design size. Morris screening is not causal inference or a Sobol variance decomposition.</div><footer>Plan <code>\{escape(report.plan_id)}</code><br>Design seed: \{plan.study.seed} · levels: \{report.levels} · bootstrap seed: \{report.bootstrap_seed}<br>Vexstride · Find what moves the model.</footer></main></body></html>",
  )
  out.to_string()
}
