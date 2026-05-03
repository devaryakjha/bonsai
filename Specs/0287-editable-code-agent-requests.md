# Spec 0287: Editable Code Agent Requests

## Intent

Cover Fork 2.64's editable default AI-agent request surface while keeping
Bonsai's code-agent command boundaries read-only and predictable.

## Requirements

- Add Integration preferences for the commit-message request and branch-review
  request.
- Preload both preferences with Bonsai's current default request copy.
- Allow each request to be reset to its default value.
- Keep fixed safety requirements in the generated prompt so custom request text
  cannot remove read-only boundaries, output-shape rules, or attribution rules.
- Fall back to the default request when a stored value is empty.

## Acceptance

- Unit coverage proves custom request text is included in generated prompts.
- Unit coverage proves blank request text falls back to the default request.
- Unit coverage proves fixed branch-review safety requirements remain present
  when the request is customized.
