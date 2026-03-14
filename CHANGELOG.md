# Changelog

All notable changes to Disable Safe Media Volume will be documented here.

---

## [v1.1] - 2026-03-14

### Added
- APatch and KernelSU support alongside existing Magisk support
- GitHub release-based auto-updating via `updateJson` in module.prop
- `update.json` for release tracking
- Custom installer UI with sponsor callout in `customize.sh`

### Changed
- `audio_safe_volume_state` setting changed from `3` to `0` (was likely setting enforcing state instead of disabled)
- Expanded `system.prop` to target CSD (Content Sound Dosimetry) enforcement introduced in Android 14, which is likely responsible for the aggressive ~2 hour reset rather than the standard 20 hour AOSP timer
- Added `persist.` variants of all props to ensure they survive reboot

### Fixed
- `ro.` prefixed props removed — these are set before module props load and were likely being ignored entirely

---

## [v1.0] - Initial Release

### Added
- Basic safe media volume prop patching
- Boot-completed service script
- Initial settings database overrides
