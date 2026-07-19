module main;

import cc1.diagnostic : Diagnostic, FrontendException;
import cc1.lexer : lexSource;
import cc1.parser : parseTokens;
import std.file : readText, write;
import std.json : JSONValue, parseJSON;
import std.stdio : stderr, writeln;

private JSONValue jsonString(string value) {
    return JSONValue(value);
}

private JSONValue jsonBool(bool value) {
    return JSONValue(value);
}

private JSONValue jsonInteger(size_t value) {
    return JSONValue(cast(long) value);
}

int main(string[] args) {
    if (args.length != 3) {
        stderr.writeln("usage: openc-cc1-parser <fixture-bundle.json> <report.json>");
        return 2;
    }

    immutable fixturePath = args[1];
    immutable reportPath = args[2];

    JSONValue root;
    try {
        root = parseJSON(readText(fixturePath));
    } catch (Exception error) {
        stderr.writeln("infrastructure error: cannot read fixture bundle: ", error.msg);
        return 2;
    }

    JSONValue[] resultValues;
    size_t passedCount;
    size_t failedCount;
    size_t infrastructureFailureCount;

    foreach (fixtureValue; root["fixtures"].array) {
        immutable fixtureId = fixtureValue["id"].str;
        immutable source = fixtureValue["source"].str;
        immutable expectedResult = fixtureValue["expected_result"].str;
        string expectedRule;
        if (auto expectedRuleValue = "expected_rule" in fixtureValue.object) {
            expectedRule = (*expectedRuleValue).str;
        }

        bool accepted;
        bool infrastructureFailure;
        Diagnostic diagnostic;
        string infrastructureMessage;

        try {
            auto tokens = lexSource(source);
            parseTokens(tokens);
            accepted = true;
        } catch (FrontendException error) {
            diagnostic = error.diagnostic;
            accepted = false;
        } catch (Exception error) {
            infrastructureFailure = true;
            infrastructureMessage = error.msg;
        }

        immutable actualResult = infrastructureFailure
            ? "infrastructure_failure"
            : (accepted ? "accept" : "reject");

        bool passed;
        if (!infrastructureFailure) {
            if (expectedResult == "accept") {
                passed = accepted;
            } else if (expectedResult == "reject") {
                passed = !accepted && diagnostic.rule == expectedRule;
            }
        }

        if (passed) {
            ++passedCount;
        } else {
            ++failedCount;
        }
        if (infrastructureFailure) {
            ++infrastructureFailureCount;
        }

        JSONValue[string] resultObject;
        resultObject["id"] = jsonString(fixtureId);
        resultObject["expected_result"] = jsonString(expectedResult);
        resultObject["expected_rule"] = jsonString(expectedRule);
        resultObject["actual_result"] = jsonString(actualResult);
        resultObject["passed"] = jsonBool(passed);

        if (!accepted && !infrastructureFailure) {
            JSONValue[string] diagnosticObject;
            diagnosticObject["rule"] = jsonString(diagnostic.rule);
            diagnosticObject["message"] = jsonString(diagnostic.message);
            diagnosticObject["line"] = jsonInteger(diagnostic.line);
            diagnosticObject["column"] = jsonInteger(diagnostic.column);
            diagnosticObject["offset"] = jsonInteger(diagnostic.offset);
            resultObject["diagnostic"] = JSONValue(diagnosticObject);
        }

        if (infrastructureFailure) {
            resultObject["infrastructure_message"] = jsonString(infrastructureMessage);
        }

        resultValues ~= JSONValue(resultObject);

        immutable marker = passed ? "PASS" : "FAIL";
        if (accepted) {
            writeln(marker, " ", fixtureId, " -> accept");
        } else if (infrastructureFailure) {
            writeln(marker, " ", fixtureId, " -> infrastructure_failure: ", infrastructureMessage);
        } else {
            writeln(marker, " ", fixtureId, " -> reject ", diagnostic.rule);
        }
    }

    JSONValue[string] summaryObject;
    summaryObject["total"] = jsonInteger(resultValues.length);
    summaryObject["passed"] = jsonInteger(passedCount);
    summaryObject["failed"] = jsonInteger(failedCount);
    summaryObject["infrastructure_failures"] = jsonInteger(infrastructureFailureCount);

    JSONValue[string] implementationObject;
    implementationObject["name"] = jsonString("openc-cc1-parser");
    implementationObject["language"] = jsonString("D");
    implementationObject["milestone"] = jsonString("CC1-M1-parser");

    JSONValue[string] reportObject;
    reportObject["schema"] = jsonString("openc.cc1.parser_gate_report.v1");
    reportObject["milestone"] = jsonString("CC1-M1-parser");
    reportObject["fixture_bundle"] = jsonString(fixturePath);
    reportObject["implementation"] = JSONValue(implementationObject);
    reportObject["summary"] = JSONValue(summaryObject);
    reportObject["results"] = JSONValue(resultValues);

    write(reportPath, JSONValue(reportObject).toPrettyString() ~ "\n");

    writeln(
        "CC1-M1-parser: ", passedCount, "/", resultValues.length,
        " passed; infrastructure failures: ", infrastructureFailureCount);

    return failedCount == 0 ? 0 : 1;
}
