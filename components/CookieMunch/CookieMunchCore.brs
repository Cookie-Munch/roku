' Cookie Munch for Roku — the pure half.
'
' State, decisions, the consent record and the "do I prompt" answer, with no I/O at all,
' so it runs — and is tested — off-device. CookieMunchTask does the network and the
' registry; CookieMunchDialog draws the prompt. The record this builds is the same one the
' web embed and the iOS/Android SDKs send to POST /api/v1/consent, field for field.

' A fresh, undecided state: necessary on, everything else off, not yet an answer.
function CM_DefaultState(stamp as String, ver as Integer) as Object
    return {
        necessary: true
        preferences: false
        statistics: false
        marketing: false
        method: "implied"
        utc: 0&
        stamp: stamp
        ver: ver
    }
end function

' True once the viewer has actually chosen, as opposed to sitting on the default.
function CM_HasResponse(state as Dynamic) as Boolean
    if state = invalid then return false
    return state.method = "explicit"
end function

' Record a decision: grant = true allows every category, false refuses every optional one.
' Necessary stays on either way; it is not a choice.
function CM_Decide(state as Object, grant as Boolean, nowMs as LongInteger) as Object
    decided = CM_Copy(state)
    decided.necessary = true
    decided.preferences = grant
    decided.statistics = grant
    decided.marketing = grant
    decided.method = "explicit"
    decided.utc = nowMs
    return decided
end function

' Whether this viewer is still owed a prompt. The server resolves the regime from the IP it
' sees (a TV's locale says where it was sold, not where it is); without that answer — first
' launch offline — we ask rather than assume, because assuming wrongly under GDPR means
' tracking someone who never agreed.
function CM_ShouldPrompt(state as Dynamic, regulation as Dynamic) as Boolean
    if CM_HasResponse(state) then return false
    if regulation = invalid then return true
    if CM_IsBool(regulation.consentRequired) then return regulation.consentRequired
    return true
end function

' The body for POST /api/v1/consent. subjectId is omitted entirely when empty or not
' storable, so an anonymous decision is byte-identical to one from a build without it.
function CM_BuildRecord(cbid as String, state as Object, subjectId as String) as Object
    record = {
        cbid: cbid
        stamp: state.stamp
        choices: {
            preferences: state.preferences
            statistics: state.statistics
            marketing: state.marketing
        }
        method: state.method
        ver: state.ver
        utc: state.utc
        url: "app://" + cbid
    }
    ' AddReplace, not record.subjectId: BrightScript folds dotted keys to lowercase, and
    ' FormatJson would then send "subjectid", which the server does not know.
    if CM_ValidSubjectId(subjectId) then record.AddReplace("subjectId", subjectId)
    return record
end function

' What the consent ledger accepts as a subjectId: 1–128 of [A-Za-z0-9._:@+/=~-].
function CM_ValidSubjectId(value as String) as Boolean
    n = Len(value)
    if n < 1 or n > 128 then return false
    allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:@+/=~-"
    for i = 1 to n
        if Instr(1, allowed, Mid(value, i, 1)) = 0 then return false
    end for
    return true
end function

' Serialise for the registry.
function CM_Serialize(state as Object) as String
    return FormatJson(state)
end function

' Restore from the registry. Anything corrupt or partial returns invalid, and the caller
' keeps the undecided default — a damaged store must never read as a decision.
function CM_Parse(raw as Dynamic) as Dynamic
    if raw = invalid or not CM_IsString(raw) or raw = "" then return invalid
    parsed = ParseJson(raw)
    if parsed = invalid or type(parsed) <> "roAssociativeArray" then return invalid
    for each key in ["preferences", "statistics", "marketing"]
        if not CM_IsBool(parsed[key]) then return invalid
    end for
    if parsed.method <> "explicit" and parsed.method <> "implied" then return invalid
    if not CM_IsString(parsed.stamp) or parsed.stamp = "" then return invalid
    if not CM_IsNumber(parsed.ver) or not CM_IsNumber(parsed.utc) then return invalid
    parsed.necessary = true
    return parsed
end function

' The current time in milliseconds, as a LongInteger (32-bit Integer overflows).
function CM_NowMs() as LongInteger
    dt = CreateObject("roDateTime")
    ms& = dt.AsSeconds()
    return ms& * 1000& + dt.GetMilliseconds()
end function

' One block of a parsed /config response, or invalid when it is absent or the wrong shape.
' A server that has not been upgraded simply has no block, which is not an error.
function CM_ConfigBlock(config as Dynamic, name as String) as Dynamic
    if config = invalid or type(config) <> "roAssociativeArray" then return invalid
    block = config[name]
    if block = invalid or type(block) <> "roAssociativeArray" then return invalid
    return block
end function

' A string from the prompt's resolved copy, or the fallback when the server has not
' answered yet — a prompt that waits for the network is a prompt that does not ask.
function CM_Text(copy as Dynamic, key as String, fallback as String) as String
    if copy = invalid or type(copy) <> "roAssociativeArray" then return fallback
    banner = copy.banner
    if banner = invalid or type(banner) <> "roAssociativeArray" then return fallback
    value = banner[key]
    if CM_IsString(value) and value <> "" then return value
    return fallback
end function

function CM_Copy(source as Object) as Object
    out = {}
    for each key in source
        out[key] = source[key]
    end for
    return out
end function

function CM_IsBool(value as Dynamic) as Boolean
    t = type(value)
    return t = "Boolean" or t = "roBoolean"
end function

function CM_IsString(value as Dynamic) as Boolean
    t = type(value)
    return t = "String" or t = "roString"
end function

function CM_IsNumber(value as Dynamic) as Boolean
    t = type(value)
    return t = "Integer" or t = "roInt" or t = "LongInteger" or t = "roLongInteger" or t = "Float" or t = "roFloat" or t = "Double" or t = "roDouble"
end function
