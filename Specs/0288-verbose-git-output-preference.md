# Spec 0288: Verbose Git Output Preference

## Intent

Cover Fork 2.62's verbose Git output preference without making Bonsai noisier by
default.

## Requirements

- Add a General preference for verbose Git output.
- Keep verbose output off by default.
- When enabled, prepend the executed Git command to mutation command output.
- Preserve the existing quiet command result behavior when disabled.
- Keep the implementation centralized instead of modifying every Git action.

## Acceptance

- Unit coverage proves quiet formatting preserves existing output.
- Unit coverage proves verbose formatting includes the Git command and output.
- Unit coverage proves commands with arguments that contain spaces remain
  readable.
