# Spec 0060: Interactive Rebase Sheet Focus

## Objective

Make the interactive rebase sheet feel like a focused editing surface rather
than an instructional panel.

## Requirements

- The default sheet must prioritize the commit action list and row controls.
- Raw todo text must be opt-in through disclosure, not always visible.
- The sheet may show compact state metadata such as commit count and upstream.
- Visible copy must stay professional, short, and sentence-case.

## Acceptance

- Opening the sheet shows the action list without a raw todo preview.
- The generated todo text remains available for inspection.
- `swift test`, the app verification script, and whitespace checks pass.
