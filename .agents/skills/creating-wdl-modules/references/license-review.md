# License and Container Review

## Evidence record

Before writing module files, record:

| Field        | Required evidence                                       |
| ------------ | ------------------------------------------------------- |
| Tool         | Canonical upstream project name and URL                 |
| Version      | Exact release tag or immutable commit                   |
| License      | Full name and SPDX identifier                           |
| License file | Direct URL pinned to the selected tag or commit         |
| Commands     | Authoritative documentation for each wrapped command    |
| Container    | Registry, immutable digest, and publisher               |

Prefer the upstream repository's license file at the selected release. Package
metadata may corroborate it but does not replace available upstream evidence.
Repeat the review for every version update.

## Policy decision

Compare the verified license with `README.md`:

- Continue only when the license is on the approved list.
- Stop for AGPL or another prohibited use-triggered license.
- Stop and present the evidence for maintainer review when the license is
  unlisted, unclear, conflicting, or missing.

Do not create a partial module before this decision.

## Container decision

1. Search the upstream project for an official image matching the exact selected
   version and supported platform.
2. If no suitable official image exists, search BioContainers for the exact
   upstream version and supported platform.
3. Resolve the selected image's OCI digest with:

   ```bash
   docker buildx imagetools inspect <image-tag>
   ```

4. Put `<image-tag>@sha256:<digest>` in WDL.
5. Verify the image executes the expected tool version through the module's
   Sprocket tests.

When BioContainers supplies the fallback, explain why no suitable official
upstream image was used in the module README. Stop if neither source is
available. An image from another third party and a mutable tag are not
fallbacks.

## Pull-request handoff

Provide this factual table:

```markdown
| Tool                            | Version     | License             | SPDX     | License file                                | Needs review? |
| ------------------------------- | :---------: | ------------------- | :------: | ------------------------------------------- | :-----------: |
| [<tool>](<project-url>)         | `<version>` | <full-license-name> | `<spdx>` | [Link](<version-pinned-license-url>)        |       ☐       |
```

Leave `Needs review?` as `☐` for an approved license. Change it to `☒` only
for an unlisted license that the maintainer must review. Never check a
contributor's right-to-license attestation or any maintainer-only checkbox.
