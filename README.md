# Cookie Munch for Roku

Consent for Roku channels: a SceneGraph Task that keeps and records the viewer's decision,
and a dialog built for the remote. It writes the same consent record as the Cookie Munch web
embed and the iOS/Android SDKs, so a decision made on a TV is the same row in your ledger.

## Install

Copy `components/CookieMunch/` into your channel's `components/` folder:

| File | Does |
|---|---|
| `CookieMunchCore.brs` | The logic: state, decisions, the consent record, whether to prompt. No I/O. |
| `CookieMunchTask.xml` / `.brs` | Registry storage and the network, on a Task thread as SceneGraph requires. |
| `CookieMunchDialog.xml` / `.brs` | The prompt: a centred card, two equal choices, left/right to move, OK to choose. |

## Use

```brightscript
' In your Scene's init()
m.consent = CreateObject("roSGNode", "CookieMunchTask")
m.consent.cbid = "your-cbid"
m.consent.subjectId = "account-123"   ' optional: your signed-in account id
m.consent.observeField("state", "onConsentState")
m.consent.control = "RUN"

m.top.findNode("consentDialog").consent = m.consent
```

```xml
<CookieMunchDialog id="consentDialog" />
```

Only start measurement once it is allowed:

```brightscript
sub onConsentState()
    if m.consent.state.statistics then startAnalytics()
end sub
```

To record a decision from your own UI instead, write `"accept"` or `"decline"` to
`m.consent.command`.

The dialog shows itself when a decision is owed and hides once one is made. Back is left to
your channel, so the prompt never traps the viewer. Decisions are saved to the registry
before they are sent — an offline set still remembers them. Until the server has said which
privacy regime applies (it decides from the IP address, not the set's region setting), the
channel asks rather than assumes.

Full reference: <https://cookiemunch.net/docs/connected-tv>

## Development

`sample/` is a minimal channel wired to the components. Neither check needs a Roku:

```bash
# logic tests, in an off-device BrightScript interpreter
npx -p brs-node@2.6.0 brs-cli components/CookieMunch/CookieMunchCore.brs test/core_test.brs
# compile and validate every component, SceneGraph XML included
npx -p brighterscript@0.73.5 bsc --project bsconfig.json
```
