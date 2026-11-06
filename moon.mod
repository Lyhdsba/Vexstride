// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Lyhdsba/vexstride"

version = "0.1.0"

readme = "README.md"

repository = ""

license = "Apache-2.0"

keywords = [ "sensitivity", "morris", "numerical-models" ]

preferred_target = "wasm"

description = "Reproducible Morris screening and external-model result exchange"

import {
  "moonbitlang/x@0.5.5",
}
