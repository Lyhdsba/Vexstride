# Owner identity checks

Enable with `git config --local core.hooksPath .githooks`.

Both hooks invoke `identity.mbtx`. They check the current GitHub login and Git author/committer. The push check also verifies the destination owner and every existing commit identity. Authentication failure or an unexpected identity blocks the operation.

Hooks are local safeguards, not an access-control boundary. Do not bypass them. Formatting, numerical validation and tests remain required independently.
