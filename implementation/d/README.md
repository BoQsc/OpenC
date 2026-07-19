# OpenC CC1 D syntax frontend

This directory contains the D implementation used for the Core Candidate 1 M1 and M2 gates.

## Modules

```text
source/main.d
source/cc1/diagnostic.d
source/cc1/token.d
source/cc1/syntax.d
source/cc1/lexer.d
source/cc1/parser.d
```

The implementation has no third-party D package dependencies.

## Compile with GDC

```text
gdc-13 -O0 -g -Wall -Iimplementation/d/source \
  implementation/d/source/main.d \
  implementation/d/source/cc1/diagnostic.d \
  implementation/d/source/cc1/token.d \
  implementation/d/source/cc1/syntax.d \
  implementation/d/source/cc1/lexer.d \
  implementation/d/source/cc1/parser.d \
  -o build/openc-cc1-parser
```

## Execute the fixed M1 regression

```text
build/openc-cc1-parser --suite \
  implementation/gates/cc1_m1_fixtures.json \
  build/cc1-m1-report.json
```

## Materialize the committed M2 fixture bundle

```text
python3 implementation/gates/materialize_cc1_m2_gate.py \
  implementation/gates/cc1_m2_core_syntax_fixtures.json.zlib.b64 \
  build/gates/cc1_m2_core_syntax_fixtures.json
```

## Execute complete Core source syntax

```text
build/openc-cc1-parser --suite \
  build/gates/cc1_m2_core_syntax_fixtures.json \
  build/cc1-m2-report.json
```

The accepted results include a structural syntax tree. Semantically invalid but syntactically valid fixtures are expected to parse successfully at this stage.
