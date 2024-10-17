#!/bin/bash
#SBATCH -p normal            # Partition to submit to
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 7Gb     # Memory in MB
#SBATCH -J cutadapt           # job name
#SBATCH -o logs/cutadapt.%A_%a.out    # File to which standard out will be written
#SBATCH -e logs/cutadapt.%A_%a.err    # File to which standard err will be written

module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load Python/3.8.6-GCCcore-10.2.0

#------------------------
# Prapare folders

OUTDIR=$1
UMI=$2
ADAPTER=$3
FASTQDIR=$4
FASTQ_SUFFIX=$5
folder=$6

echo -e "Output directory has been defined as $OUTDIR.\n" 
echo -e "UMI has been defined as $UMI.\n" 
echo -e "Adapter has been defined as $ADAPTER.\n" 
echo -e "Fastq directory has been defined as $FASTQDIR.\n" 
echo -e "Fastq suffix has been defined as $FASTQ_SUFFIX.\n" 

FASTQFILES=($(ls -1 $FASTQDIR/${folder}/*$FASTQ_SUFFIX))
i=$(($SLURM_ARRAY_TASK_ID - 1)) ## bash arrays are 0-based
echo -e "Array index is $i.\n" 

THISFASTQFILE=${FASTQFILES[i]}

echo "$THISFASTQFILE is being analyzed."

#--------------------
# Prapare input files
name=`basename $THISFASTQFILE`
echo "The basename for the file is $name."

#--------------------
# Run cutadapt & and qc
# Keep reads with minimum length of 15nt ( cutadapt -m 15)

if [ $UMI == TRUE ]
  then
    cutadapt -j $SLURM_CPUS_PER_TASK -m 15 -o $OUTDIR/$name $THISFASTQFILE
  else
    cutadapt -j $SLURM_CPUS_PER_TASK -m 15 -a $ADAPTER -o $OUTDIR/$name $THISFASTQFILE
fi

module load FastQC/0.11.7-Java-1.8.0_162
echo "FastQC module loaded."

fastqc --outdir $OUTDIR --threads $SLURM_CPUS_PER_TASK $OUTDIR/$name 
echo "FastQC run."
