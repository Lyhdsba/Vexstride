# Development decisions and review

## Owner direction

The project brief selects an applied mathematical-computing project, accepts parameter sensitivity analysis as the direction, requests a distinctive English identity and sets a local-first release boundary. The owner requires reproducible verification, transparent AI assistance and Lyhdsba as the sole commit and push identity. Remote creation, publishing and pushes remain subject to the owner's release decision.

These decisions guide the implementation. They do not imply that the owner has personally reviewed each source line or validated the statistical method.

## AI assistance

The AI assistant drafted the initial implementation, tests, example models, report layout and documentation under the owner's project direction. The assistant also helped with the pre-submission audit and its local fixes. Automated compiler, runtime and reference checks are recorded separately from human review. The Git author and committer identity identifies the repository account used to record the work. It does not establish who wrote or personally reviewed each change.

The project does not contain fabricated human sign-offs, backdated development records or claims of deployment. Public documentation uses repository-relative paths. Local working files, dependency caches and temporary verification data are ignored.

## Review before release

- [ ] The owner can explain normalized Morris steps, signed effects and the meaning of μ*, μ and σ.
- [ ] The owner can explain why σ does not isolate interactions and why these results are not causal claims.
- [ ] The owner has run a custom model through CSV exchange and reviewed the missing/duplicate-result behavior.
- [ ] The owner has reviewed the three example assumptions, licenses, generated interfaces and validation evidence.
- [ ] The owner has written the required one-page project application personally, using the implemented scope and at least three concrete scenarios.
- [x] The owner authorized remote repository creation and the scheduled pushes.
- [x] Remote CI passed on the published GitHub snapshot [6cb2a1d](https://github.com/Lyhdsba/Vexstride/actions/runs/42386801910).
- [ ] The package has been published to Mooncakes and installed into an independent consumer.

These items remain unchecked until their actions actually occur. Local tests and AI-assisted review do not substitute for them.
