# Spec 0197: Branch and Tag Command Boundaries

## Intent

Branch and tag mutations are central v0 Git-client operations. Their Git
arguments should be inspectable and covered before the UI invokes them.

## Requirements

- Route local branch create, rename, and delete through static argument builders.
- Route tag create, annotated create, and delete through static argument builders.
- Route checkout, tracking checkout, upstream set/unset, and reset through static
  argument builders.
- Preserve branch names, tag names, messages, upstreams, targets, and refs as
  single arguments.
- Preserve force delete and reset mode flag ordering.

## Acceptance

- Command argument coverage proves branch create, rename, and delete commands.
- Command argument coverage proves tag create, annotated create, and delete
  commands.
- Command argument coverage proves checkout, upstream, and reset commands.
- SwiftPM tests and the app verifier pass.
