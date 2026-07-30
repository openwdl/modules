# Module Convention

## Layout

Use one root-level lowercase kebab-case directory per upstream tool:

```text
<tool>/
├── module.json
├── README.md
├── <tool>.wdl
├── <subcommand>/
│   ├── <subcommand>.wdl
│   └── test/
│       └── <subcommand>.yaml
└── test/
    └── fixtures/
```

Module trees may not contain symlinks. `<tool>.wdl` is the explicit module
entrypoint. For a tool with subcommands, put each public subcommand task in
`<subcommand>/<subcommand>.wdl` and selectively import it into the entrypoint
so consumers can write `import { <subcommand> } from <tool>`. Keep a tool with
no subcommands in the entrypoint. Do not add workflows.

## Manifest

`module.json` follows the schema identified by its `$schema` field. Engines
ignore unrecognized fields for forward compatibility, but repository manifests
use only standardized fields. A manifest must:

- use the module license expression `MIT OR Apache-2.0`;
- set `entrypoint` to `<tool>.wdl`;
- set `repository` to the canonical repository URL;
- use a `tools` array whose entries contain required `name`, `version`, and
  SPDX `license` strings, plus optional `url` and `ids` fields;
- search `bio.tools` by tool name and upstream URL before assigning an ID;
- encode identifiers as an `ids` array of registered CURIE strings, such as
  `["biotools:<biotoolsID>"]`, only when the `bio.tools` record is an exact
  upstream match; omit `ids` when no authoritative identifier exists;
- enclose code-like literals in backticks within prose fields such as
  `description`;
- use `{}` for `dependencies` unless WDL imports another module; each declared
  dependency uses either a local `path` or a `git` URL with exactly one of
  `version`, `tag`, `branch`, or `commit`, plus an optional repository `path`;
- contain no comments, duplicate keys, or trailing commas.

The module's release version and the wrapped tool's `tools[].version` serve
different purposes. Changing the wrapped tool in a way that changes expected
outputs requires a new module Git tag even though `module.json` has no
top-level version field.

## WDL tasks

Every document declares `version 1.4`. For tools with subcommands, name each
task after its subcommand, e.g., `filter`, so the module supports
`import { filter } from fq`. For tools without subcommands, use a concise
snake_case task name.

Begin every WDL document with a Sprocket `##` module documentation comment
immediately before the `version` declaration. Its first sentence states the
document's purpose. Its second sentence names every task and user-defined type
that the document exports. Keep license, container, and fixture provenance in
the README rather than duplicating them in this comment.

Treat the pinned executable's actual per-subcommand CLI help as the authoritative
option surface. Cross-check source code to identify flags hidden from help; README
omissions do not narrow required coverage. Every public functional option must have
an explicit typed input. Exclude only help, version, and hidden developer flags.
`extra_args` supports options absent from the pinned CLI, such as future upstream
additions; it never substitutes for a typed input for a current option.

Every finite public CLI choice set uses a top-level WDL enum declared before all
tasks. Enum values exactly match the pinned CLI tokens. Free-form `String` is
reserved for genuinely open-ended input such as filenames, record identifiers,
and regular expressions. When a choice's value is identical to its name, omit
the redundant explicit value. Assign a value only when the pinned CLI token
differs from the WDL choice name. Extract enum values for use in Bash with
`value()`.

For each task:

- expose stable options as typed inputs;
- place `Array[String] extra_args = []` last;
- provide conservative overridable `cpu`, `memory`, `disk_gib`, and
  digest-pinned `container` defaults;
- use `requirements`, never deprecated `runtime` or the `docker` alias;
- use a heredoc command beginning with `set -euo pipefail`;
- use WDL `env` declarations for string, file, directory, and argument-file
  values that enter Bash;
- put `# shellcheck disable=SC2154` before `set -euo pipefail`; this is the only
  default suppression and reconciles WDL runtime `env` exports with ShellCheck;
- do not begin input identifiers with `input`, which Sprocket rejects;
- serialize `extra_args` with `write_lines`, load them using `mapfile -t`, and
  expand the Bash array as `"${extra_args[@]}"`;
- declare deterministic, exact output paths rather than broad globs; and
- use Sprocket `##` comments to document the task, every input, and every output;
  do not add redundant `meta` or `parameter_meta` blocks.

Use Sprocket documentation comments beginning with `##`. Place documentation
comments immediately before every task, user-defined type, enum choice or
struct member, input declaration, and output declaration. Use ordinary `#`
prose comments for private declarations because `sprocket dev doc` does not
publish them and Sprocket reports `##` there as `UnusedDocComments`. Keep
`meta` and `parameter_meta` because they remain part of the WDL task interface.
Enable documentation comments for `sprocket dev doc` with
`doc.with_doc_comments = true` in `sprocket.toml`.

In manifest prose, `meta`, `parameter_meta`, documentation comments, prose
comments, and runtime error messages, enclose code-like literals in backticks.
This includes tool names, versions, task names, subcommand names, option flags,
file paths, identifiers, default values, enum values, and format suffixes such
as `.gz`. Quote shell error strings so backticks remain literal rather than
command substitutions. Syntactic directives such as
`# shellcheck disable=SC2154` are exempt where backticks would break the tool.

`extra_args` preserves argument boundaries but remains a trusted-caller escape
hatch: the wrapper cannot decide whether the upstream tool treats an argument
as dangerous or invalid.

## README

Document:

1. the wrapped tool, exact version, and upstream URL;
2. the upstream license and version-pinned license URL;
3. the container URI, digest, and publisher;
4. why BioContainers replaced an official upstream image, when applicable;
5. every public task and its material behavior, including enum types and their
   available choices for any finite option set; and
6. a `Fixture provenance` section with the pinned tool version, installation
   method, exact deterministic generation and transformation commands, seed,
   and an explicit statement that the data is synthetic when fixtures are
   generated;
   and
7. `sprocket dev test <tool>`.

Enclose code-like literals in backticks throughout README prose: tool names,
version strings, task names, option names, enum choice names and values, file
paths, and format suffixes. Do not backtick ordinary domain terms such as
"FASTQ" or "read pair".

Do not copy upstream prose, code, binaries, or fixtures into the repository.
Fixtures must either be authored for the module or deterministically generated
by the pinned tool with documented provenance.
