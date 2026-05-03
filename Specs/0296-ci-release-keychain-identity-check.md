# Spec 0296: CI Release Keychain Identity Check

## Intent

The protected release workflow imports the Developer ID certificate into a
temporary CI keychain. Release credential checks must inspect that keychain
instead of assuming the identity lives in the login keychain.

## Requirements

- Use `BONSAI_NOTARY_KEYCHAIN` as the codesigning identity search keychain when
  it is set.
- Preserve the login-keychain behavior for local maintainer checks where no
  release keychain override is provided.
- Apply the same keychain selection to `--doctor`, `--check-credentials`,
  `--archive`, and `--notarize` credential gates.
- Keep diagnostic output secret-free.

## Acceptance

- A temporary keychain with the Bonsai Developer ID `.p12` import is reported as
  having the configured Developer ID identity.
- Missing notary profile validation remains a separate failure, proving the
  identity check no longer blocks before the notarization credential check.
