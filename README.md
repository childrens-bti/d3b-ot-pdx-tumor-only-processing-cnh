# CNH PDX Xenome Preprocessing

This repository contains a Common Workflow Language (CWL) pipeline for separating host and graft reads from patient-derived xenograft (PDX) sequencing data with [Xenome](https://github.com/data61/gossamer/blob/master/docs/xenome.md).

The primary workflow is [`workflows/cnh-pdx-classification.cwl`](workflows/cnh-pdx-classification.cwl). It accepts paired-end or single-end FASTQ inputs, preprocesses the reads, classifies them against a combined host/graft Xenome index, and compresses the classification outputs.

## Workflow overview

The workflow performs the following steps:

1. Determines the read layout from the supplied FASTQ inputs and rejects incomplete or mixed layouts.
2. Combines the FASTQ inputs into a common reads-record representation.
3. Detects adapters with fastp and trims reads with cutadapt when applicable.
4. Extracts the processed FASTQ files from the reads records.
5. Classifies reads with Xenome, automatically enabling `--pairs` for paired-end inputs.
6. Compresses the classification FASTQ files with gzip.

Read preprocessing uses CWL tools and subworkflows from version `v1.2.4` of [`childrens-bti/kf-rnaseq-workflow-cnh`](https://github.com/childrens-bti/kf-rnaseq-workflow-cnh).

## Inputs

The workflow supports one of these input layouts per run:

- Paired-end FASTQs through matching `input_pe_reads` (R1) and `input_pe_mates` (R2) arrays.
- Single-end FASTQs through `input_se_reads`.

The principal required configuration is:

- `xenome_index`: A `.tgz` Xenome index containing both host and graft genomes.
- `sample_name`: The sample identifier.
- `output_basename`: The basename used for generated files.

`idx_prefix` defaults to the prefix of the index files inside the extracted archive. `host_name` and `graft_name` default to `mouse` and `human`. Resource controls include `cores`, `ram`, and `samtools_fastq_cores`. Optional read-group, adapter, minimum-length, and quality-trimming inputs are also exposed by the workflow.

Supply exactly one input layout per run: both paired-end arrays (`input_pe_reads` and `input_pe_mates`) or `input_se_reads`. The arrays must contain the same number of files. The workflow rejects mixed or incomplete layouts and derives Xenome's `--pairs` option from the detected layout.

## Outputs

The primary outputs are:

- `host_fastqs`: Compressed FASTQ files classified as host.
- `graft_fastqs`: Compressed FASTQ files classified as graft.
- `ambiguous_fastqs`: Optional compressed FASTQ files classified as ambiguous, enabled by `keep_ambiguous_fastqs`.
- `both_fastqs`: Optional compressed FASTQ files classified as both, enabled by `keep_both_fastqs`.
- `neither_fastqs`: Optional compressed FASTQ files classified as neither, enabled by `keep_neither_fastqs`.
- `xenome_classify_stats`: Xenome classification statistics.
- `cutadapt_stats`: Optional adapter-trimming reports.
- `fastp_adapter_json` and `fastp_adapter_html`: Adapter-detection and QC reports.

## Building a Xenome index

[`tools/xenome_index.cwl`](tools/xenome_index.cwl) builds a combined index from a host FASTA and a graft FASTA and packages it as a `.tgz` file:

```sh
cwltool tools/xenome_index.cwl xenome-index-job.yml
```

The `output_basename` used to build the index should match the workflow's `idx_prefix` when that index is used for classification.

## Running the workflow

A CWL v1.2-compatible runner and a container runtime are required. The workflow also needs network access to resolve its versioned upstream CWL dependencies and access to the referenced container registry.

Validate the workflow with:

```sh
cwltool --validate workflows/cnh-pdx-classification.cwl
```

Run it with a CWL input object containing the required files and parameters:

```sh
cwltool workflows/cnh-pdx-classification.cwl workflow-job.yml
```

The workflow includes Seven Bridges/Cavatica extensions but is otherwise structured as CWL v1.2.

## Repository structure

| Path | Purpose |
| --- | --- |
| [`workflows/cnh-pdx-classification.cwl`](workflows/cnh-pdx-classification.cwl) | Main PDX read preprocessing and Xenome classification workflow |
| [`tools/xenome_index.cwl`](tools/xenome_index.cwl) | Builds and packages a combined host/graft Xenome index |
| [`tools/xenome_classify.cwl`](tools/xenome_classify.cwl) | Runs Xenome classification for single- or paired-end reads |
| [`tools/determine_read_layout.cwl`](tools/determine_read_layout.cwl) | Validates the FASTQ layout and derives the paired-end mode |
| [`tools/extract_reads_from_record.cwl`](tools/extract_reads_from_record.cwl) | Flattens processed reads records into a FASTQ file array |
| [`tools/sbg_compressor.cwl`](tools/sbg_compressor.cwl) | Seven Bridges compression utility used for workflow outputs |
| [`tools/sbg_decompressor.cwl`](tools/sbg_decompressor.cwl) | Legacy Seven Bridges decompression utility |

## License

See [`LICENSE`](LICENSE).
