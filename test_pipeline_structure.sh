#!/bin/bash
#SBATCH -p lowmem,normal         # Partition to submit to
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu 7Gb     # Memory in MB
#SBATCH -J smallRNASeq           # job name
#SBATCH -o logs/smallRNASeq.%J.out    # File to which standard out will be written
#SBATCH -e logs/smallRNASeq.%J.err    # File to which standard err will be written

#######################################################################################################################################################
#                                                                                                                                                     #
#                                                       -TO BE RUN IN THE COMMAND LINE-                                                               #
# After fulfilling the file 'config_input_files.txt' and 'sample_sheet.xlsx' (if needed), please run the following command in the bash terminal:      #
#                                                                                                                                                     #
# cd /bicoh/MARGenomics/Pipelines/smallRNASeq (or else the directory where "test_pipeline_structure.sh" is located; usually your project directory,   #
#     but bear in mind that a logs folder must be there!)                                                                                              #
# INPUT=/bicoh/MARGenomics/Pipelines/smallRNASeq/config_inputs_file.txt (please modify the directory to where the onfig_inputs_files.txt is located) #
# sbatch /bicoh/MARGenomics/Pipelines/smallRNASeq/test_pipeline_structure.sh $INPUT                                                                                                            #
#                                                                                                                                                     #
#######################################################################################################################################################

PARAMS=$1

# Steps to perform
MERGE=$(grep merge: $PARAMS | awk '{ print$2 }' | tr -d '\r')
QC=$(grep quality: $PARAMS | awk '{ print$2 }' | tr -d '\r')
LENGTH_EXTRACT=$(grep 01_umi_length_and_extract: $PARAMS | awk '{ print$2 }' | tr -d '\r')
CUTADAPT=$(grep 02_cutadapt: $PARAMS | awk '{ print$2 }' | tr -d '\r')
ALIGNMENT=$(grep 03_alignment: $PARAMS | awk '{ print$2 }' | tr -d '\r')
QUANTIFICATION=$(grep 04_quantification: $PARAMS | awk '{ print$2 }' | tr -d '\r')

# General parameters
PROJECT=$(grep project_directory: $PARAMS | awk '{ print$2 }' | tr -d '\r')
WD=$(grep project_analysis: $PARAMS | awk '{ print$2 }' | tr -d '\r' | sed 's/\r$//')
FUNCTIONSDIR=$(grep functions: $PARAMS | awk '{ print$2 }' | tr -d '\r')
FASTQDIR=$(grep fastq_directory: $PARAMS | awk '{ print$2 }' | tr -d '\r')
BATCH=$(grep batch_num: $PARAMS | awk '{ print$2 }' | tr -d '\r')
BATCH_FOLDER=$(grep batch_folder: $PARAMS | awk '{ print$2 }' | tr -d '\r')
UMI=$(grep UMIs: $PARAMS | awk '{ print$2 }' | tr -d '\r')
FASTQ_SUFFIX=$(grep fastq_suffix: $PARAMS | awk '{ print$2 }')

# Merge parameters
SAMPLE_SHEET=$(grep sample_sheet: $PARAMS | awk '{ print$2 }' | tr -d '\r')
PAIRED=$(grep paired_end: $PARAMS | awk '{ print$2 }' | tr -d '\r')
TOTAL_OUT=$(grep total_output_files: $PARAMS | awk '{ print$2 }' | tr -d '\r')

# UMI variables
ADAPTER=$(grep adapter: $PARAMS | awk '{ print$2 }' | tr -d '\r')

# Alignment variables
GNMIDX=$(grep genome_index: $PARAMS | awk '{ print$2 }' | tr -d '\r')

# Quantification variables
REFGENE=$(grep reference_genome: $PARAMS | awk '{ print$2 }' | tr -d '\r')
ANNOTGENE=$(grep annotation_genome: $PARAMS | awk '{ print$2 }' | tr -d '\r')

