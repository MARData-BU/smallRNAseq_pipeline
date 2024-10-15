#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu 6Gb     # Memory in MB
#SBATCH -J FastQC           # job name
#SBATCH -o logs/FastQC.%j.out    # File to which standard out will be written
#SBATCH -e logs/FastQC.%j.err    # File to which standard err will be written

module purge
module load FastQC/0.11.7-Java-1.8.0_162 # de vegades falla aquesta part perquè s'ha actualitzat la versió. Comprovar amb "module avail FastQC" a bash
echo "FasQC module loaded."
# Prapare folders

PROJECT=$1
folder=$2
FASTQDIR=$3
FASTQ_SUFFIX=$4

echo -e "Project directory has been defined as $PROJECT. \n"
echo -e "Batch has been defined as $folder.\n"
echo -e "Fastq directory has been defined as $FASTQDIR. \n"
echo -e "Fastq suffix has been defined as $FASTQ_SUFFIX. \n"

mkdir -p $PROJECT/QC/${folder}/FastQC
OUTDIR=$PROJECT/QC/${folder}/FastQC

#--------------------
# Prapare input files

FASTQFILES=($(ls -1 $FASTQDIR/${folder}/*$FASTQ_SUFFIX))
i=$(($SLURM_ARRAY_TASK_ID - 1))
INFILE=${FASTQFILES[i]}
echo -e "Analyzing sample $INFILE.\n"

##############################################
#############  FASTQC ########################

fastqc --outdir $OUTDIR --threads $SLURM_CPUS_PER_TASK $INFILE
echo "FastQC run."
