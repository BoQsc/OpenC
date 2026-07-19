# OpenC Core Candidate 1 D parser

This directory contains the first implementation milestone for OpenC Core Candidate 1.

The milestone is intentionally narrow:

- tokenize and parse the 22 fixtures listed by `CC1-M1-parser`;
- accept every positive fixture;
- reject every negative syntax fixture with its exact expected primary rule ID;
- report crashes, unsupported behavior, and infrastructure failures as failures;
- compile the implementation with a recorded D compiler.

It is not a semantic checker, code generator, or OpenC conformance claim.

## Modules

```text
source/main.d             gate adapter and machine-readable report
source/cc1/token.d        token representation
source/cc1/diagnostic.d   structured frontend diagnostics
source/cc1/lexer.d        Core Candidate lexer
source/cc1/parser.d       recursive-descent parser
```

## Build

With GNU D Compiler:

```text
gdc -Iimplementation/d/source \
  implementation/d/source/main.d \
  implementation/d/source/cc1/diagnostic.d \
  implementation/d/source/cc1/token.d \
  implementation/d/source/cc1/lexer.d \
  implementation/d/source/cc1/parser.d \
  -o build/openc-cc1-parser
```

## Execute the gate

```text
build/openc-cc1-parser \
  implementation/gates/cc1_m1_fixtures.json \
  build/cc1-m1-report.json
```

The process exits successfully only when all 22 fixtures produce their exact expected outcomes.
