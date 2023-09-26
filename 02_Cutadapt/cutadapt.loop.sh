#!/bin/bash
#SBATCH -p normal            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 4Gb     # Memory in MB
#SBATCH -J Cutadapt.loop           # job name
#SBATCH -o logs/Cutadapt.loop.%j.out    # File to which standard out will be written
#SBATCH -e logs/Cutadapt.loop.%j.err    # File to which standard err will be written

FASTQDIR=$1
folder=$2
WD=$3
FUNCTIONSDIR=$4
UMI=$5
ADAPTER=$6
FASTQ_SUFFIX=$7

echo -e "Fastq directory has been defined as $FASTQDIR.\n" 
echo -e "Batch has been defined as $folder.\n" 
echo -e "Working directory has been defined as $WD.\n" 
echo -e "Functions directory has been defined as $FUNCTIONSDIR.\n" 
echo -e "UMI has been defined as $UMI.\n" 
echo -e "Adapter has been defined as $ADAPTER.\n" 
echo -e "Fastq suffix has been defined as $FASTQ_SUFFIX.\n" 

# Prepare variables
#------------------

OUTDIR=$WD/02_Cutadapt/Trimmed_Files/${folder} # define output directory

cd $WD/02_Cutadapt

#=========================#
#   Cutadapt              #
#=========================#
if [ $UMI == TRUE ]
  then
    FASTQFILES=($(ls -1 $WD/01_ExtractUMI/Fastq_Files/${folder}/*$FASTQ_SUFFIX))
    i=$(($SLURM_ARRAY_TASK_ID - 1))
    echo "The index used is $i."
    THISFASTQFILE=${FASTQFILES[i]}
    echo "$THISFASTQFILE is being analyzed."
    CUTADAPT=$(sbatch --parsable $FUNCTIONSDIR/02_Cutadapt/cutadapt.sh $OUTDIR $THISFASTQFILE $UMI)
    echo "cutadapt.sh script run and sent to the cluster with job ID $CUTADAPT."

    #sbatch $FUNCTIONSDIR/02_Cutadapt/gzip.sh $OUTDIR
  else
    FASTQFILES=($(ls -1 $FASTQDIR/${folder}/*$FASTQ_SUFFIX))
    i=$(($SLURM_ARRAY_TASK_ID - 1))
    THISFASTQFILE=${FASTQFILES[i]}
    echo "$THISFASTQFILE is being analyzed."
    CUTADAPT=$(sbatch --parsable $FUNCTIONSDIR/02_Cutadapt/cutadapt.sh $OUTDIR $THISFASTQFILE $UMI $ADAPTER)

    echo "cutadapt.sh script run and sent to the cluster with job ID $CUTADAPT."

    #sbatch dependency=afterok:${CUTADAPT}  $FUNCTIONSDIR/02_Cutadapt/gzip.sh $OUTDIR

fi
