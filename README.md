# LegAI

An AI legal assistant you can type to, talk to, or have **listen in** on a live conversation. Listen In records the conversation on the phone, transcribes it, and flags the moments that need legal advice, as text on screen or whispered into your earbuds.

## Features

- **Ask**: text chat with plain-language answers, the law behind them, read-aloud and follow-up suggestions.
- **Talk**: voice conversation with a live particle orb, captions and spoken answers.
- **Listen In**:
  - A consent step (recording rule, topic, announce, whisper).
  - Live transcript (collapsible) and a level meter.
  - Advice cards that slide in as things are said.
  - Review afterwards: playback, flags on the waveform and the transcript, and sharing with a lawyer.
- **Sessions**: history of chats and recordings. **Settings**: theme (system/light/dark), jurisdiction, Listen In defaults.
- Dark and light themes, built from the logo's gold.

Everything is stored **on the phone**. Speech recognition and the spoken voice use the phone's own engines.

> **Demo answers.** Legal answers and Listen In flags currently come from a built-in rule set (`DemoLegalKnowledgeBase`, `DemoLegalAnalyzer`), so the app works end to end without a backend. Have counsel review the wording and citations before release. See "Connecting a real AI backend" below.

## Architecture

Clean Architecture, organised by feature:

```
lib/
  main.dart                 bootstrap: .env → Supabase (optional) → DI → app
  app/                      composition root: DI (get_it), routes, router, app widget
  core/                     theme tokens, shared widgets & animations, storage, errors, base UseCase
  features/
    <feature>/
      domain/               entities, repository interfaces, use cases (pure Dart)
      data/                 repository implementations, data sources, JSON models
      presentation/         BLoCs/Cubits, pages, widgets
```

Features: `auth`, `onboarding`, `settings`, `chat` (Ask), `voice` (Talk), `listen_in`, `home` (Home and Sessions), and `audio` (speech recognition, text to speech, playback and audio routes shared by the others).

Rules: presentation depends on use cases and domain entities only; data implements domain interfaces; only `app/` reads the service locator.

### Key pieces

| Piece | Where |
| --- | --- |
| Design tokens (dark/light) | `core/theme/legai_colors.dart`, `legai_theme.dart` |
| Particle orb animation | `core/widgets/particle_orb.dart` |
| Waveform / level meter | `core/widgets/waveform_bars.dart` |
| Logo mark (drawn in code) | `core/widgets/legai_mark.dart` |
| Live session orchestration | `features/listen_in/presentation/bloc/live_listen_bloc.dart` |
| Transcript segmentation | `features/listen_in/domain/services/transcript_assembler.dart` |
| Record + transcribe from one mic stream | `features/listen_in/data/repositories/stt_record_capture_repository.dart` |

## Setup

```bash
flutter pub get
dart run flutter_launcher_icons   # regenerates app icons from assets/icon/
flutter run
```

`.env` (bundled as an asset):

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

If either value is empty, the app runs in **guest mode**: no sign-in, everything local.

### Platform notes

- **Android**: `minSdk` 24 (needed by `stt_record`). Recording and transcription share one microphone stream. On Android 12 and below, the saved audio may be incomplete on some devices; this is a platform limitation noted by the plugin.
- **iOS**:
  - Microphone and speech-recognition usage strings, and the `audio` background mode, are in `Info.plist`.
  - Test speech features on a real device.
  - `stt_record` ships a CocoaPods podspec only, so Flutter will generate a Podfile if one is missing.
- Whispered advice plays **only when earbuds or headphones are connected**, so it is never read out loud to the room.

## Connecting a real AI backend

Implement two interfaces and register them in `lib/app/di.dart`. Nothing else changes.

- `LegalAssistantRepository` (`features/chat/domain/repositories/chat_repositories.dart`): answers questions.
- `LegalAnalysisRepository` (`features/listen_in/domain/repositories/listen_repositories.dart`): flags transcript segments and writes the session summary.

A Supabase Edge Function is a good home for this, so the AI provider's key never ships in the app.

## Tests

```bash
flutter test
```

The suite covers:

- **Logic**: transcript assembly, the analyzer and knowledge base, WAV peak extraction, and the chat, live and settings blocs.
- **Screens**: page tests for Listen In, plus a smoke test that renders every screen in both themes on a large and a small phone, and fails on any layout overflow.

To write screenshots of every screen to `build/screens/`:

```bash
flutter test test/screens_smoke_test.dart --update-goldens --dart-define=LEGAI_SHOTS=true
```

## Assets

- `assets/fonts/`: Manrope and Newsreader (SIL Open Font License, see `OFL-*.txt`).
- `assets/brand/`: logo mark and app icon as SVG.
- `assets/icon/`: app icon PNGs for `flutter_launcher_icons`.
