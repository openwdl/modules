## Wraps `fq` for filtering, generating, validating, and subsampling FASTQ data.
## Exports the `filter`, `generate`, `lint`, and `subsample` tasks and the `FqLintMode`,
## `FqValidationLevel`, and `FqValidator` types.
version 1.4

import { filter } from "filter/filter.wdl"
import { generate } from "generate/generate.wdl"
import { FqLintMode, FqValidationLevel, FqValidator, lint } from "lint/lint.wdl"
import { subsample } from "subsample/subsample.wdl"

## Identifies the upstream `fq` release wrapped by the module.
struct FqRelease {
    ## Exact upstream `fq` version.
    String tool_version
}
