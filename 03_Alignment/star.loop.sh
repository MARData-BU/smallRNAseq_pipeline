#!/bin/bash
#SBATCH -p normal            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 4Gb     # Memory in MB
#SBATCH -J star.loop           # job name
#SBATCH -o logs/star.loop.%j.out    # File to which standard out will be written
#SBATCH -e logs/star.loop.%j.err    # File to which standard err will be written

WD=$1
FUNCTIONSDIR=$2
GNMIDX=$3
INDIR=$4
OUTDIR=$5
FASTQ_SUFFIX=$6

echo -e "Working directory has been defined as $WD.\n" 
echo -e "Functions directory has been defined as $FUNCTIONSDIR.\n" 
echo -e "Genome index has been defined as $GNMIDX.\n" 
echo -e "Input directory has been defined as $INDIR.\n"
echo -e "Output directory has been defined as $OUTDIR.\n"
echo -e "Fastq suffix has been defined as $FASTQ_SUFFIX.\n" 

# Prepare variables
#------------------

cd $WD/03_Alignment

#=========================#
#   STAR ALIGNMENT        #
#=========================#

# Keep reads with minimum length of 15nt ( cutadapt -m 15)
FASTQFILES=($(ls -1 $INDIR/*$FASTQ_SUFFIX))
i=$(($SLURM_ARRAY_TASK_ID - 1))
THISFASTQFILE=${FASTQFILES[i]}

echo "$THISFASTQFILE is being analyzed."

sbatch $FUNCTIONSDIR/03_Alignment/star.sh $WD $THISFASTQFILE $OUTDIR $GNMIDX
