## Wraps `fq generate` to create seeded synthetic paired FASTQ data.
## Exports the `generate` task.
version 1.4

## Generates a random paired FASTQ dataset with `fq generate`.
task generate {
    input {
        ## Optional random-number seed.
        Int? seed

        ## Number of read pairs to generate.
        Int record_count = 10000

        ## Bases per generated read.
        Int read_length = 101

        ## Read-one output filename; `.gz` enables compression.
        env String r1_output_name = "generated_R1.fastq.gz"

        ## Read-two output filename; `.gz` enables compression.
        env String r2_output_name = "generated_R2.fastq.gz"

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

    # Optional random-number seed or an empty string.
    env String seed_value = if defined(seed)
        then "~{select_first([
            seed,
        ])}"
        else ""

    # Record count serialized for `fq generate`.
    env String record_count_value = "~{record_count}"

    # Read length serialized for `fq generate`.
    env String read_length_value = "~{read_length}"

    # File preserving trusted extra-argument boundaries.
    env File extra_args_file = write_lines(extra_args)

    command <<<
        # shellcheck disable=SC2154
        set -euo pipefail
        export NO_COLOR=1

        mapfile -t extra_args < "$extra_args_file"

        option_args=(
            --record-count "$record_count_value"
            --read-length "$read_length_value"
        )
        if [[ -n "$seed_value" ]]; then
            option_args+=(--seed "$seed_value")
        fi

        fq generate \
            "${option_args[@]}" \
            "${extra_args[@]}" \
            "$r1_output_name" \
            "$r2_output_name"
    >>>

    output {
        ## Generated read-one FASTQ.
        File r1_fastq = r1_output_name

        ## Generated read-two FASTQ.
        File r2_fastq = r2_output_name
    }

    requirements {
        container: container
        cpu: cpu
        memory: memory
        disks: disk_gib
    }
}
