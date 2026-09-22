sub init()
    m.top.visible = false
    m.titleLabel = m.top.findNode("titleLabel")
    m.messageLabel = m.top.findNode("messageLabel")
    m.decline = m.top.findNode("declineButton")
    m.accept = m.top.findNode("acceptButton")
    m.decline.observeField("buttonSelected", "onDecline")
    m.accept.observeField("buttonSelected", "onAccept")
    render()
end sub

sub render()
    ' The server's words for this viewer's language when they have arrived; the field
    ' defaults otherwise, so the prompt still asks on a first launch with no network.
    copy = invalid
    if m.top.consent <> invalid then copy = m.top.consent.copy
    m.titleLabel.text = CM_Text(copy, "title", m.top.title)
    m.messageLabel.text = CM_Text(copy, "body", m.top.message)
    m.decline.text = CM_Text(copy, "rejectAll", m.top.declineLabel)
    m.accept.text = CM_Text(copy, "acceptAll", m.top.acceptLabel)
end sub

sub onConsent()
    consent = m.top.consent
    if consent = invalid then return
    consent.observeField("ready", "refresh")
    consent.observeField("consentRequired", "refresh")
    ' Re-draw when the words land, which may be after the prompt is already on screen.
    consent.observeField("copy", "render")
    refresh()
    render()
end sub

' Show while a decision is owed; hand focus to the first choice as it appears, so the
' first press of the remote does something visible.
sub refresh()
    consent = m.top.consent
    owed = consent <> invalid and consent.ready and consent.consentRequired
    if owed and not m.top.visible then
        m.top.visible = true
        m.decline.setFocus(true)
    else if not owed and m.top.visible then
        m.top.visible = false
    end if
end sub

sub onDecline()
    decide("decline")
end sub

sub onAccept()
    decide("accept")
end sub

sub decide(command as String)
    m.top.consent.command = command
    m.top.visible = false
    m.top.done = true
end sub

' Left and right move between the two choices. Everything else — including Back — is left
' to the channel, so the prompt never traps the viewer or breaks Roku's navigation rules.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press or not m.top.visible then return false
    if key = "left" then
        m.decline.setFocus(true)
        return true
    else if key = "right" then
        m.accept.setFocus(true)
        return true
    end if
    return false
end function
