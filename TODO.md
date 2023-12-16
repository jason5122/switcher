# TODO

## MVP

### Implement

- Refresh window IDs when:
  1. an existing app opens a new window, or
  2. an existing minimized window appears.
- When an app quits, delete windows in `window_map`/`window_ref_map`.

### Fix

- Handle "AXError for AXWindows" segfault.
- `universalaccessd` eventually has high CPU usage.
  - Maybe this is due to multiple launches?
  - Or, it could be from showing/hiding thumbnails many times.
- There is a rare chance of app getting stuck, even when using the reliable `GLCaptureView`.
- Rare race conditions occur under `SwiftCaptureView.swift`/`CaptureEngine.swift`
- Prevent window from ever gaining focus on click.
  - However, we should still allow click actions.
- Remove the Sonoma recording icon.
- `CGSSpace` does not play nicely with notifications.

### Refactor

- Use [three-letter prefixes](https://google.github.io/styleguide/objcguide.html#prefixes)
- Clean up GN Python stuff

## Repo/Project Tasks

### Repo

- Add acknowledgements of other open-source projects used
  1. OBS
  2. HyperSwitch
  3. AltTab
  4. Chromium
- Clean up history.
- Create releases.

### Project

- Design logo.
- Rebrand to WindowTabby.
- Test on multiple macOS versions.
- [Create Homebrew cask](https://github.com/Homebrew/brew/blob/master/docs/Formula-Cookbook.md#basic-instructions).
- Create the project website!

## Reach Goals

- Implement full screen live previews.
- Add _subtle_ shadows maybe?
- Implement application-level switching?
- Implement a minimal CPU/GPU mode (static thumbnails)?
- Add HDR support?
  - Reference [OpenGL/Metal pixel formats](https://developer.apple.com/forums/thread/698050).
- Add auto-updater (Sparkle).
