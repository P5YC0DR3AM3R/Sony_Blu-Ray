# Sony_Blu-Ray — BDP-S5100 iOS Remote

A native SwiftUI iPhone remote for the Sony BDP-S5100 Blu-ray player,
controlling it over the local network via Sony's CERS pairing API and the
UPnP IRCC (IR-over-IP) SOAP service.

## Features

- **PIN pairing flow** — one tap sends `GET /cers/api/register` to the player,
  which displays a PIN on your TV; enter it in the app to finish registration.
- **Full remote surface, styled after the physical RMT-B119A remote** —
  eject + power, number pad (0–9) with volume rocker, Audio/Subtitle/Display,
  the four color keys, Top Menu / Pop-Up Menu, D-pad (Up/Down/Left/Right/OK)
  flanked by Return and Options, the Home pill, media transport (Prev, Pause,
  Next, Rewind, Play, Fast Forward, Stop), and Netflix/SEN. VOL and SEN are
  rendered for fidelity but the BDP-S5100 doesn't expose them over IP, so
  they explain that when tapped.
- **IRCC over SOAP** — every keypress is a `POST /IRCC` with the
  `X_SendIRCC` SOAP envelope and `SOAPACTION` header.
- **`.env`-driven configuration** — the player's IP, port, device ID, and
  device name are parsed at runtime by a small custom config manager
  (`EnvConfig.swift`); no hardcoded network values.

## Project layout

```
SonyBDPRemote.xcodeproj/        Xcode project (open this)
SonyBDPRemote/
  SonyBDPRemoteApp.swift        App entry point
  Info.plist                    NSLocalNetworkUsageDescription + local ATS exception
  Config/EnvConfig.swift        .env parser / runtime configuration
  Model/IRCCCommand.swift       IRCC keypress codes for BDP-S players
  Network/BDPNetworkClient.swift  async/await pairing + IRCC SOAP client
  ViewModels/RemoteViewModel.swift
  Views/                        SwiftUI screens (pairing + remote) and theme
Package.swift                   SwiftPM manifest for the non-UI core (CI/Linux verification)
Tests/SonyBDPCoreTests/         Unit tests for config parsing + SOAP building
.env.example                    Template for the gitignored .env
```

## Setup

1. **Create your `.env`** at the repo root (it is gitignored):

   ```sh
   cp .env.example .env
   ```

   ```ini
   BDP_IP=192.168.1.150
   PORT=50001
   DEVICE_ID=MediaRemote:11-22-33-44-55-66
   DEVICE_NAME=iOS_Custom_Remote
   ```

   A build phase ("Copy .env into bundle") copies this file into the app
   bundle so `EnvConfig` can parse it at launch. If the file is missing the
   app falls back to the defaults above and says so on the pairing screen.

2. **Open in Xcode** (14 or newer):

   ```sh
   open SonyBDPRemote.xcodeproj
   ```

3. **Run in the iOS Simulator** — select the `SonyBDPRemote` scheme, pick any
   iPhone simulator, and press **⌘R**. Or from the command line:

   ```sh
   xcodebuild -project SonyBDPRemote.xcodeproj \
     -scheme SonyBDPRemote \
     -destination 'platform=iOS Simulator,name=iPhone 15' \
     build
   ```

   > The Simulator shares your Mac's network, so it can reach the player on
   > your LAN. On a physical iPhone, iOS will show the Local Network
   > permission prompt (configured via `NSLocalNetworkUsageDescription`).

4. **Pair** — with the player on, tap **Start Pairing**. The player shows a
   PIN on the TV; type it in and tap **Complete Pairing**. The remote screen
   appears and every button fires an IRCC keypress.

## Verifying the core without Xcode

The config parser, IRCC codes, and network client are platform-independent
and exposed as a SwiftPM library, so on any machine with a Swift toolchain
(macOS or Linux):

```sh
swift build          # compiles the core
swift test           # runs the unit tests
```

## Protocol notes

- **Pairing** — `GET http://{IP}:{PORT}/cers/api/register?name={DEVICE_NAME}&registrationType=initial&deviceId={DEVICE_ID}`.
  A `401` means the player is displaying a PIN; the app re-sends the request
  with `Authorization: Basic base64(":" + PIN)` to complete registration.
- **Keypresses** — `POST http://{IP}:{PORT}/IRCC` with
  `SOAPACTION: "urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"` and a SOAP
  body carrying the base64 `IRCCCode` for the key.
