# TODO

## MVP

### Implement

- Refresh window IDs when:
  1. an existing app opens a new window
  2. an existing minimized window appears
- When an app quits, delete windows in `window_map`/`window_ref_map`
- [Universal binaries](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary#Update-the-Architecture-List-of-Custom-Makefiles)

### Fix

- Rare chance of app getting stuck, even when using the reliable `GLCaptureView`
- Rare race conditions under `SwiftCaptureView.swift`/`CaptureEngine.swift`
- Prevent window from ever gaining focus on click
  - Still allow click actions
- Remove Sonoma recording icon?
- `CGSSpace` does not play nicely with notifications

### Refactor

- Use [three-letter prefixes](https://google.github.io/styleguide/objcguide.html#prefixes)

## Repo/Project Tasks

### Repo

- Add acknowledgements of other open-source projects used
  1. OBS
  2. HyperSwitch
  3. AltTab
  4. Chromium
- Clean up history
- Create releases

### Project

- Design logo
- Rebrand to WindowTabby
- Test on multiple macOS versions
- [Create Homebrew cask](https://github.com/Homebrew/brew/blob/master/docs/Formula-Cookbook.md#basic-instructions)
- Create website?

## Reach Goals

- Full screen, live previews
- Add _subtle_ shadows
- Multithreading throughout app
  - `BackgroundWork.swift` in AltTab
- Application-level switching?
- Minimal CPU/GPU mode (static thumbnails)?
- HDR support
  - [OpenGL/Metal pixel formats](https://developer.apple.com/forums/thread/698050)
- Auto-updater (Sparkle)