FASTQSCREEN_CONFIG=$(grep fastqscreen_config: $PARAMS | awk '{ print$2 }' | tr -d '\r')

cd "$WD"

echo -e "
##########################################################
# PLEASE READ THE BELOW TEXT BEFORE RUNNING THE PIPELINE #
##########################################################

In order to run this smallRNAseq pipeline, please fill in the config_input_files.txt file that can be found in the '/bicoh/MARGenomics/Pipelines/smallRNASeq' path.
All required functions can be found in that path as well. The primary script is this file 'test_pipeline_structure.sh', from which other scripts are called and sent to the cluster.

Please do note that the 'config_input_files.txt' file must be fulfilled leaving an **empty space** between the colon (:) and the input text (e.g: project_directory: /bicoh/MARGenomics/Development/RNASeq/TEST).
Any other version of inputing data (such as project_directory:/bicoh/MARGenomics...) will NOT work for the pipeline. See below the description of each element from the input txt file:

  ################
  STEPS TO PERFORM
  ################
  >merge: whether you require to merge your data before processing (for >1 lane) (TRUE/FALSE).
  >quality: whether to compute the quality check(TRUE/FALSE).
  >01_umi_length_and_extract: whether to compute the UMI length and extraction (TRUE/FALSE).
  >02_cutadapt: whether to compute the cutadapt (TRUE/FALSE).
  >03_alignment: whether to compute the alignment (TRUE/FALSE).
  >04_quantification: whether to compute the quantification (TRUE/FALSE).

  ##################
  GENERAL PARAMETERS
  ##################
  >project_directory: full path for the project directory (e.g:/bicoh/MARGenomics/20230626_MFito_smallRNAseq). Do not include the batch name/folder, if any.
  >project_analysis: full path for the project analysis (e.g: directory/bicoh/MARGenomics/20230626_MFito_smallRNAseq/Analysis). Do not include the batch name/folder, if any.
  >functions: full path for the functions directory (unless functions are modified, they are in /bicoh/MARGenomics/Pipelines/smallRNASeq).
  >fastq_directory: path for the FASTQ files (e.g: /bicoh/MARGenomics/20230626_MFito_smallRNAseq/rawData). If there are batches, do NOT add them in this path, as the pipeline will automatically
  run through the batch folders if defined correctly.
  >batch_num: total number of batches.
  >bat_folder: batch name (only if batch_num is 1; e.g: FITOMON_01) or else batch prefix (only if batch_num >1; e.g: FITOMON_0). In this second case (batch_num > 1), the pipeline will assume that the batch folders
  are the batch_folder variable pasted with 1:batch_num (e.g: if batch_num is 3 and bat_folder is FITOMON_0, the batch folders will be considered as FITOMON_01, FITOMON_02 and FITOMON_03). If you have only one batch
  and they are not stored in any folder rather than within the fastq_directory, please leave this variable as 'NA' or 'FALSE'.
  >UMIs: whether the smallRNAseq contains UMIs (TRUE/FALSE).
  >fastq_suffix: suffix for the fastq files (usually .fastq.gz or .fq.gz).

  ################
  MERGE PARAMETERS
  ################
  >sample_sheet: path to the sample_sheet.xlsx file. Please copy the xlsx file from /bicoh/MARGenomics/Pipelines/smallRNASeq/sample_sheet.xlsx to your folders, but do not modify the original file.
  >total_output_files: total output files that will be generated after the merge. It must correspond to the number of rows in the sample_sheet.xlsx file.

  #############
  UMI VARIABLES
  #############
  >adapter: smallRNAseq adapter.

  ###################
  ALIGNMENT VARIABLES
  ###################
  >genome_index: genome index to be used (e.g: /bicoh/MARGenomics/AnalysisFiles/Index_Genomes_STAR/miRBase/miRBase_v22.1_hsa_hairpin_cDNA).

  ########################
  QUANTIFICATION VARIABLES
  ########################
  >reference_genome: reference genome to be used (e.g: /bicoh/MARGenomics/Ref_Genomes_fa/miRBase/miRBase_v22.1_hsa_hairpin_cDNA.fa).
  >annotation_genome: annotation genome to be used (e.g: /bicoh/MARGenomics/AnalysisFiles/Annot_files_GTF/Human_miRNAs/miRNA.str.v22.1_27092022_over_hairpin.hsa.gtf).
  >fastqscreen_config: fastQScreen configuration (e.g: /bicoh/MARGenomics/AnalysisFiles/Index_Genomes_Bowtie2/fastq_screen.conf).

