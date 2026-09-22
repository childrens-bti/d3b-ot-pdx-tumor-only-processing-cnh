cwlVersion: v1.2
class: ExpressionTool
id: extract_reads_from_record

requirements:
  InlineJavascriptRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: https://raw.githubusercontent.com/childrens-bti/kf-rnaseq-workflow-cnh/v1.2.4/schema/reads_record_type.yml

inputs:
  reads_records:
    type:
      type: array
      items: https://raw.githubusercontent.com/childrens-bti/kf-rnaseq-workflow-cnh/v1.2.4/schema/reads_record_type.yml#reads_record
  outFileNamePrefix: string

outputs:
  reads: File[]

expression: >-
  ${
    return {
      reads: inputs.reads_records.reduce(function(files, record) {
        files.push(record.reads1);
        if (record.reads2 != null) {
          files.push(record.reads2);
        }
        return files;
      }, [])
    };
  }
