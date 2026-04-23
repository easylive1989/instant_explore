# App Store Review — AI Disclosure Reply (2026-04-21)

> Paste the body below into the App Store Connect reply for submission
> `e05d912c-09c9-445b-bb42-e57e9f1e61ef` (Guideline 2.1). Keep this file
> updated if the AI stack changes so future submissions can reuse it.

## Guideline 2.1 — AI Disclosure

**1. Does your app use any third-party AI for analysis of data?**

Yes.

**2. What is the name of the third-party AI provider?**

Google Vertex AI (Gemini 2.5 Flash), accessed through the Firebase AI
SDK (`firebase_ai` package).

**3. List the types of data being transmitted to the third-party AI.**

Per narration request, the app sends:

- Public place metadata sourced from the Google Places API: the place's
  name, formatted address, category, place types, and rating (when
  available).
- A localized prompt template (English or Traditional Chinese)
  describing the desired narration style, length, and audience.

The app does **not** transmit:

- User account identifiers
- Email addresses or names
- Device identifiers
- Photos, audio recordings, or camera input
- Location coordinates or movement data

## App Store Connect metadata checklist

Before resubmission, confirm all three:

- [ ] App Description ends with `Terms of Use (EULA): https://lorescape.app/terms`
- [ ] App Information → Privacy Policy URL is `https://lorescape.app/privacy`
- [ ] This reply is pasted into App Review Notes for the next build