Also please consider the following points when populating the config_input_files.txt and before running the pipeline:
  -If your data contains ONLY 1 batch, please populate the parameter -batch_num- with 1. If your data is stored within a folder named after this unique batch, please
  define the variable -batch_folder- accordingly. If your data is NOT stored within any batch folder, please set the variable -batch_folder- as NA or FALSE. Any
  other definitions of the variable -batch_folder- will be considered as a name for the folder in which batch data is stored.
  -If your data contains more than 1 batch, please consider the following:
      >The parameter -batch_num- refers to the number of batches your data has.
      >The parameter -batch_folder- refers to the PREFIX of your batch folders. This pipeline will consider the prefix and then add the numbers from 1 to batch_num as batch folder names
      (e.g: if -batch_num- is set to 3 and -batch_folder- to 'BATCH_0', the batch folders through which the pipeline will iterate will be 'BATCH_01', 'BATCH_02' and 'BATCH_03').
  -If you only require to run some parts of the pipeline, please consider the following:
      >This pipeline assumes that there will be 5 folders within your -project_analysis- directory:
        00_Length
        01_ExtractUMI
        02_Cutadapt
        03_Alignment
        04_Quantification
      >Please note that if '01_umi_length_and_extract' is set to FALSE, the folders '00_Length' and '01_ExtractUMI' will not be generated and are not expected to exist. If this smallRNAseq analysis contains UMIs
      (UMIs set to TRUE) but '01_umi_length_and_extract' is set to FALSE (smallRNAseq contains UMIs, but UMI length and UMI extact are not to be run), the pipeline will expect the path $WD/02_Cutadapt/Trimmed_Files
      to contain .fastq.gz files in it.
      >If '02_cutadapt' is set to FALSE but '03_alignment' to TRUE, the pipeline will assume that the path $WD/02_Cutadapt/Trimmed_Files exists and contains .zip files generated from the alignment.
      If no alignment has been run previously, the alignment will not work as the pipeline will not find the required files.
      >In the same way, if '03_alignment' is set to FALSE but '04_quantification' to TRUE, the pipeline will assume that the path $WD/03_Alignment/BAM_Files exists and that it contains .bam files in it.

  -Please read and check the SET PARAMETERS section once you have launched the pipeline in the 'logs.out' file to ensure that all your parameters have been set correctly. This 'logs.out' document will be stored
  within a logs folder generated in the 'project_analysis' path.

##################################################################
# PLEASE READ THE BELOW TEXT IF YOU REQUIRE TO MERGE FASTQ FILES #
##################################################################

