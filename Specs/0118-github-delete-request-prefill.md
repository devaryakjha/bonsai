# Spec 0118: GitHub Delete Request Prefill

## Objective

Make GitHub repository deletion safer by pre-filling the destructive request
from the repository remote a user is most likely to mean.

## Requirements

- Delete GitHub Repository prefers a GitHub `origin` remote target when present.
- If `origin` is not a GitHub remote, Bonsai falls back to another GitHub
  remote target.
- If no GitHub remote exists, the delete request keeps owner empty and falls
  back to the selected local repository name.
- No provider network call runs while presenting the delete sheet.

## Acceptance

- Store tests cover origin preference and non-GitHub fallback behavior.
- GitHub remote target parsing remains covered separately.
- `swift test`, the app verification script, and whitespace checks pass.
