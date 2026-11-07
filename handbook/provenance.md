# References and independent contribution

Vexstride implements published Morris screening ideas in MoonBit. It does not claim to invent Morris analysis, bootstrap resampling, SHA-256 or deterministic pseudo-random generation.

## Algorithm references

- Morris, M. D. (1991), *Factorial Sampling Plans for Preliminary Computational Experiments*, Technometrics 33(2), 161–174. [DOI](https://doi.org/10.1080/00401706.1991.10484804).
- [SALib Morris documentation](https://salib.readthedocs.io/en/stable/api/SALib.analyze.html#module-SALib.analyze.morris): definitions, assumptions and reference behavior. [SALib 1.5.2](https://pypi.org/project/SALib/1.5.2/) is MIT-licensed and invoked as an independent test tool. Its interval construction differs from this project's empirical percentile intervals.
- Park-Miller recurrence with multiplier 48271: the implementation states the exact integer formula and rejection mapping, and tests a fixed output vector.
- [moonbitlang/x](https://github.com/moonbitlang/x), version 0.5.5, Apache-2.0: SHA-256 and process exit support. MoonBit core supplies types, JSON, UTF-8, math and async file/process APIs.

Production algorithm code was authored for this project with AI assistance. SALib is not embedded or invoked by the library or CLI. If code is later transplanted from another project, its source revision, license and copied scope must be recorded here before release. The worked model formulas and generated data are described in `fieldnotes/README.md`; no external private or commercial data is redistributed.

## MoonBit ecosystem comparison

The November topic review used Mooncakes keyword searches and the linked public source interfaces. This is a scoped review, not proof that no similar project exists.

| Existing project | Shared area | Vexstride contribution |
| --- | --- | --- |
| [MoonDOE](https://github.com/shangwuxi/moondoe) | Experimental plans and numerical modeling | Morris elementary-effect screening with complete external evaluation identity and trajectory-bootstrap analysis, rather than factorial/response-surface/optimal design. |
| [moonbit-montecarlo](https://github.com/jdjjttr/moonbit-montecarlo) | Reproducible sampling | A model-independent screening and results-recovery workflow; random generators and Sobol sequences are not claimed as new ecosystem capabilities. |
| [moonbit-biogeochem](https://github.com/lqlnvj/moonbit-biogeochem) | Existing local and Sobol sensitivity analyses | A generic Morris library accepting arbitrary scalar model callbacks or external CSV results, without marine-model domain types. |

Vexstride is a new implementation and application boundary. It is not a continuation of the owner's earlier task orchestration, chemical report or Boolean circuit projects. It does not borrow the implementation or data of the clock-calibration, MQTT trace-checking or timetable repositories reviewed during topic selection.
