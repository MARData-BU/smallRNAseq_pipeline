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
THISFASTQFILE=$2
UMI=$3
ADAPTER=$4
#--------------------
# Prapare input files
name=`basename $THISFASTQFILE`
echo "$name is being analyzed."

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