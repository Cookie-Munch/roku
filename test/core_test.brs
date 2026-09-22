' Off-device tests for CookieMunchCore.brs, run with brs-node:
'   npx brs-cli components/CookieMunch/CookieMunchCore.brs test/core_test.brs
' Prints one line per check and a final "ROKU-CORE <passed>/<total>".

sub Main()
    m.passed = 0
    m.total = 0

    s = CM_DefaultState("stamp-1", 3)
    check("a fresh state is not an answer", not CM_HasResponse(s))
    check("a fresh state keeps necessary on", s.necessary = true)
    check("a fresh state grants nothing optional", not s.preferences and not s.statistics and not s.marketing)

    yes = CM_Decide(s, true, 1758000000123&)
    check("allowing is an answer", CM_HasResponse(yes))
    check("allowing grants every category", yes.preferences and yes.statistics and yes.marketing)
    check("the decision keeps its millisecond time", yes.utc = 1758000000123&)
    check("deciding does not mutate the old state", not CM_HasResponse(s))

    no = CM_Decide(s, false, 5&)
    check("refusing is an answer too", CM_HasResponse(no))
    check("refusing keeps necessary on", no.necessary and not no.marketing)

    check("no answer and no regime: ask", CM_ShouldPrompt(s, invalid))
    check("no answer, regime requires it: ask", CM_ShouldPrompt(s, { consentRequired: true }))
    check("no answer, opt-out regime already answered: do not ask", not CM_ShouldPrompt(s, { consentRequired: false }))
    check("already answered: never ask again", not CM_ShouldPrompt(yes, { consentRequired: true }))

    check("round-trips through the registry", CM_HasResponse(CM_Parse(CM_Serialize(yes))))
    check("corrupt storage is not a decision", CM_Parse("{not json") = invalid)
    check("partial storage is not a decision", CM_Parse("{""method"":""explicit""}") = invalid)
    check("an empty store is not a decision", CM_Parse("") = invalid)

    check("a storable subject id", CM_ValidSubjectId("user-4471"))
    check("an email is storable", CM_ValidSubjectId("ada@example.com"))
    check("spaces are not", not CM_ValidSubjectId("has space"))
    check("empty is not", not CM_ValidSubjectId(""))

    anon = CM_BuildRecord("cb-tv", no, "")
    check("an anonymous record has no subjectId at all", not anon.DoesExist("subjectId"))
    known = CM_BuildRecord("cb-tv", yes, "user-4471")
    check("a signed-in record carries it", known.subjectId = "user-4471")
    check("with the key spelled the way the server reads it", Instr(1, FormatJson(known), """subjectId""") > 0)
    check("the record names the channel", known.url = "app://cb-tv")

    check("now is a plausible millisecond clock", CM_NowMs() > 1600000000000&)

    ' The prompt's words come from the server, in the viewer's language.
    config = ParseJson("{""regulation"":{""consentRequired"":true},""copy"":{""language"":""de"",""banner"":{""title"":""Wir respektieren Ihre Privatsphäre"",""acceptAll"":""Alle akzeptieren""}}}")
    copy = CM_ConfigBlock(config, "copy")
    check("reads the copy block", copy <> invalid)
    check("uses the server's words", CM_Text(copy, "acceptAll", "Allow all") = "Alle akzeptieren")
    check("falls back when a string is missing", CM_Text(copy, "rejectAll", "Reject all") = "Reject all")
    check("falls back with no copy at all", CM_Text(invalid, "acceptAll", "Allow all") = "Allow all")
    check("a response without the block is not an error", CM_ConfigBlock(ParseJson("{}"), "copy") = invalid)
    check("still reads the regime alongside it", CM_ConfigBlock(config, "regulation").consentRequired = true)

    ' The exact wire body, for the server-side validator to check (see roku-record.test.ts).
    print "RECORD " + FormatJson(known)
    print "ROKU-CORE " + m.passed.ToStr() + "/" + m.total.ToStr()
end sub

sub check(name as String, ok as Boolean)
    m.total = m.total + 1
    if ok then
        m.passed = m.passed + 1
        print "ok   " + name
    else
        print "FAIL " + name
    end if
end sub
