# CC1-M1-parser evidence contract

`CC1-M1-parser` is the first implementation milestone after OpenC Core Candidate 1.

A successful claim requires all of the following:

1. A D compiler is identified by exact package and version.
2. The D frontend is compiled from the committed multi-module source.
3. The compiled binary executes the committed 22-fixture gate.
4. Positive fixtures parse successfully.
5. Negative syntax fixtures reject with the exact expected primary rule ID.
6. A crash, compiler failure, unsupported result, missing report, or fabricated success fails the gate.
7. The workflow publishes source, fixture, binary, compiler, console, and report hashes.

This milestone proves only the parser gate. It does not claim semantic analysis, execution, Hosted support, Native support, or full Core conformance.