If MERGE is set to TRUE (if fastq files have to be merged), please note that the Excel file 'sample_sheet.xlsx' MUST BE POPULATED. Please consider the following when doing so:
  -The 'total_output_files' variable in the 'config_input_files.txt' must correspond to the total number of files that are to be generated (total number of rows).
  -The Excel file 'sample_sheet.xlsx' must be populated with
      >(1) the paths and names of the fastq.gz files and
      >(2) the paths and names in which merged files will be stored. If there are >1 batches to be merged, note that ALL merged samples must be stored within the same folder, which will correspond to
      the FASTQDIR variable. Please consider so when populating the path. Also please consider this when populating the variables -batch_num- and -batch_folder- from the 'config_input_files.txt', which
      will need to be 1 and NA respectively.
      >It is possible to leave empty cells within a row, and also to add new columns, but note that the output path/name must ALWAYS be the last populated column of the spreadsheet, that it
      must be the same column for all rows even though empty spaces are left in some (but not all) rows, and that it must be named 'Output_name'.
      >Column names can be modified with the exception of 'Output_name' column (which MUST be the last column). Please, do NOT modify the name of this column or else the pipeline will not run.
      >Please consider saving the merged files in a different folder than the non-merged files. The pipeline will analyze any file with the prefix .fastq.gz, so unless merged and unmerged files
      are stored separately, the pipeline will analyze all of them.
  -If you require to MERGE files and your data has >1 BATCHES, please note that ALL MERGED FILES MUST BE STORED IN THE SAME OUTPUT DIRECTORY."


echo -e "
######################################################
#############                            #############
#############       SET PARAMETERS       #############
#############                            #############
######################################################
"
echo -e "Please read the below text to ensure that the parameters inputed to the config_input_files.txt are correct. \n"
echo -e "According to the set up, the steps to perform are:\n"

if [ "$MERGE" == TRUE ]; then
  echo "- Merge fastq files."
fi

if [ "$QC" == TRUE ]; then
  echo "- QC."
fi

if [ "$LENGTH_EXTRACT" == TRUE ]; then
  echo "- Compute UMI length and extraction."
fi

if [ "$CUTADAPT" == TRUE ]; then
  echo "- Cutadapt."
fi

if [ "$ALIGNMENT" == TRUE ]; then
  echo "- Alignment (STAR) and summary metrics (picard)."
fi

if [ "$QUANTIFICATION" == TRUE ]; then
  echo "- Quantification."
fi

echo -e "\nThe parameters defined for the pipeline are the following:\n"

if [ "$MERGE" == TRUE ]; then
  echo "- The sample sheet is $SAMPLE_SHEET (only used if MERGE has been defined as TRUE)."
  echo "- The total output files to be generated with the merge are: $TOTAL_OUT."

  if [ "$PAIRED" == TRUE ]; then
    END=PAIRED
    echo "- RNA end has been defined as $END END."
  else
    END=SINGLE
    echo "- RNA end has been defined as $END END."
  fi
fi

echo "- The project directory is $PROJECT."
echo "- The analysis directory is $WD."
echo "- The functions directory is $FUNCTIONSDIR."
echo "- The fastq directory is $FASTQDIR."
echo "- The fastq suffix is $FASTQ_SUFFIX"
echo "- There is/are $BATCH batch/es."
echo "- The batch folders are:"

if [ "$BATCH" -gt 1 ]; then
  folders=()  # Initialize an empty array
  for ((n=1; n<=$BATCH; n++)); do
    folder="${BATCH_FOLDER}${n}" # define "folder" as a variable that concatenates the batch prefix (BATCH_FOLDER) + the array number (e.g: BATCH_01)
    folders+=("$folder")  # Append the folder to the array
  done
elif [ "$BATCH" -eq 1 ]; then
  if [ "$BATCH_FOLDER" == "NA" ] || [ "$BATCH_FOLDER" == "FALSE" ]; then
    folders=("/")
  else
    folders=("$BATCH_FOLDER")
  fi
else
  echo "Invalid BATCH value: $BATCH"
fi

for folder in "${folders[@]}"; do
  echo "  - $folder"
done

if [ "$UMI" == TRUE ]; then
  echo "> The smallRNAseq contains UMIs."
fi

echo "- The adapter is $ADAPTER."
echo "- The genome index used is $GNMIDX."
echo "- The reference genome is $REFGENE."
echo "- The annotation genome is $ANNOTGENE."
echo "- The fastq config file is $FASTQSCREEN_CONFIG."


######################################################
#############                            #############
#############        MERGE FILES         #############
#############                            #############
######################################################

