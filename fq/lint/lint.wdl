## Wraps `fq lint` to validate single or paired FASTQ data.
## Exports the `lint` task and the `FqLintMode`, `FqValidationLevel`, and `FqValidator`
## types.
version 1.4

## Controls whether `fq lint` stops at the first error or logs all errors.
enum FqLintMode[String] {
    ## Stops at the first validation error.
    Panic = "panic",

    ## Logs all validation errors before failing.
    Log = "log",
}

## Sets the highest validator level used by `fq lint`.
enum FqValidationLevel[String] {
    ## Runs low-level validators.
    Low = "low",

    ## Runs low- and medium-level validators.
    Medium = "medium",

    ## Runs low-, medium-, and high-level validators.
    High = "high",
}

## Identifies an `fq lint` validator that callers may disable.
enum FqValidator {
    ## Low-level check requiring the plus line to begin with `+`.
    S001,

    ## Medium-level check allowing only case-insensitive `ACGTN` sequence characters.
    S002,

    ## High-level check requiring the record name to begin with `@`.
    S003,

    ## Low-level check requiring nonempty name, sequence, plus, and quality lines.
    S004,

    ## High-level check requiring equal sequence and quality lengths.
    S005,

    ## Medium-level check allowing only printable ASCII quality characters from `!` to `~`.
    S006,

    ## High-level check rejecting duplicate read-one names in paired input.
    S007,

    ## Medium-level check requiring paired records to have the same normalized name.
    P001,
}

## Validates single or paired FASTQ inputs with `fq lint`.
task lint {
    input {
        ## Read-one FASTQ input.
        env File r1_fastq

        ## Optional read-two FASTQ input.
        File? r2_fastq

        ## Whether `fq lint` stops at the first error or logs all errors.
        FqLintMode lint_mode = FqLintMode.Panic

        ## Highest single-read validator level to run.
        FqValidationLevel single_read_validation_level = FqValidationLevel.High

        ## Highest paired-read validator level to run.
        FqValidationLevel paired_read_validation_level = FqValidationLevel.High

        ## Validator codes to disable.
        Array[FqValidator] disabled_validators = []

        ## Optional upstream record-name separator.
        String? record_definition_separator

        ## Validation log filename.
        env String report_name = "fq-lint.log"

        ## Minimum CPU cores.
        Int cpu = 1

        ## Minimum memory with units.
        String memory = "1 GiB"

        ## Minimum disk space in GiB.
        Int disk_gib = 10

        ## Digest-pinned `fq` `0.12.0` BioContainers image.
        String container = "quay.io/biocontainers/fq:0.12.0--h9ee0642_0@sha256:74b59572f1d05b4829b45b599ee04311c8b3acec510f3cfb879f23b4bbd2090b"

        ## Trusted arguments absent from the pinned `fq` CLI.
        Array[String] extra_args = []
    }

    # CLI token for `lint_mode`.
    env String lint_mode_value = value(lint_mode)

    # CLI token for `single_read_validation_level`.
    env String single_read_validation_level_value = value(single_read_validation_level)

    # CLI token for `paired_read_validation_level`.
    env String paired_read_validation_level_value = value(paired_read_validation_level)

    # Optional read-two path or an empty string.
    env String r2_fastq_value = select_first([
        r2_fastq,
        "",
    ])

    # Optional record-definition separator or an empty string.
    env String separator_value = select_first([
        record_definition_separator,
        "",
    ])

    # File containing one disabled validator code per line.
    env File disabled_validators_file = write_lines(disabled_validators)

    # File preserving trusted extra-argument boundaries.
    env File extra_args_file = write_lines(extra_args)

    command <<<
        # shellcheck disable=SC2154
        set -euo pipefail
        export NO_COLOR=1

        mapfile -t disabled_validators < "$disabled_validators_file"
        mapfile -t extra_args < "$extra_args_file"

        option_args=(
            --lint-mode "$lint_mode_value"
            --single-read-validation-level "$single_read_validation_level_value"
            --paired-read-validation-level "$paired_read_validation_level_value"
        )
        for validator in "${disabled_validators[@]}"; do
            option_args+=(--disable-validator "$validator")
        done
        if [[ -n "$separator_value" ]]; then
            option_args+=(--record-definition-separator "$separator_value")
        fi

        positional_args=("$r1_fastq")
        if [[ -n "$r2_fastq_value" ]]; then
            positional_args+=("$r2_fastq_value")
        fi

        status=0
        if fq lint \
            "${option_args[@]}" \
            "${extra_args[@]}" \
            "${positional_args[@]}" \
            > "$report_name"
        then
            :
        else
            status=$?
        fi

        cat "$report_name"
        exit "$status"
    >>>

    output {
        ## Validation log from a successful `fq lint` run.
        File validation_report = report_name
    }

    requirements {
        container: container
        cpu: cpu
        memory: memory
        disks: disk_gib
    }
}
