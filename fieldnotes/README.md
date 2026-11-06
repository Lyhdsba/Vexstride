# Three models, one screening workflow

All inputs are synthetic, chosen to make model behavior and verification reproducible. None is a claimed customer deployment. Run `moon run verify.mbtx --deny-warn` from the project root to create inputs, outputs and reports.

## Heat: choose what to measure first

`E=U*A*ΔT*t/1000`, in kWh. Parameters are wall area 50..150 m², thermal transmittance 0.2..1.2 W/(m² K), temperature difference 10..30 K and duration 4..12 hours.

This is steady wall conduction only. It excludes ventilation, solar gains, varying weather, thermal mass and building certification. In the supplied 32-trajectory design, transmittance has the largest μ*. That conclusion applies to these ranges and this model, not every building.

Workflow: generate a study → export the 160 input rows → evaluate energy → merge results → compare the importance and intervals → choose which assumptions to investigate next. An external spreadsheet can evaluate the same formula and return the same identity columns.

## Stock: inspect fixed-policy cost assumptions

Simulate 60 days, starting with 150 units. At each day: receive due orders, serve demand up to available inventory, charge lost-sales penalty and end-of-day holding cost, then order 200 units if inventory plus pending stock is below 100. Lead time is floored to an integer day. Orders after day 59 have no terminal value or cancellation charge.

Ranges: demand 10..25 units/day, lead time 1..7 days, holding cost 0.05..0.2 per unit/day, unfilled-demand penalty 2..10 per unit and order fee 5..30. Output is total cost over the fixed horizon. Demand is deterministic, not a random sample. This screens a specified policy; it does not optimize replenishment.

Workflow: generate 192 rows → execute the fixed inventory model → return accumulated cost → inspect how influence changes with the selected ranges. Discontinuities from ordering decisions can produce large σ; this alone cannot identify a particular interaction.

## Spring: connect an external engineering model

For an underdamped linear spring-mass-damper under a force step, the first peak displacement is

`x_peak = F/k * (1 + exp(-πζ/sqrt(1-ζ²)))`.

Ranges: mass 1..5 kg, stiffness 50..200 N/m, damping ratio 0.05..0.3 and force 5..20 N. Output is displacement in metres. This analytic response omits nonlinear material behavior, saturation and measurement noise.

The peak value is independent of mass for this output definition; peak timing is not. This gives an application-level zero-influence check. The supplied design returns zero mass μ* and σ, and closely ranked load and stiffness influence. It does not justify removing mass from a model whose output is settling time or frequency.

Workflow: export 160 physical parameter rows → feed a matching analytic or external simulator → return peak displacement → check complete run identities → compare rankings and interval overlap. Use the built-in `evaluate spring` only for the documented analytic fixture.
