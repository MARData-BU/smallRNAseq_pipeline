#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 12Gb     # Memory in MB
#SBATCH -J QC_loop           # job name
#SBATCH -o logs/QC_loop.%j.out    # File to which standard out will be written
#SBATCH -e logs/QC_loop.%j.err    # File to which standard err will be written

# Carregar variables amb el readme!!

# QC Analysis of RNASeq samples of project:

# Prepare variables
#------------------

PROJECT=$1
FASTQDIR=$2
FUNCTIONSDIR=$3
folder=$4
FASTQSCREEN_CONFIG=$5
FASTQ_SUFFIX=$6

echo -e "Project directory has been defined as $PROJECT. \n"
echo -e "Fastq directory has been defined as $FASTQDIR. \n"
echo -e "Functions directory has been defined as $FUNCTIONSDIR. \n"
echo -e "Batch has been defined as $folder.\n"
echo -e "Fastqscreen config file has been defined as $FASTQSCREEN_CONFIG. \n"
echo -e "Fastq suffix has been defined as $FASTQ_SUFFIX. \n"


cd "$FUNCTIONSDIR/QC"

#============#
#   FASTQC   #
#============#
echo -e "Creating QC and FastQC directories...\n"
mkdir -p $PROJECT/QC/${folder}/FastQC

echo -e "Directories created.\n"

FASTQC=$(sbatch --array=1-$(ls -l $FASTQDIR/${folder}/*$FASTQ_SUFFIX | wc -l) --parsable $FUNCTIONSDIR/QC/fastqc.sh $PROJECT $folder $FASTQDIR $FASTQ_SUFFIX)
echo -e "Fastqc scripts sent to the cluster.\n"

#=================#
#   FASTQSCREEN   #
#=================#
echo -e "Creating FastqScreen directory...\n"
mkdir -p $PROJECT/QC/${folder}/FastqScreen

echo -e "Directory created.\n"

FASTQSCREEN=$(sbatch --array=1-$(ls -l $FASTQDIR/${folder}/*$FASTQ_SUFFIX | wc -l) --dependency=afterok:${FASTQC} --parsable $FUNCTIONSDIR/QC/fastq_screen.sh $PROJECT $folder $FASTQDIR $FUNCTIONSDIR $FASTQSCREEN_CONFIG $FASTQ_SUFFIX)
echo -e "Scripts sent. They will be launched once FastQC scripts have finished.\n"

#=================#
#   MultiQC       #
#=================#
sbatch --dependency=afterok:${FASTQC},${FASTQSCREEN} $FUNCTIONSDIR/QC/QC_metrics.sh $PROJECT
echo -e "MultiQC job sent. It will be run once the FASTQC and FASTQSCREEN jobs have finished. \n"
