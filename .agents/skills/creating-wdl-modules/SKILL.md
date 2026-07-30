---
name: creating-wdl-modules
description: Use when creating, adding, scaffolding, bootstrapping, or updating a WDL module that wraps a bioinformatics command-line tool in this repository.
---

# Creating WDL Modules

## Overview

Create reusable WDL 1.4 tool modules only after proving upstream license and
container provenance. A module is complete when its typed tasks, documentation,
native Sprocket tests, and repository-wide CI-equivalent checks all pass.

## Required order

1. Inspect `README.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`,
   `sprocket.toml`, CI, and existing modules.
2. Fix the exact upstream tool version and commands in scope.
3. Read [license-review.md](references/license-review.md). Complete the license
   decision before creating module files.
4. Resolve a digest-pinned official upstream image. Use BioContainers only
   through the documented fallback.
5. Read [module-convention.md](references/module-convention.md). Derive typed
   task interfaces from the pinned version's per-subcommand CLI help, and
   cross-check source to exclude only hidden developer flags. Represent every
   finite public CLI choice set as a WDL enum during interface derivation. Look
   up the tool on `bio.tools` before deciding whether the manifest has an ID.
   Record upstream tool provenance using the current `tools` object fields.
6. Create or update the manifest, README, root WDL entrypoint, one WDL file per
   public subcommand, one adjacent native test YAML per subcommand,
   provenance-documented fixtures, and shared `test/fixtures`. Give every WDL
   document a two-sentence module documentation comment that states its purpose
   and names every task and user-defined type it exports. Fixtures may be
   original or deterministically generated with the pinned tool.
7. Read [quality-gates.md](references/quality-gates.md). Run the targeted
   module checks, then every repository-wide CI-equivalent check.
8. Report provenance evidence and the factual PR tools-table row.

## Hard gates

Stop rather than improvise when:

- the upstream license is prohibited, missing, or ambiguous;
- neither the upstream project nor BioContainers publishes a suitable image;
- an immutable image digest cannot be verified;
- fixtures are copied or have unknown or undocumented provenance;
- authoritative docs do not support the proposed task interface; or
- formatting, linting, native tests, or CI still fail.

## Non-negotiable rules

| Pressure                                       | Required response                                                                                                                              |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| "Ship now; review the license later"           | License review precedes scaffolding.                                                                                                           |
| "The tag is specific enough"                   | WDL container must include the immutable sha256 digest; a bare tag is not pinned.                                                              |
| "Use any working image"                        | Only an official upstream image or BioContainers fallback—searched in that order and digest-pinned—is accepted.                                |
| "Tests can follow"                             | Every public task ships with passing `sprocket dev test` coverage before merge.                                                                |
| "I'll track tests in a follow-up issue"        | No follow-up issue substitutes for `sprocket dev test` passing at merge time.                                                                  |
| "A smoke test is enough for now"               | Native `sprocket dev test` coverage is required; minimal smoke tests are not equivalent.                                                       |
| "`extra_args` supports that option"            | Every public functional option in the pinned CLI has a typed input; `extra_args` only covers options absent from that CLI.                     |
| "Silence the lint or change expected output"   | Fix the cause; do not weaken the gate without evidence of an incorrect gate.                                                                   |
| "A `String` is simpler for these choices"      | Represent every finite public CLI choice set as a WDL enum with values matching the pinned CLI tokens.                                         |
| "Spell out every enum value"                   | Omit an explicit enum value when it is identical to the choice name; assign a value only when the pinned CLI token differs.                    |
| "One WDL file is simpler"                      | Put each public subcommand in its own folder and WDL file, then selectively re-export it from the module entrypoint.                           |
| "`meta` and `parameter_meta` are still needed" | Omit them when Sprocket `##` comments document the same task, inputs, and outputs.                                                             |
| "The README already describes the module"      | Give every WDL document a two-sentence `##` module comment that states its purpose and names every task and user-defined type it exports.      |
| "Generated fixtures need no provenance"        | Document the pinned tool version, exact generation and transformation commands, seed, and installation method.                                 |
| "Backticks are cosmetic"                       | Enclose literals in backticks throughout prose documentation, manifest strings, WDL metadata, prose code comments, and runtime error messages. |

## Completion contract

Do not claim completion until the changed module's native tests and all
repository CI-equivalent commands pass. Do not check contributor legal
attestations or maintainer-only PR checkboxes on another person's behalf.

## Cross-client note

The canonical skill lives under `.agents/skills`. Claude uses the committed
`.claude/skills` symlink. Windows checkouts must enable Developer Mode and Git
symlink support or Claude cannot discover this repository skill.
