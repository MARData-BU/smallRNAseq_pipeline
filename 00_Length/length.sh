#!/bin/bash
#SBATCH -p normal,long            	# Partition to submit to
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu 45Gb     	# Memory in MB
#SBATCH -J GrepLength           	# job name
#SBATCH -o logs/grep.%j.out	# Sdt out file name: %j SLURM_JOB_ID; %A SLURM_ARRAY_JOB_ID, %a SLURM_ARRAY_TASK_ID
#SBATCH -e logs/grep.%j.err	# Std err file name

WD=$1
folder=$2

echo -e "The working directory has been defined as $WD."
echo -e "The batch that is now being processed is $folder."

mkdir $WD/00_Length/Fastq_Files/Results_grep
mkdir $WD/00_Length/Fastq_Files/Results_grep_length
mkdir $WD/00_Length/Fastq_Files/Results_distribution
mkdir $WD/00_Length/Fastq_Files/Results_grep/${folder}
mkdir $WD/00_Length/Fastq_Files/Results_grep_length/${folder}
mkdir $WD/00_Length/Fastq_Files/Results_distribution/${folder}

echo -e "Computing the number of bp per line... /n"

for i in $(ls $WD/00_Length/Fastq_Files/Results/${folder}/*.txt| xargs -I {} basename {} | rev | cut -d "/" -f 1 | rev) # extract the basenames (file names) without the path of each file
  do echo "reading file $i"
  while read line
    do
      echo "$line has ${#line} bp";#"$line has ${#line} bp";
    done < $WD/00_Length/Fastq_Files/Results/${folder}/$i > $WD/00_Length/Fastq_Files/Results_grep/${folder}/$i;
  done

# ----------------------------------------------- #

## Saving length of read
echo -e "Saving length of the read... /n"

for i in $(ls $WD/00_Length/Fastq_Files/Results_grep/${folder}/*.txt| xargs -I {} basename {} | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1);
  do for j in $(ls $WD/00_Length/Fastq_Files/Results_grep/${folder}/${i}*.txt);
    do cat $WD/00_Length/Fastq_Files/Results_grep/${folder}/${i}*.txt >> $WD/00_Length/Fastq_Files/Results_grep_length/${folder}/${i}_length.txt;
  done;
done;

## Getting length distribution
echo -e "Getting length distribution... /n"

for i in $(ls $WD/00_Length/Fastq_Files/Results_grep_length/${folder}/*.txt| cut -d "/" -f 10| cut -d "." -f 1);
  do cat $WD/00_Length/Fastq_Files/Results_grep_length/${folder}/${i}.txt | cut -d " " -f 3 | sort | uniq -c > \
      $WD/00_Length/Fastq_Files/Results_distribution/${folder}/${i}.txt;
  done
