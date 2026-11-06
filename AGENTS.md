# Vexstride development

Keep the numerical core deterministic and independent of files, network access and operating-system state. Public domain types belong to `spec`; algorithm, exchange and presentation packages have separate responsibilities.

For each behavior change, add a regression based on an analytic result, an independently calculated fixture, or a real failure condition. Run `moon check --deny-warn`, the relevant tests, and `moon fmt`. Before delivery, run `moon info`, review generated interfaces, run the full tests and execute `verify.mbtx`. Automation belongs in `.mbtx` files.

Keep worked examples honest: synthetic inputs must be labeled; no deployment, performance or human-review claims without evidence. Record algorithm and code provenance. Do not commit credentials, machine-specific absolute paths, caches or generated local working data.

## Repository identity

The owner is **Lyhdsba**. Every commit and push for this repository must use Lyhdsba. Before committing or pushing, verify the authenticated GitHub account and both Git identities. Do not add another author, committer or coauthor. Configure identity locally, never by changing global settings for other repositories.

Run `moon run identity.mbtx -- commit` before commits; use `moon run identity.mbtx -- push <remote-url>` before pushes. Configure `.githooks` as the local hooks path. Never bypass a failed identity check. Remote creation, pushes and publishing require the owner's explicit authorization for that release.
