# Numerical contract

## Morris trajectories

For `d` factors, each trajectory has `d+1` rows and changes each factor once. There are `r` independent randomized trajectories, costing exactly `r(d+1)` model calls.

For even grid level count `p`, grid coordinates are integers `0..p-1` divided by `p-1`. The integer step is `p/2`, so normalized step magnitude is `Δ = p / (2(p-1))`. Each factor gets a uniformly selected feasible base coordinate and a random direction. Fisher-Yates shuffles the factor order. No optimized trajectory selection is claimed.

The random generator is Park-Miller with multiplier 48271 and modulus 2147483647. Seeds are in `1..2147483646`. Bounded choices use rejection sampling over generator outputs minus one. This generator is for reproducibility, not cryptography. A golden recurrence vector and a hand-derived single-factor design are tested on each supported computation target.

Physical coordinates are `lower + u(upper-lower)`. Parameter ranges, level count, trajectory count, seed and schema are encoded as ordered JSON arrays and fingerprinted using SHA-256. Plan validation regenerates the design and compares all fields and rows. A fingerprint is an accidental-mixup safeguard, not a signature or proof that external outputs were calculated honestly.

## Elementary effects

For the step that changes factor `j`, compute `EE_j = (y_after-y_before)/(u_after,j-u_before,j)`. This denominator includes the direction, so a consistently decreasing model has negative μ in either traversal direction.

For `r` elementary effects per factor:

- `μ = mean(EE)`.
- `μ* = mean(abs(EE))`.
- `σ = sqrt(sum((EE-μ)^2)/(r-1))`, using sample degrees of freedom.

Moment computation scales by the largest absolute effect before Welford accumulation. This reduces avoidable overflow. Non-finite effects, differences or summaries are rejected rather than silently reported. The library does not promise arbitrary-precision arithmetic.

`EE` measures change per unit **normalized** parameter movement and has the model output's units. Changing the range changes the question. σ cannot distinguish nonlinearity from interaction and is not itself an interaction index. Independent rectangular variation does not handle correlated or constrained input domains.

## Bootstrap

The analysis draws `r` complete trajectory indices with replacement for each replicate. Every factor uses the same indices, preserving pairing. μ* is recomputed per replicate. The reported 95% endpoints are empirical quantiles 0.025 and 0.975, with linear interpolation of sorted values (`h=(B-1)q`, often called type 7).

The default is 200 replicates with seed 7919. Library callers may select 20..2000 replicates within the work budget. Intervals are finite-sample bootstrap estimates; they do not prove convergence or guaranteed coverage. Default replicate count favors a quick first study; consequential conclusions need larger designs and stability checks.

Top share counts which factor has the greatest resampled μ*, splitting ties equally. Relative tolerance `1e-12` defines a tie, with zero absolute tolerance. Constant observed output yields no top shares. Being constant at sampled points does not prove a model is constant everywhere.

## Budgets and assumptions

- 1..64 factors; 2..512 trajectories; even 4..32 levels.
- At most 32768 model evaluations.
- At most 8 million factor-trajectory bootstrap draws (`d*r*B`).
- Finite, strictly increasing bounds with finite span and distinct representable physical grid levels. A range that is too narrow for the selected levels is rejected before planning. Model outputs must be deterministic finite scalars.
- Positive reproducibility seeds; no implicit entropy source.

These are protective input limits, not performance guarantees. Generation, validation and raw coordinate storage cost O(rd²); basic effect scanning also visits O(rd²) coordinates. Bootstrap costs O(Brd + dB log B), with O(rd+dB) additional analysis storage. JSON/CSV exchange adds storage proportional to serialized input. The library retains the complete plan to make external-model exchange inspectable.
