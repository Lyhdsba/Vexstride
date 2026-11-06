# Separate source consumer

This module declares a versioned Vexstride dependency and uses only the public facade. Its workspace resolves that dependency to this checkout, allowing development before publication:

```sh
moon -C consumer check --deny-warn
moon -C consumer run . --deny-warn
```

It is a source-consumer check, not evidence of a registry release. After publication, verify the same consumer outside any enclosing workspace with a Mooncakes-resolved dependency.
