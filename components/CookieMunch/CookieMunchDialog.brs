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
    m.titleLabel.text = m.top.title
    m.messageLabel.text = m.top.message
    m.decline.text = m.top.declineLabel
    m.accept.text = m.top.acceptLabel
end sub

sub onConsent()
    consent = m.top.consent
    if consent = invalid then return
    consent.observeField("ready", "refresh")
    consent.observeField("consentRequired", "refresh")
    refresh()
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
