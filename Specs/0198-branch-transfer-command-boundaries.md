# Spec 0198: Branch Transfer Command Boundaries

## Intent

Push, pull, merge, rebase, and tag transfer actions are high-impact Git
operations. Their arguments should be tested at the same boundary as other v0
Fork-parity commands.

## Requirements

- Route branch publish through a static argument builder.
- Route force-push-with-lease through a static argument builder.
- Route selected-branch pull through a static argument builder.
- Route merge, rebase, tag push, and remote tag delete through static builders.
- Preserve branch, remote, upstream, tag, and ref names as single arguments.
- Reject branches without usable upstreams for force-push and non-current pull.

## Acceptance

- Command argument coverage proves branch publish and force-with-lease.
- Command argument coverage proves current and non-current branch pull.
- Command argument coverage proves merge/rebase reference commands.
- Command argument coverage proves tag push and remote tag delete commands.
- SwiftPM tests and the app verifier pass.
