## Wraps `fq subsample` to retain FASTQ records by probability or exact count.
## Exports the `subsample` task.
version 1.4

## Subsamples single or paired FASTQ inputs with `fq subsample`.
task subsample {
    input {
        ## Read-one FASTQ input.
        env File r1_fastq

        ## Optional read-two FASTQ input.
        File? r2_fastq

        ## Optional probability strictly between `0.0` and `1.0`.
        Float? probability

        ## Optional exact number of records to retain.
        Int? record_count

        ## Optional random-number seed.
        Int? seed

        ## Read-one output filename; `.gz` enables compression.
        env String r1_output_name = "subsampled_R1.fastq.gz"

        ## Optional read-two output filename; `.gz` enables compression.
        String? r2_output_name

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

    # Optional read-two path or an empty string.
    env String r2_fastq_value = if defined(r2_fastq)
        then "~{select_first([
            r2_fastq,
        ])}"
        else ""

    # Optional sampling probability or an empty string.
    env String probability_value = if defined(probability)
        then "~{select_first([
            probability,
        ])}"
        else ""

    # Optional record count or an empty string.
    env String record_count_value = if defined(record_count)
        then "~{select_first([
            record_count,
        ])}"
        else ""

    # Optional random-number seed or an empty string.
    env String seed_value = if defined(seed)
        then "~{select_first([
            seed,
        ])}"
        else ""

    # Optional read-two output filename or an empty string.
    env String r2_output_name_value = select_first([
        r2_output_name,
        "",
    ])

    # File preserving trusted extra-argument boundaries.
    env File extra_args_file = write_lines(extra_args)

    command <<<
        # shellcheck disable=SC2154
        set -euo pipefail
        export NO_COLOR=1

        mapfile -t extra_args < "$extra_args_file"

        quantity_count=0
        quantity_args=()
        if [[ -n "$probability_value" ]]; then
            quantity_args+=(--probability "$probability_value")
            ((quantity_count += 1))
        fi
        if [[ -n "$record_count_value" ]]; then
            quantity_args+=(--record-count "$record_count_value")
            ((quantity_count += 1))
        fi
        if (( quantity_count != 1 )); then
            printf '%s\n' "exactly one of \`probability\` or \`record_count\` is required" >&2
            exit 2
        fi

        r2_pair_count=0
        if [[ -n "$r2_fastq_value" ]]; then
            ((r2_pair_count += 1))
        fi
        if [[ -n "$r2_output_name_value" ]]; then
            ((r2_pair_count += 1))
        fi
        if (( r2_pair_count == 1 )); then
            printf '%s\n' "\`r2_fastq\` and \`r2_output_name\` must be provided together" >&2
            exit 2
        fi

        option_args=("${quantity_args[@]}" --r1-dst "$r1_output_name")
        if [[ -n "$seed_value" ]]; then
            option_args+=(--seed "$seed_value")
        fi
        if [[ -n "$r2_output_name_value" ]]; then
            option_args+=(--r2-dst "$r2_output_name_value")
        fi

        positional_args=("$r1_fastq")
        if [[ -n "$r2_fastq_value" ]]; then
            positional_args+=("$r2_fastq_value")
        fi

        fq subsample \
            "${option_args[@]}" \
            "${extra_args[@]}" \
            "${positional_args[@]}"
    >>>

    output {
        ## Subsampled read-one FASTQ.
        File r1_subsampled_fastq = r1_output_name

        ## Optional subsampled read-two FASTQ.
        File? r2_subsampled_fastq = r2_output_name
    }

    requirements {
        container: container
        cpu: cpu
        memory: memory
        disks: disk_gib
    }
}
