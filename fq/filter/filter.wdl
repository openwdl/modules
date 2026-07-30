## Wraps `fq filter` to retain aligned FASTQ records by name or sequence pattern.
## Exports the `filter` task.
version 1.4

## Filters aligned FASTQ inputs with `fq filter`.
task filter {
    input {
        ## Aligned FASTQ source files.
        Array[File] sources

        ## Output filenames aligned with `sources`.
        Array[String] output_names

        ## Optional file containing bare record identifiers to retain.
        File? names

        ## Optional regular expression for sequences to retain.
        String? sequence_pattern

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

    # File containing one localized source path per line.
    env File sources_file = write_lines(sources)

    # File containing one output filename per line.
    env File output_names_file = write_lines(output_names)

    # Optional bare-ID allowlist path or an empty string.
    env String names_value = if defined(names)
        then "~{select_first([
            names,
        ])}"
        else ""

    # Optional sequence regular expression or an empty string.
    env String sequence_pattern_value = select_first([
        sequence_pattern,
        "",
    ])

    # File preserving trusted extra-argument boundaries.
    env File extra_args_file = write_lines(extra_args)

    command <<<
        # shellcheck disable=SC2154
        set -euo pipefail
        export NO_COLOR=1

        mapfile -t source_args < "$sources_file"
        mapfile -t output_name_args < "$output_names_file"
        mapfile -t extra_args < "$extra_args_file"

        if (( ${#source_args[@]} == 0 )); then
            printf '%s\n' "\`filter\` requires at least one \`source\`" >&2
            exit 2
        fi

        if (( ${#source_args[@]} != ${#output_name_args[@]} )); then
            printf '%s\n' "\`sources\` and \`output_names\` must have equal lengths" >&2
            exit 2
        fi

        if [[ -n "$names_value" && -n "$sequence_pattern_value" ]]; then
            printf '%s\n' "\`names\` and \`sequence_pattern\` are mutually exclusive" >&2
            exit 2
        fi

        filter_args=()
        if [[ -n "$names_value" ]]; then
            filter_args+=(--names "$names_value")
        fi
        if [[ -n "$sequence_pattern_value" ]]; then
            filter_args+=(--sequence-pattern "$sequence_pattern_value")
        fi

        destination_args=()
        for output_name in "${output_name_args[@]}"; do
            destination_args+=(--dsts "$output_name")
        done

        fq filter \
            "${filter_args[@]}" \
            "${destination_args[@]}" \
            "${extra_args[@]}" \
            "${source_args[@]}"
    >>>

    output {
        ## Filtered FASTQ outputs in input order.
        Array[File] filtered_fastqs = output_names
    }

    requirements {
        container: container
        cpu: cpu
        memory: memory
        disks: disk_gib
    }
}
