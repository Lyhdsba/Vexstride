# A small independent check of Morris summaries

For `f(u)=(u-1/2)^2`, use trajectories `0 → 2/3` and `1 → 1/3`.
The signed elementary effects are `-1/3` and `+1/3`. Their mean cancels,
but their mean absolute value does not. The sample standard deviation uses
one degree of freedom for these two observations.

```mbt check
///|
test "signed cancellation and sample dispersion" {
  let first = -1.0 / 3.0
  let second = 1.0 / 3.0
  let mu = (first + second) / 2.0
  let mu_star = (first.abs() + second.abs()) / 2.0
  let sigma = ((first - mu) * (first - mu) + (second - mu) * (second - mu)).sqrt()
  assert_eq(mu, 0.0)
  assert_true(mu_star.is_close(1.0 / 3.0))
  assert_true(sigma.is_close(2.0.sqrt() / 3.0))
}
```
