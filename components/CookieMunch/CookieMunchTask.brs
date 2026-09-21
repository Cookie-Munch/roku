' The I/O half of the Roku client: registry, network, and the command loop. All decision
' logic lives in CookieMunchCore.brs, which is tested off-device.

sub init()
    m.top.functionName = "consentLoop"
end sub

sub consentLoop()
    port = CreateObject("roMessagePort")
    m.top.observeField("command", port)

    m.section = CreateObject("roRegistrySection", "CookieMunch")
    m.key = "state_" + m.top.cbid

    state = CM_Parse(m.section.Read(m.key))
    if state = invalid then
        state = CM_DefaultState(CreateObject("roDeviceInfo").GetRandomUUID(), 1)
    end if
    m.top.state = state

    regulation = fetchRegulation()
    if regulation <> invalid then m.top.regulation = regulation
    m.top.consentRequired = CM_ShouldPrompt(state, regulation)
    m.top.ready = true

    while true
        msg = wait(0, port)
        if type(msg) = "roSGNodeEvent" and msg.getField() = "command" then
            command = msg.getData()
            if command = "accept" or command = "decline" then
                decided = CM_Decide(m.top.state, command = "accept", CM_NowMs())
                persist(decided)
                m.top.state = decided
                m.top.consentRequired = false
                send(decided)
            end if
        end if
    end while
end sub

' The decision is kept locally before anything is sent: an offline TV still remembers it.
sub persist(state as Object)
    m.section.Write(m.key, CM_Serialize(state))
    m.section.Flush()
end sub

function transfer(url as String) as Object
    xfer = CreateObject("roUrlTransfer")
    xfer.SetUrl(url)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.AddHeader("Content-Type", "application/json")
    xfer.AddHeader("Accept", "application/json")
    return xfer
end function

' GET /config/:cbid — the server resolves the regime from the IP it sees.
function fetchRegulation() as Dynamic
    raw = transfer(m.top.apiBase + "/config/" + m.top.cbid).GetToString()
    if raw = invalid or raw = "" then return invalid
    config = ParseJson(raw)
    if config = invalid or type(config.regulation) <> "roAssociativeArray" then return invalid
    return config.regulation
end function

' POST /api/v1/consent. Never retried inline: the local copy is already saved.
sub send(state as Object)
    record = CM_BuildRecord(m.top.cbid, state, m.top.subjectId)
    transfer(m.top.apiBase + "/api/v1/consent").PostFromString(FormatJson(record))
end sub
