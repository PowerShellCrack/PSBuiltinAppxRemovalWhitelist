# Change log for RemoveBuiltinAppxWhitelist.ps1

## Unreleased

## 2.0.1 - Oct 08, 2021

- Ran Invoke-ScriptAnalyzer against script; made sure all warnings were addressed
- Change write-progress to a tasksequence version (if used)
- changed name to Appx instead of Apps
- fixed logging output; missing splat parameters
- Fixed whitelist appx for Windows 11; change dot to comma
- Added Testonly switch to ensure apps removed are accurate before actually running

## 2.0.0 - Oct 08, 2021

- Added OS version control; added all tested OS.
- Added logging
- Added parameters to append to Appx and FoD list

## 1.0.0 - Oct 1, 2021

- Initial