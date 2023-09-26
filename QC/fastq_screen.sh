#!/bin/bash
#SBATCH -p short,normal            # Partition to submit to
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu 8Gb     # Memory in MB
#SBATCH -J FastQScreen           # job name
#SBATCH -o logs/FastQScreen.%j.out    # File to which standard out will be written
#SBATCH -e logs/FastQScreen.%j.err    # File to which standard err will be written

#-------------------------------

module purge  ## Why? Clear out .bashrc /.bash_profile settings that might interfere
module load FastQ-Screen/0.14.1 # de vegades falla aquesta part perquè s'ha actualitzat la versió. Comprovar amb "module avail FastQ-Screen" a bash
module load Bowtie2/2.4.2-GCC-10.2.0	# Required for Fastqscreen. Ídem al de dalt; en aquest cas "module avail Bowtie2"
echo "FastQScreen and Bowtie modules loaded."

#------------------------
# Prapare folders
PROJECT=$1
folder=$2
FASTQDIR=$3
FUNCTIONSDIR=$4
FASTQSCREEN_CONFIG=$5
FASTQ_SUFFIX=$6

echo -e "Project directory has been defined as $PROJECT. \n"
echo -e "Batch has been defined as $folder.\n"
echo -e "Functions directory has been defined as $FUNCTIONSDIR. \n"
echo -e "Fastqscreen config file has been defined as $FASTQSCREEN_CONFIG. \n"
echo -e "Fastq suffix has been defined as $FASTQ_SUFFIX. \n"


mkdir $PROJECT/QC/${folder}/FastqScreen
OUTDIR=$PROJECT/QC/${folder}/FastqScreen

#--------------------
# Prapare input files

FASTQFILES=($(ls -1 $FASTQDIR/${folder}/*$FASTQ_SUFFIX))
i=$(($SLURM_ARRAY_TASK_ID - 1)) ## bash arrays are 0-based
INFILE=${FASTQFILES[i]}

##############################################
#############  FASTQ SCREEN ##################

cd $FUNCTIONSDIR
fastq_screen --threads $SLURM_CPUS_PER_TASK --conf $FASTQSCREEN_CONFIG --outdir $OUTDIR $INFILE
echo "FastQScreen run."
