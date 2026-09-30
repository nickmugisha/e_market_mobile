# LOT 10 — Final QA, documentation & submission readiness

LOT 10 is intentionally a stabilization/documentation LOT rather than a new
business-feature LOT.

Added/updated:
- final `README.md`;
- final Firestore schema/security overview;
- complete physical-phone runtime checklist;
- short exam demonstration script;
- final QA status;
- submission checklist;
- reusable `scripts/final_qa.ps1`.

Final local validation includes an Android debug APK build so the native Kotlin
image picker and WhatsApp bridge are compiled even while no phone is available.

No Firestore rule deployment is required by LOT 10 because this LOT does not
change application security rules.

Physical runtime certification remains deferred until a phone is available.
