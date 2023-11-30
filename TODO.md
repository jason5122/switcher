# TODO

## MVP

### Implement

- Detect more types of crashes/signals
  - Spawn a second process to detect with the app closes?
- [Universal binaries](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary#Update-the-Architecture-List-of-Custom-Makefiles)

### Fix

- Crash when closing a capture window before hiding switcher
- Memory leak
  - Use Instruments.app to measure
- Recording icon sometimes gets stuck. Is this due to an hanging stream?
- Prevent window from ever gaining focus on click
  - Still allow click actions
- Remove Sonoma recording icon?
- `CGSSpace` does not play nicely with notifications

### Refactor

- Make `shortcut_manager.mm` a controller
  - It shouldn't be a model since it contains a controller (WindowController)
- Use [three-letter prefixes](https://google.github.io/styleguide/objcguide.html#prefixes)

## Repo/Project Tasks

### Repo

- Add `README.md`
- Add license
- Add acknowledgements of other open-source projects used
  1. OBS
  2. HyperSwitch
  3. AltTab?
- Remove history
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
