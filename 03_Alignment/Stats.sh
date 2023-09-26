#!/bin/bash
#SBATCH -p short            # Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 29Gb     # Memory in MB
#SBATCH -J star.stats           # job name
#SBATCH -o logs/star.stats.%j.out    # File to which standard out will be written
#SBATCH -e logs/star.stats.%j.err    # File to which standard err will be written

WD=$1
folder=$2
PROJECT=$3

# Prepare variables
#------------------

INDIR=$WD/03_Alignment/BAM_Files/${folder}
OUTDIR=$WD/03_Alignment/Stats/${folder}
mkdir -p $PROJECT/QC/${folder}/QC_trimmed/

cd $OUTDIR

#Inspeccionem el resultat dels alineaments

for i in ${INDIR}/*.final.out; do basename $i >> ${OUTDIR}/TotalCounts_Alignment; grep "Uniquely mapped reads number" "$i" >> ${OUTDIR}/TotalCounts_Alignment; grep "Number of reads mapped to multiple loci" "$i" >> ${OUTDIR}/TotalCounts_Alignment; grep "Number of reads mapped to too many loci" "$i" >> ${OUTDIR}/TotalCounts_Alignment; grep "reads unmapped: too short" "$i" >> ${OUTDIR}/TotalCounts_Alignment; done
echo "Total counts alignment file generated."

mkdir -p $PROJECT/QC/${folder}/QC_trimmed/MultiQC_data

# Copy files for multiqc
#cp $INDIR/*.final.out $PROJECT/QC/${folder}/QC_trimmed/
ln -s $INDIR/*.final.out $PROJECT/QC/${folder}/QC_trimmed/MultiQC_data # create symbolic link

echo "Final out files copied to QC_trimmed folder."

cd $PROJECT/QC/${folder}/QC_trimmed/
echo "Path moved to QC_trimmed."

module load  Python/3.8.6-GCCcore-10.2.0
echo "Python module loaded."

multiqc -f .
echo "Multiqc run."