if [ "$MERGE" == TRUE ]
  then
    echo -e "
    ######################################################
    #############                            #############
    #############        MERGE FILES         #############
    #############                            #############
    ######################################################
    "
    echo -e "\n\nCreating the fastq directory where the merged files will be stored..."
    mkdir -p $FASTQDIR
    echo -e "\n\nCreating the script to concatenate the FASTQ files...\n\n"

    sbatch $FUNCTIONSDIR/Merge/create_merge_file.sh $FUNCTIONSDIR $SAMPLE_SHEET $WD

    until [ -f $WD/merge_to_run.sh ] # we need the merge_to_run.sh created in order to keep running the script. Otherwise, scripts won't be able to keep working.
      do
        sleep 10 # wait 5 seconds
    done

    echo "File found"

    echo -e "\n Merging FASTQ files...\n"

    sbatch --dependency=$(squeue --noheader --format %i --name create_merge_file) $WD/merge_to_run.sh

    echo -e "\n Compressing FASTQ files...\n"

    if ls $FASTQDIR/*.fastq >/dev/null 2>&1 # check whether there is any .fastq file
        then
            count=`ls -l $FASTQDIR/*.fastq | wc -l`
            while [ $count != $TOTAL_OUT ] # check whether ALL the files corresponding to every sample are created or not
            do
              sleep 100 # wait if not
              count=`ls -l $FASTQDIR/*.fastq | wc -l` # check again
              echo "The number of fastq files is $count"
          done
        else
            sleep 300 # if there is no fastq file, sleep for 300 seconds so some fastq file will be generated
            count=`ls -l $FASTQDIR/*.fastq | wc -l`
            while [ $count != $TOTAL_OUT ] # check whether ALL the files corresponding to every sample are created or not
            do
              sleep 100 # wait if not
              count=`ls -l $FASTQDIR/*.fastq | wc -l` # check again
              echo "The number of fastq files is $count and it should be $TOTAL_OUT"
          done
        fi
    
    echo "All done, there are a total of $count fastq files and it should be $TOTAL_OUT"

    sleep 300

    gzip $FASTQDIR/*.fastq

    count=`ls -l $FASTQDIR/*.fastq.gz | wc -l` # check again
    echo "The number of fastq.gz files is $count."

    while [ $count != $TOTAL_OUT ] # check whether ALL the files have been compressed
    do
        gzip $FASTQDIR/*.fastq
        count=`ls -l $FASTQDIR/*.fastq.gz | wc -l` # check again
          echo "The number of fastq files is $count and it should be $TOTAL_OUT"
    done


    echo -e "\n\nFastQ Files compressed\n\n"
fi

######################################################
#############                            #############
#############             QC             #############
#############                            #############
######################################################

echo -e "
######################################################
#############                            #############
#############             QC             #############
#############                            #############
######################################################
"

if [ $QC == TRUE ]
  then
    for folder in "${folders[@]}"; do
    echo -e "\n\nPerforming QC analysis for batch $folder.\n\n"

    mkdir -p "$FUNCTIONSDIR/QC/logs"
    cd "$FUNCTIONSDIR/QC" || exit 1
    echo "Path moved to $FUNCTIONSDIR/QC."
    # FASTQC and  FASTQSCREEN
    echo -e "\n\nLaunching QC loop...\n\n"
    sbatch $FUNCTIONSDIR/QC/QC_loop_and_metrics.sh $PROJECT $FASTQDIR $FUNCTIONSDIR $folder $FASTQSCREEN_CONFIG $FASTQ_SUFFIX 
    echo -e "\n\nQC job sent to the cluster.\n\n"
  done

  else
    echo -e "\n\nQC will not be performed.\n\n"
fi

######################################################
#############                            #############
#############  UMI LENGTH AND EXTRACT    #############
#############                            #############
######################################################

echo -e "
######################################################
#############                            #############
#############  UMI LENGTH AND EXTRACT    #############
#############                            #############
######################################################
"

if [ "$LENGTH_EXTRACT" == "TRUE" ]; then
  for folder in "${folders[@]}"; do
    #==============================#
    # 00) UMI LENGTH               #
    #==============================#
    echo -e "
    ====================
    Computing UMI length
    ===================="
    mkdir -p "$FUNCTIONSDIR/00_Length/logs"
    cd "$FUNCTIONSDIR/00_Length" || exit 1
    echo "Path moved to $FUNCTIONSDIR/00_Length."

    SEQUENCE_SH=$(sbatch --parsable "$FUNCTIONSDIR/00_Length/sequence.sh" "$WD" "$FASTQDIR" "$folder" "$ADAPTER" "$FASTQ_SUFFIX")
    echo "sequence.sh script sent to the cluster with job ID $SEQUENCE_SH."

    LENGTH_SH=$(sbatch --dependency=afterok:${SEQUENCE_SH} --parsable "$FUNCTIONSDIR/00_Length/length.sh" "$WD" "$folder")
    echo "length.sh script sent to the cluster with job ID $LENGTH_SH."

    #==============================#
    # 01) UMI EXTRACT              #
    #==============================#
    echo -e "
    ===============
    Extracting UMIs
    ==============="
    mkdir -p "$FUNCTIONSDIR/01_ExtractUMI/logs"
    mkdir -p "$WD/01_ExtractUMI/Fastq_Files/${folder}"
    cd "$FUNCTIONSDIR/01_ExtractUMI" || exit 1
    echo "Path moved to $FUNCTIONSDIR/01_ExtractUMI."

    length_files=$(ls -lR "$FASTQDIR/${folder}"/*$FASTQ_SUFFIX | wc -l) #get the number of files with fastq.gz extension
    echo "A total of $length_files fastq.gz files have been found and will be analyzed."

    EXTRACT_SH=$(sbatch --dependency=afterok:${LENGTH_SH} --parsable --array=1-$length_files "$FUNCTIONSDIR/01_UMI_extract/umi_extract_1mm.sh" "$FASTQDIR" "$folder" "$WD" "$ADAPTER" "$FASTQ_SUFFIX")
    echo "umi_extract_1mm.sh script sent to the cluster with job ID $EXTRACT_SH."

    GZIP_SH=$(sbatch --dependency=afterok:${EXTRACT_SH} --parsable "$FUNCTIONSDIR/01_UMI_extract/gzip.sh" "$folder" "$WD")
    echo "gzip.sh script sent to the cluster with job ID $GZIP_SH."
  done
  else
    echo -e "\n UMI length and UMI extract will not be run. \n"
  fi

######################################################
#############                            #############
#############         CUTADAPT           #############
#############                            #############
######################################################

if [ "$CUTADAPT" == "TRUE" ]; then
  for folder in "${folders[@]}"; do
    echo -e "
    ================
    Running cutadapt
    ================"

    mkdir -p "$FUNCTIONSDIR/02_Cutadapt/logs"
    mkdir -p "$WD/02_Cutadapt/Trimmed_Files/${folder}"
    cd "$FUNCTIONSDIR/02_Cutadapt" || exit 1
    echo "Path moved to $FUNCTIONSDIR/02_Cutadapt."

    if [ "$LENGTH_EXTRACT" == "TRUE" ]; then
      # Check if the job $GZIP_SH is still running

      while [[ $(squeue -j "$GZIP_SH" -h | wc -l)  == 1 ]]; do # while there is still the GZIP_SH job in the squeue, sleep for 60 seconds
          echo "The job GZIP_SH $GZIP_SH is still pending or has dependencies. Sleeping for 60 seconds..."
          sleep 60
      done

      length_files=$(ls -lR "$FASTQDIR/${folder}"/*$FASTQ_SUFFIX | wc -l) # Get the number of files with fastq.gz/.fq.gz extension
      echo -e "\n The number of fastq.gz files within the fastq directory $FASTQDIR/${folder} is $length_files."

      # Run the job with array mode and set the dependency only if LENGTH_EXTRACT is TRUE
      CUTADAPT_LOOP=$(sbatch --parsable --array=1-$length_files "$FUNCTIONSDIR/02_Cutadapt/cutadapt.loop.sh" "$FASTQDIR" "$folder" "$WD" "$FUNCTIONSDIR" "$UMI" "$ADAPTER" "$FASTQ_SUFFIX")

    else
      length_files=$(ls -lR "$FASTQDIR/${folder}"/*$FASTQ_SUFFIX | wc -l) # Get the number of files with fastq.gz extension

      # Run the job with array mode and no dependency
      CUTADAPT_LOOP=$(sbatch --parsable --array=1-$length_files "$FUNCTIONSDIR/02_Cutadapt/cutadapt.loop.sh" "$FASTQDIR" "$folder" "$WD" "$FUNCTIONSDIR" "$UMI" "$ADAPTER" "$FASTQ_SUFFIX")
    fi

    echo "cutadapt.loop.sh script sent to the cluster."

    while [ $(ls -lR "$WD/02_Cutadapt/Trimmed_Files/${folder}"/*.fastq.gz | wc -l) -ne $length_files ]; do # while there are not the same number of fastq.gz files as in the orginal fastq folders
        echo "Not all fastq.gz files have yet been generated by cutadapt. Sleeping for 60 seconds..."
        sleep 60
    done

    STATS_SH=$(sbatch --parsable "$FUNCTIONSDIR/02_Cutadapt/Stats.sh" "$WD" "$folder" "$PROJECT")
    echo "Stats.sh script sent to the cluster with job ID $STATS_SH."
    
  done
  else
    echo -e "\n Cutadapt will not be run.\n"
  fi

######################################################
#############                            #############
#############         ALIGNMENT          #############
#############                            #############
######################################################

echo -e "
######################################################
#############                            #############
#############         ALIGNMENT          #############
#############                            #############
######################################################
"
if [ "$ALIGNMENT" == "TRUE" ]; then
    for folder in "${folders[@]}"; do

    #==================================#
    # 03) ALIGNMENT                    #
    #==================================#
    echo -e "
    =================
    Running alignment
    ================="

    mkdir -p "$FUNCTIONSDIR/03_Alignment/logs"
    mkdir -p "$WD/03_Alignment/BAM_Files/${folder}"
    mkdir -p "$WD/03_Alignment/Stats/${folder}"
    cd "$FUNCTIONSDIR/03_Alignment" || exit 1
    echo "Path moved to $FUNCTIONSDIR/03_Alignment."

    INDIR="$WD/02_Cutadapt/Trimmed_Files/${folder}"
    OUTDIR="$WD/03_Alignment/BAM_Files/${folder}"

    if [ "$CUTADAPT" == "TRUE" ]; then
       
      while [[ $(squeue -j "$STATS_SH" -h | wc -l) -ne 0 ]]; do # while there is still the STATS_SH job in the squeue, sleep for 60 seconds
          echo "The job STATS_SH $STATS_SH is still pending or has dependencies. Sleeping for 60 seconds..."
          sleep 60
      done

      length_files=$(ls -lR "$INDIR"/*$FASTQ_SUFFIX | wc -l) # get the number of files with fastq.gz extension
    else
      length_files=$(ls -lR "$INDIR"/*$FASTQ_SUFFIX | wc -l) # get the number of files with fastq.gz extension
    fi

    echo "A total of $length_files fastq.gz files have been found and will be analyzed."

    if [ "$CUTADAPT" == "TRUE" ]; then
      #run the job with array mode:
      STAR_LOOP=$(sbatch --dependency=afterok:${CUTADAPT_LOOP} --parsable --array=1-$length_files "$FUNCTIONSDIR/03_Alignment/star.loop.sh" "$WD" "$FUNCTIONSDIR" "$GNMIDX" "$INDIR" "$OUTDIR" "$FASTQ_SUFFIX")
    else
      STAR_LOOP=$(sbatch --parsable --array=1-$length_files "$FUNCTIONSDIR/03_Alignment/star.loop.sh" "$WD" "$FUNCTIONSDIR" "$GNMIDX" "$INDIR" "$OUTDIR" "$FASTQ_SUFFIX")
    fi

    echo "star.loop.sh script sent to the cluster."

    while [ $(ls -lR "$OUTDIR"/*.bai| wc -l) -ne $length_files ]; do # while there are not the same number of bai files as in the trimmed files folders, sleep
        echo "Not all bai files have yet been generated by STAR. Sleeping for 60 seconds..."
        sleep 60
    done

    STATS_SH2=$(sbatch --parsable "$FUNCTIONSDIR/03_Alignment/Stats.sh" "$WD" "$folder" "$PROJECT")

    echo "Stats.sh script sent to the cluster with job ID $STATS_SH2."
  done
  else
    echo -e "\n Alignment will not be run. \n"
fi

######################################################
#############                            #############
#############       QUANTIFICATION       #############
#############                            #############
######################################################

echo -e "
######################################################
#############                            #############
#############       QUANTIFICATION       #############
#############                            #############
######################################################
"

if [ "$QUANTIFICATION" == "TRUE" ]; then
    for folder in "${folders[@]}"; do
        #==================================#
        # 04) Quantification               #
        #==================================#
        echo -e "
        ======================
        Running quantification
        ======================"

        mkdir -p "$FUNCTIONSDIR/04_Quantification/logs"
        mkdir -p "$WD/04_Quantification/CountFiles/${folder}"

        cd "$FUNCTIONSDIR/04_Quantification" || exit 1
        echo "Path moved to $FUNCTIONSDIR/04_Quantification."

        BAMDIR="$WD/03_Alignment/BAM_Files/${folder}"
        OUTDIR="$WD/04_Quantification/CountFiles/${folder}"

        INDIR="$WD/03_Alignment/BAM_Files/${folder}"

        if [ "$ALIGNMENT" == "TRUE" ]; then

            while [[ $(squeue -j "$STATS_SH2" -h | wc -l) -ne 0 ]]; do
                echo "The job STATS_SH2 $STATS_SH2 is still pending or has dependencies. Sleeping for 60 seconds..."
                sleep 60
            done

            length_files=$(ls -1R "$INDIR"/*.bam | wc -l)

        else
            length_files=$(ls -1R "$INDIR"/*.bam | wc -l)
        fi

        if [ "$UMI" == "TRUE" ]; then
            QUANT=$(sbatch --dependency=afterok:${STAR_LOOP} --parsable --array=1-$length_files "$FUNCTIONSDIR/04_Quantification/quantification.sh" "$WD" "$folder" "$REFGENE" "$ANNOTGENE" "$PROJECT" "$UMI")
            echo "Quantification script sent to the cluster."

            while [ $(ls -lR "$WD/04_Quantification/UMI_Counts/${folder}"/*.tsv | wc -l) -ne $length_files ]; do
                echo "Not all tsv files have yet been generated by quantification. Sleeping for 60 seconds..."
                sleep 60
            done

            STATS_UNIQUE=$(sbatch --parsable "$FUNCTIONSDIR/04_Quantification/Stats.unique.sh" "$FASTQDIR" "$WD" "$folder" "$PROJECT")
            echo "Stats script sent to the cluster with job ID $STATS_UNIQUE. Job will start once quantification jobs have finished."

        else
            QUANT=$(sbatch --dependency=afterok:${STAR_LOOP} --parsable "$FUNCTIONSDIR/04_Quantification/quantification.sh" "$WD" "$folder" "$REFGENE" "$ANNOTGENE" "$PROJECT" "$UMI")
            echo "quantification.sh job sent to the cluster with job ID $QUANT."
        fi

    done
fi
