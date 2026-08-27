cwlVersion: v1.0
class: CommandLineTool
label: SBG Compressor CWL1.0
doc: |-
  Compress input files or folders.

  **SBG Compressor** performs archiving (and/or compression) of files and folders provided on the input. The format of the output can be selected. 
  	Supported formats are:
  - TAR
  - TAR.GZ 
  - TAR.BZ2
  -  GZ
  - BZ2
  - ZIP

  For TAR, TAR.GZ, TAR.BZ2 and ZIP formats, a single archive will be created on the output. For GZ and BZ2 formats, one archive per file will be created.

  *A list of all inputs and parameters with corresponding descriptions can be found at the bottom of this page.*

  ###Common use cases

  This tool is used to create archives of files and folders. It can be used in workflows to compress and pass on containing files or folders.

  ###Common Issues and Important Notes

  GZ and BZ2 formats are not applicable to folders and can only be used to compress files.  

  If an already zipped file is passed on the input, along with another non-compressed file, and ZIP is selected as the output format, more than one file will be created on the output. It should be noted that if the zipped file is passed as the first file on the input the tool will throw an error.  

  If two input files have the same **Sample ID** metadata field and the selected output format is TAR, TAR.GZ, TAR.BZ2 or ZIP, the output name of the compressed files will be the same as their **Sample ID**. However if they have different **Sample ID**'s and the output name is not chosen, the default value will be "output_archives". 

  The tool takes all hard linked files from the current working dir and compresses them.

  ###Performance Benchmarking

  | Output Type 	| Input Size 	| Duration 	| Cost 	| Instance (AWS) 	|
  |-	|-	|-	|-	|-	|
  | TAR.GZ 	| 150MB 	| 2min 	| $0.01 	| c4.2xlarge 	|
  | TAR.GZ 	| 1GB 	| 2min 	| $0.01 	| c4.2xlarge 	|
  | TAR.GZ 	| 25GB 	| 27min 	| $0.18 	| c4.2xlarge 	|
  | TAR.GZ 	| 150GB 	| 2h,45min 	| $1.1 	| c4.2xlarge 	|
  | TAR.BZ2 	| 150MB 	| 1min 	| $0.01 	| c4.2xlarge 	|
  | TAR.BZ2 	| 1GB 	| 2min 	| $0.01 	| c4.2xlarge 	|
  | TAR.BZ2 	| 25GB 	| 46min 	| $0.30 	| c4.2xlarge 	|
  | TAR.BZ2 	| 150GB 	| 4h,57min 	| $2.01 	| c4.2xlarge 	|
  | TAR 	| 150MB 	| 1min 	| $0.01 	| c4.2xlarge 	|
  | TAR 	| 1GB 	| 2min 	| $0.01 	| c4.2xlarge 	|
  | TAR 	| 25GB 	| 16min 	| $0.1 	| c4.2xlarge 	|
  | TAR 	| 150GB 	| 1h,35min 	| $0.65 	| c4.2xlarge 	|
  | ZIP 	| 150MB 	| 1min 	| $0.01 	| c4.2xlarge 	|
  | ZIP 	| 1GB 	| 3min 	| $0.02 	| c4.2xlarge 	|
  | ZIP 	| 25GB 	| 28min 	| $0.2 	| c4.2xlarge 	|
  | ZIP 	| 150GB 	| 2h,42min 	| $1.1 	| c4.2xlarge 	|
  | GZ 	| 150MB 	| 1min 	| $0.01 	| c4.2xlarge 	|
  | GZ 	| 1GB 	| 2min 	| $0.01 	| c4.2xlarge 	|
  | GZ 	| 25GB 	| 17min 	| $0.12 	| c4.2xlarge 	|
  | GZ 	| 150GB 	| 1h,36min 	| $0.65 	| c4.2xlarge 	|
  | BZ2 	| 150MB 	| 1min 	| $0.01 	| c4.2xlarge 	|
  | BZ2 	| 1GB 	| 2min 	| $0.01 	| c4.2xlarge 	|
  | BZ2 	| 25GB 	| 25min 	| $0.17 	| c4.2xlarge 	|
  | BZ2 	| 150GB 	| 2h,36min 	| $1.05 	| c4.2xlarge 	|

  *Cost can be significantly reduced by using spot instances. Visit the [Knowledge Center](https://docs.sevenbridges.com/docs/about-spot-instances) for more details.*
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: 1
  ramMin: 1000
- class: DockerRequirement
  dockerPull: images.sbgenomics.com/aleksa_soldatic/sbg_compressor_cwl1:1.0
- class: InitialWorkDirRequirement
  listing:
  - entryname: sbg_compressor.py
    writable: false
    entry: |-
      #!/usr/bin/python
      """
      Usage:
      	sbg_compressor.py --output_format STR [options]

      Description:
      	SBG Compressor performs the archiving(and/or compression) of the files provided on the input. The format of the output can be selected.
      	Supported formats are:
      		1. TAR
      		2. TAR.GZ
      		3. TAR.BZ2
      		4. GZ
      		5. BZ2
      		6. ZIP
      	For formats TAR, TAR.GZ, TAR.BAZ2 and ZIP, single archive will be created on the output. For formats GZ and BZ2, one archive per file will be created.
          The tool takes all hard links files from current working dir and compresses them.

      Options:
      	-h, --help					    Show this screen.
          -v, --version           	    Show version.
          -f, --output_format STR         Format of the output archive.
          -o, --output_name STR         	Base name of the output archive.  [Default: output_archive]
          -p, --process INT               A number of processes used for parallel compression. Only valid for GZ and BZ2 (also TAR.GZ, TAR.BZ2) types of compression.

      """

      import sys
      from docopt import docopt
      import os
      import shlex

      def main(argv):
          args = docopt(__doc__, version='v1.0')
          output_format = args["--output_format"]
          output_name = args["--output_name"]
          procs = args["--process"]

          suffix = "." + output_format.lower()
          i = 0
          new_output_name = output_name
          while os.path.isfile(new_output_name + suffix):
              i += 1
              new_output_name = output_name + '_' + str(i)
          output_name = new_output_name + suffix

          find = ' find . -type f -links +1; find ./ -type d -links +1 -mindepth 1; '

          if procs and procs.isdigit():
              pigz_p_arg = ' -p ' + procs
              pbzip2_p_arg = ' -p' + procs
          else:
              pigz_p_arg = ''
              pbzip2_p_arg = ''

          if output_format == "TAR":
              command = 'tar cvf ' + os.path.normpath(shlex.quote(output_name)) + ' $("$")(' + find + ')'
          elif output_format == "TAR.GZ":
              command = 'tar cf - $("$")(' + find + ') | pigz' + pigz_p_arg + ' > ' + os.path.normpath(shlex.quote(output_name))
          elif output_format == "TAR.BZ2":
              command = 'tar cf - $("$")(' + find + ') | pbzip2' + pbzip2_p_arg + ' > ' + os.path.normpath(shlex.quote(output_name))
          elif output_format == "ZIP":
              command = 'zip -r ' + os.path.normpath(shlex.quote(output_name)) + ' $("$")(' + find + ')'
          elif output_format == "GZ":
              command = 'pigz -k' + pigz_p_arg + ' -f ' + ' $("$")(' + find + ')'
          elif output_format == "BZ2":
              command = 'pbzip2 -k -z' + pbzip2_p_arg + ' -f ' + ' $("$")(' + find + ')'
          else:
              print ("Format not supported")
              sys.exit()

          print (command)
          os.system(command)


      if __name__ == "__main__":
          main(sys.argv[1:])
  - writable: false
    entry: $(inputs.input_files)
  - writable: false
    entry: $(inputs.input_folder)
- class: InlineJavascriptRequirement
  expressionLib:
  - |2-

    var setMetadata = function(file, metadata) {
        if (!('metadata' in file)) {
            file['metadata'] = {}
        }
        for (var key in metadata) {
            file['metadata'][key] = metadata[key];
        }
        return file
    };
    var inheritMetadata = function(o1, o2) {
        var commonMetadata = {};
        if (!o2) {
            return o1;
        };
        if (!Array.isArray(o2)) {
            o2 = [o2]
        }
        for (var i = 0; i < o2.length; i++) {
            var example = o2[i]['metadata'];
            for (var key in example) {
                if (i == 0)
                    commonMetadata[key] = example[key];
                else {
                    if (!(commonMetadata[key] == example[key])) {
                        delete commonMetadata[key]
                    }
                }
            }
            for (var key in commonMetadata) {
                if (!(key in example)) {
                    delete commonMetadata[key]
                }
            }
        }
        if (!Array.isArray(o1)) {
            o1 = setMetadata(o1, commonMetadata)
        } else {
            for (var i = 0; i < o1.length; i++) {
                o1[i] = setMetadata(o1[i], commonMetadata)
            }
        }
        return o1;
    };

inputs:
- id: input_files
  label: Input files
  doc: The input files to be archived.
  type: File[]?
- id: output_format
  label: Output format
  doc: "Format of the output archive.\nGZ and BZ2 not applicable to folders."
  type:
    name: output_format
    type: enum
    symbols:
    - TAR
    - TAR.GZ
    - TAR.BZ2
    - ZIP
    - GZ
    - BZ2
  inputBinding:
    prefix: --output_format
    position: 0
    shellQuote: false
  sbg:altPrefix: -f
- id: output_name
  label: Output name
  doc: |-
    Base name of the output archive. This parameter is not applicable for the GZ and BZ2 file formats.
  type: string?
  sbg:altPrefix: -o
- id: run_if
  label: Run condition
  doc: Workflow-only control input used to expose a conditional step input.
  type: boolean?
- id: process
  label: Number of processes
  doc: |-
    A number of processes used for parallel compression. Only valid for GZ and BZ2 (also TAR.GZ, TAR.BZ2) types of compression.
  type: int?
  inputBinding:
    prefix: --process
    position: 0
    shellQuote: false
  sbg:altPrefix: -p
- id: input_folder
  label: Input folders
  doc: The input folders to be archived.
  type: Directory[]?

outputs:
- id: output_archives
  label: Output archives
  doc: Newly created archives from the input files.
  type: File[]
  outputBinding:
    glob: |-
      ${
          var format = inputs.output_format.toLowerCase()
          return "*." + format
      }
    outputEval: |+
      ${ 
              function flatten(files){
              var a = []
              for(var i=0;i<files.length;i++){
                  if(files[i]){
                      if(files[i].constructor == Array) {
                          a = a.concat(flatten(files[i]))
                      } else {
                          a = a.concat(files[i])
                      }
                  }
              }      
            
              var b = a.filter(function (el) {
                  return el != null
              })      
              return b
            
          }    
          
          var input_files = [].concat(inputs.input_files)
          var input_files = flatten(input_files)
          
          if (self && input_files) {
              for (var i = 0; i < self.length; i++) {
                  var output_name = self[i].basename
                  if (output_name){
                      var input_name = output_name.split('.').slice(0, -1).join('.')
                      for (var j = 0; j < input_files.length; j++) {
                          if (input_files[j].basename == input_name) self[i].metadata = input_files[j].metadata
                          else inheritMetadata(self, input_files)
                      }
                  }
              }
          }
          return self
      }


  sbg:fileTypes: TAR, TAR.GZ, TAR.BZ2, GZ, BZ2, ZIP

baseCommand:
- python3.7
- sbg_compressor.py
arguments:
- prefix: -o
  position: 100
  valueFrom: |-
    ${  
        function flatten(files){
            var a = []
            for(var i=0;i<files.length;i++){
                if(files[i]){
                    if(files[i].constructor == Array) {
                        a = a.concat(flatten(files[i]))
                    } else {
                        a = a.concat(files[i])
                    }
                }
            }      
          
            var b = a.filter(function (el) {
                return el != null
            })      
            return b
          
        }    
        
        var input_files = [].concat(inputs.input_files)
        var input_files = flatten(input_files)
        
        if (!inputs.output_name) {

            if (inputs.input_folder) {
                var input_folder = [].concat(inputs.input_folder)[0]
                return input_folder.basename
            } 
            else if (input_files.length > 0) {

                if (!input_files[0].metadata) {
                    return input_files[0].nameroot
                }
                else if (!input_files[0].metadata['sample_id']) {
                    return input_files[0].nameroot
                } 
                else {
                    var flag = 'True'
                    var sample_id = input_files[0].metadata['sample_id']
                    // check if sample_id is the same for all files
                    for (var i = 0; i < input_files.length; i++) {
                        if ((input_files[i].metadata) && (input_files[i].metadata['sample_id']) && 
                            (input_files[i].metadata['sample_id'] !== sample_id)) {
                            flag = 'False'  // detected file with different sample_id
                        }
                    } 
            
                    if (flag == 'True') {
                        // sample_id is the same for all input files
                        var filebase = input_files[0].metadata['sample_id']
                    } 
                    else {
                        var filebase = "output_archives"
                    }
                    return filebase
                } // end else sample_id exists
            } // else if (input_files.length)
            else { 
               throw 'Input files or folder must be defined!'
            }
        } // end if (!inputs.output_name) 
        else {
            return inputs.output_name
        }
    }
  shellQuote: false
id: |-
  https://cavatica-api.sbgenomics.com/v2/apps/admin/sbg-public-data/sbg-compressor-cwl1-0/10/raw/
sbg:appVersion:
- v1.0
sbg:categories:
- Other
sbg:cmdPreview: |-
  python3.7 sbg_compressor.py --output_format TAR --process 1 -o output_name-string-value
sbg:content_hash: a797896dc3fce65c8b48c97e2c077404c7897c1a23748f361da856173b44debea
sbg:contributors:
- admin
sbg:createdBy: admin
sbg:createdOn: 1591664122
sbg:expand_workflow: false
sbg:homepage: https://igor.sbgenomics.com/
sbg:id: admin/sbg-public-data/sbg-compressor-cwl1-0/10
sbg:image_url:
sbg:latestRevision: 10
sbg:license: Apache License 2.0
sbg:modifiedBy: admin
sbg:modifiedOn: 1615275697
sbg:project: admin/sbg-public-data
sbg:projectName: SBG Public Data
sbg:publisher: sbg
sbg:revision: 10
sbg:revisionNotes: app info modified
sbg:revisionsInfo:
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1591664122
  sbg:revision: 0
  sbg:revisionNotes: Copy of sevenbridges/sbgtools-cwl1-0-demo/sbg-compressor-1-0/10
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1591664305
  sbg:revision: 1
  sbg:revisionNotes: Initial
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1592404704
  sbg:revision: 2
  sbg:revisionNotes: latest version from dev
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1593165168
  sbg:revision: 3
  sbg:revisionNotes: files inside the folder - fixed
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1599047738
  sbg:revision: 4
  sbg:revisionNotes: no longer archives log files
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1599047738
  sbg:revision: 5
  sbg:revisionNotes: output file renamed
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1615275696
  sbg:revision: 6
  sbg:revisionNotes: fix flatten tmp
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1615275696
  sbg:revision: 7
  sbg:revisionNotes: check if metadata exists
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1615275697
  sbg:revision: 8
  sbg:revisionNotes: fix brackets
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1615275697
  sbg:revision: 9
  sbg:revisionNotes: Fix inherit metadata
- sbg:modifiedBy: admin
  sbg:modifiedOn: 1615275697
  sbg:revision: 10
  sbg:revisionNotes: app info modified
sbg:sbgMaintained: false
sbg:toolAuthor: Marko Petkovic, Seven Bridges Genomics
sbg:toolkit: SBGTools
sbg:toolkitVersion: v1.0
sbg:validationErrors: []
