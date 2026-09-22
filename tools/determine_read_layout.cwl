cwlVersion: v1.2
class: ExpressionTool
id: determine_read_layout
label: Determine FASTQ read layout

requirements:
  - class: InlineJavascriptRequirement

inputs:
  input_pe_reads: {type: 'File[]?'}
  input_pe_mates: {type: 'File[]?'}
  input_se_reads: {type: 'File[]?'}

outputs:
  is_paired_end: boolean

expression: >-
  ${
    var peReads = inputs.input_pe_reads || [];
    var peMates = inputs.input_pe_mates || [];
    var seReads = inputs.input_se_reads || [];
    var hasPeReads = peReads.length > 0;
    var hasPeMates = peMates.length > 0;
    var hasSeReads = seReads.length > 0;

    if (hasPeReads !== hasPeMates) {
      throw new Error("Paired-end inputs must include both input_pe_reads and input_pe_mates.");
    }
    if (hasPeReads && peReads.length !== peMates.length) {
      throw new Error("input_pe_reads and input_pe_mates must contain the same number of files.");
    }
    if (hasPeReads === hasSeReads) {
      throw new Error("Provide exactly one read layout: paired-end or single-end FASTQs.");
    }
    return {is_paired_end: hasPeReads};
  }
