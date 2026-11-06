///|
test "Park-Miller published recurrence golden vector" {
  let rng = @draw.Generator::new(1)
  let expected = [48270, 182605793, 1291394885, 1914720636, 2078669040]
  for value in expected {
    assert_eq(rng.bounded(2147483646), value)
  }
}
