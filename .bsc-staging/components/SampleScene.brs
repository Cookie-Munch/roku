sub init()
    m.status = m.top.findNode("status")

    m.consent = CreateObject("roSGNode", "CookieMunchTask")
    m.consent.cbid = "your-cbid"
    m.consent.observeField("state", "onState")
    m.consent.control = "RUN"

    m.top.findNode("consentDialog").consent = m.consent
end sub

' Only start measurement once it is allowed — the Roku equivalent of prior-blocking.
sub onState()
    state = m.consent.state
    if state <> invalid and state.statistics then
        m.status.text = "Analytics allowed"
    else
        m.status.text = "Analytics off"
    end if
end sub
