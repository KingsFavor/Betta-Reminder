<div align="center">
  <img src="assets/logo.png" alt="Betta" width="88" />
  <h1>Betta</h1>
  <p><b>일정 간격마다 모든 창 위에 조용히 떠오르는 미니멀 리마인더</b></p>
  <p><i>Minimal always-on-top interval reminders for macOS.</i></p>
</div>

---

## 무엇을 하나요

- **모든 창 위에 뜨는 팝업** — 알림 센터 배너가 아니라, 다른 앱·전체 화면 위까지 떠오르는 인앱 팝업으로 리마인드합니다.
- **간편한 주기 설정** — `간격` · `활동 시간대` · `요일`을 몇 번의 탭으로. 예) 50분마다 · 09–18 · 평일.
- **알림 템플릿** — `사무직 스트레칭` 템플릿은 실제 스트레칭 이미지와 함께 목·어깨·손목·허리·눈 자세를 번갈아 안내합니다.
- **테스트 & 토글** — 각 알림을 즉시 미리보고, 스위치로 켜고 끕니다.
- **Dock + 메뉴바** — Dock 아이콘을 누르면 활성 알림과 *다음 알림까지 남은 시간*이 보입니다. 메뉴바에서 빠르게 확인·토글.

가볍고 네이티브입니다 — **SwiftUI만** 사용하고, 모든 데이터는 **로컬**(Application Support의 JSON 한 파일)에 저장됩니다.

## 요구 사항

- macOS 14 (Sonoma) 이상

## 설치 (Homebrew)

```bash
brew install --cask kingsfavor/tap/betta
```

## 업데이트

```bash
brew update && brew upgrade --cask betta
```

Homebrew로 설치하지 않았다면 [Releases](https://github.com/KingsFavor/Betta-Reminder/releases)에서 최신 `Betta-x.y.z.dmg`를 받아 `/Applications`의 앱을 덮어쓰세요. 앱은 실행 시 조용히 새 버전을 확인하고, 새 버전이 있으면 상단에 배너로 알려줍니다.

## 빌드

```bash
xcodebuild build -project Betta.xcodeproj -scheme Betta \
  -configuration Debug -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO
```

## 구조

```
Betta/
  App/       진입점 · 창/메뉴바/설정 씬 · Dock 재활성화
  Design/    Theme(팔레트·모양) · Color+Hex
  Models/    Reminder · Schedule · ReminderTemplate · 포맷 헬퍼
  Store/     ReminderStore (로컬 JSON 영속 · CRUD)
  System/    ReminderEngine(스케줄 틱) · PopupPresenter(플로팅 팝업) · UpdateChecker · LaunchAtLogin
  Views/     RootView · 편집기 · 스케줄 피커 · 템플릿 갤러리 · 팝업 · 메뉴바 · 설정
```

배포는 태그(`vX.Y.Z`) 푸시로 `release.yml`이 공증 DMG를 만들고 `KingsFavor/homebrew-tap`의 cask를 갱신합니다.
