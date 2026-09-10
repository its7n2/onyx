# Rules of Engagement — <Customer> / <Activity Type> (<YYYY-MM-DD>)

## Testing window
<Days/hours testing is permitted, timezone. Any blackout periods.>

## Allowed techniques
<e.g. network scanning, cred spraying against SSO with client approval, social engineering if contracted — be explicit>

## Prohibited
<e.g. DoS/load testing, physical attacks, social engineering, destructive payloads, kernel exploits on production>

## Rate limits / stealth requirements
<e.g. max threads, scanning only within window, IDS/AV evasion expectations>

## Credentials provided
| System | Username | Notes |
|---|---|---|
| | | (actual secrets stay with the operator / client vault — record here only what system + account) |

## Escalation & emergency contacts
| Trigger | Contact | Channel | SLA |
|---|---|---|---|
| Service crash / degradation | | | |
| Security team detection | | | |
| Critical finding (exploitable now) | | | |

## Crash / incident policy
<What happens if something breaks: stop, preserve state, notify <contact>, document timeline.>

## Evidence handling
<Where evidence lives (activity folder), retention, encryption at rest, who may access it.>

## Sign-off
- Operator confirmation: <date>
- Client RoE document received: <yes/no + reference>
