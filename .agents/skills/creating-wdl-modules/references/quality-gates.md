# Quality Gates

## Test placement

Sprocket matches each `<name>.wdl` with an adjacent `test/<name>.yaml`. For
tools with subcommands, keep each native test YAML beside its subcommand WDL
under `<subcommand>/test/<subcommand>.yaml`. Put shared minimal fixtures under
the module's root `test/fixtures`. Fixtures may be authored for the module or
generated deterministically by the pinned tool when the README records the
exact command, seed, version, installation method, transformation commands, and
synthetic-data status. Never use copied or unknown fixtures.
Sprocket writes execution state under ignored `test/runs` directories.

Every public task needs at least one native test. Add cases or an input matrix
for meaningful option branches. Assert every supported semantic property:

- `exit_code` or intentional `should_fail`;
- exact Boolean, string, integer, or float values;
- array/map length or emptiness and first/last array elements;
- file and directory basenames with `Name`; and
- meaningful stdout/stderr regular expressions.

Do not use the schema's `custom` assertion until the repository's minimum
Sprocket release implements it. Do not add test-only WDL outputs merely to
inspect opaque file contents.

## Development loop

Format changed WDL:

```bash
sprocket format overwrite <module-directory>
```

Run the smallest relevant checks:

```bash
sprocket dev module verify --manifest-path <module-directory>
sprocket lint <module-directory>
sprocket dev test <module-directory>
```

Then reproduce CI:

```bash
sprocket format check .
sprocket lint .
sprocket dev doc --check .

shopt -s nullglob
for manifest in ./*/module.json; do
    module_dir="$(dirname "$manifest")"
    sprocket dev module verify --manifest-path "$module_dir"
    sprocket dev test "$module_dir"
done
```

If a gate fails, preserve the evidence, fix the root cause, rerun the smallest
failing command, then rerun the complete gate. Do not add broad exceptions,
remove assertions, change expected output without upstream evidence, or weaken
CI.
