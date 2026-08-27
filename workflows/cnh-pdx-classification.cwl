cwlVersion: v1.2
class: Workflow
id: cnh-pdx-xenome-classify
label: CNH PDX Xenome Classify
doc: |
    # Children's National PDX Xenome Classify Workflow

    ## Introduction

    This workflow uses fastp to detect adapters from raw reads, and if present removes them using cutadapt.
    Then the workflow uses xenome classify to seprate reads from a host and graft genome.

    The initial steps are copied from the RNA-Seq Workflow that can be found at https://github.com/childrens-bti/kf-rnaseq-workflow-cnh

    Xenome documentation can be found at https://github.com/data61/gossamer/blob/master/docs/xenome.md

requirements:
- class: ScatterFeatureRequirement
- class: MultipleInputFeatureRequirement
- class: SubworkflowFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement

inputs:
  # Xenome specific
  xenome_index: {type: File, doc: "Xenome index made form host and graft fasta",
    "sbg:suggestedValue": {class: File, path: 6a736b9b0493ff749a1b06fb, name: GRCh38_graft_GRCm39.vM38_host.tgz}}
  idx_prefix: {type: "string?", doc: "String prefix of index files when decompressed", default: "GRCh38_graft_GRCm39.vM38_host"}
  host_name: {type: "string?", doc: "name to use describing model organism receiving graft", default: "mouse"}
  graft_name: {type: "string?", doc: "name to use describing organism that grafted tissue came from", default: "human"}

  # main inputs
  sample_name: {type: 'string', doc: "Sample ID of the input reads"}
  output_basename: {type: 'string', doc: "String to use as basename for outputs"}
  input_pe_reads: {type: 'File[]?', doc: "List of R1 paired end FASTQ files to process"}
  input_pe_mates: {type: 'File[]?', doc: "List of R2 paired end FASTQ files to process"}
  input_se_reads: {type: 'File[]?', doc: "List of single end FASTQ files to process"}
  input_pe_rg_strs: {type: 'string[]?', doc: "List of RG strings to use in PE processing"}
  input_se_rg_strs: {type: 'string[]?', doc: "List of RG strings to use in SE processing"}
  keep_ambiguous_fastqs: {type: 'boolean?', doc: "Keep reads classified as ambiguous", default: false}
  keep_both_fastqs: {type: 'boolean?', doc: "Keep reads classified as both", default: false}
  keep_neither_fastqs: {type: 'boolean?', doc: "Keep reads classified as neither", default: false}
  is_paired_end: {type: 'boolean?', doc: "For alignment files inputs, are the reads paired end?"}
  r1_adapter: {type: 'string?', doc: "!Warning this will be applied to all R1 reads (PE, SE, and reads from alignment files)! If you
      have multiple adapters, manually trim your reads before input. If they share the same adapter, supply adapter here"}
  r2_adapter: {type: 'string?', doc: "!Warning this will be applied to all R2 reads (PE and reads from alignment files)! If you have
      multiple adapters, manually trim your reads before input. If they share the same adapter, supply adapter here"}
  min_len: {type: 'int?', doc: "If trimming adapters, what is the minimum length reads should have post trimming"}
  quality_base: {type: 'int?', doc: "Phred scale used for quality scores of the reads"}
  quality_cutoff: {type: 'int[]?', doc: "Quality trim cutoff, see https://cutadapt.readthedocs.io/en/v3.4/guide.html#quality-trimming
      for how 5' 3' is handled"}
  samtools_fastq_cores: {type: 'int?', doc: "Num cores for align2fastq conversion, if input is an alignment file", default: 16}
  cores: {type: "int?", doc: "Num cores to use", default: 8}
  ram: {type: "int?", doc: "Mem to use in GB", default: 8}

outputs:
  host_fastqs: {type: 'File[]', outputSource: compress_host_reads/output_archives, doc: "Filtered reads coming from host organism."}
  graft_fastqs: {type: 'File[]', outputSource: compress_graft_reads/output_archives, doc: "Filtered reads coming from graft organism."}
  ambiguous_fastqs: {type: 'File[]?', outputSource: compress_ambiguous_reads/output_archives, doc: "Filtered reads classified as ambiguous."}
  both_fastqs: {type: 'File[]?', outputSource: compress_both_reads/output_archives, doc: "Filtered reads classified as both."}
  neither_fastqs: {type: 'File[]?', outputSource: compress_neither_reads/output_archives, doc: "Filtered reads classified as neither."}
  cutadapt_stats: {type: 'File[]?', outputSource: preprocess_reads/cutadapt_stats, doc: "Cutadapt stats output, only if adapter is
      supplied."}
  fastp_adapter_json: {type: 'File[]?', outputSource: preprocess_reads/fastp_json, doc: "fastp adapter detection JSON reports (one per
      processed reads record, for both SE and PE inputs). Contains detected adapter sequences and QC metrics."}
  fastp_adapter_html: {type: 'File[]?', outputSource: preprocess_reads/fastp_html, doc: "fastp adapter detection HTML reports (one per
      processed reads record, for both SE and PE inputs)."}
  xenome_classify_stats: {type: 'File', outputSource: xenome_classify/output_stats, "Output stats file from Xenome Classify"}

steps:
  lists_to_reads_records:
    run: https://raw.githubusercontent.com/childrens-bti/kf-rnaseq-workflow-cnh/v1.2.4/subworkflows/lists_to_reads_records.cwl
    in:
      input_pe_reads: input_pe_reads
      input_pe_mates: input_pe_mates
      input_se_reads: input_se_reads
      input_pe_rg_strs: input_pe_rg_strs
      input_se_rg_strs: input_se_rg_strs
      is_paired_end: is_paired_end
      r1_adapter: r1_adapter
      r2_adapter: r2_adapter
      min_len: min_len
      quality_base: quality_base
      quality_cutoff: quality_cutoff
    out: [am_reads_records, pe_fq_reads_records, se_fq_reads_records]
  basename_picker:
    run: https://raw.githubusercontent.com/childrens-bti/kf-rnaseq-workflow-cnh/v1.2.4/tools/basename_picker.cwl
    in:
      root_name:
        source: [lists_to_reads_records/am_reads_records, lists_to_reads_records/pe_fq_reads_records, lists_to_reads_records/se_fq_reads_records]
        linkMerge: merge_flattened
        pickValue: all_non_null
        valueFrom: $(self.map(function(e) { return e.reads1.basename.split('.')[0] }).join("-"))
      output_basename: output_basename
      sample_name: sample_name
    out: [outname, outsample, outrg]
  preprocess_reads:
    run: https://raw.githubusercontent.com/childrens-bti/kf-rnaseq-workflow-cnh/v1.2.4/subworkflows/preprocess_reads.cwl
    scatter: [reads_record]
    in:
      reads_record:
        source: [lists_to_reads_records/am_reads_records, lists_to_reads_records/pe_fq_reads_records, lists_to_reads_records/se_fq_reads_records]
        linkMerge: merge_flattened
        pickValue: all_non_null
      sample_name: sample_name
      output_basename: output_basename
      samtools_fastq_cores: samtools_fastq_cores
    out: [processed_reads_record, cutadapt_stats, fastp_json, fastp_html]
  extract_reads_from_record:
    run: ../tools/extract_reads_from_record.cwl
    in:
      reads_records: preprocess_reads/processed_reads_record
      outFileNamePrefix: basename_picker/outname
    out: [reads]
  xenome_classify:
    run: ../tools/xenome_classify.cwl
    in:
      xenome_index: xenome_index
      host_name: host_name
      graft_name: graft_name
      cores: cores
      ram: ram
      idx_prefix: idx_prefix
      is_paired_end: is_paired_end
      fastq_reads: extract_reads_from_record/reads
      output_basename: basename_picker/outname
    out: [graft_fastqs, host_fastqs, ambiguous_fastqs, both_fastqs, neither_fastqs, output_stats]
  compress_host_reads:
    run: ../tools/sbg_compressor.cwl
    in:
      input_files: xenome_classify/host_fastqs
      process: cores
      output_format:
        valueFrom: |
          ${
            return "GZ"
          }
    out: [output_archives]
  compress_ambiguous_reads:
    run: ../tools/sbg_compressor.cwl
    when: $(inputs.run_if == true)
    in:
      run_if: keep_ambiguous_fastqs
      input_files: xenome_classify/ambiguous_fastqs
      process: cores
      output_format:
        valueFrom: |
          ${
            return "GZ"
          }
    out: [output_archives]
  compress_both_reads:
    run: ../tools/sbg_compressor.cwl
    when: $(inputs.run_if == true)
    in:
      run_if: keep_both_fastqs
      input_files: xenome_classify/both_fastqs
      process: cores
      output_format:
        valueFrom: |
          ${
            return "GZ"
          }
    out: [output_archives]
  compress_neither_reads:
    run: ../tools/sbg_compressor.cwl
    when: $(inputs.run_if == true)
    in:
      run_if: keep_neither_fastqs
      input_files: xenome_classify/neither_fastqs
      process: cores
      output_format:
        valueFrom: |
          ${
            return "GZ"
          }
    out: [output_archives]
  compress_graft_reads:
    run: ../tools/sbg_compressor.cwl
    in:
      input_files: xenome_classify/graft_fastqs
      process: cores
      output_format:
        valueFrom: |
          ${
            return "GZ"
          }
    out: [output_archives]

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: 'sbg:maxNumberOfParallelInstances'
  value: 3
sbg:license: Apache License 2.0
sbg:links:
- id: 'https://github.com/childrens-bti/d3b-ot-pdx-tumor-only-processing-cnh/releases/tag/v1.0.0'
  label: github-release
