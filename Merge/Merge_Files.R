
samplesheet=commandArgs()[6]
outputDir=commandArgs()[7]

print(samplesheet)
print(outputDir)

require(openxlsx)

zcat <- openxlsx::read.xlsx(xlsxFile = samplesheet , sheet=1)

list.paste <- list() # create an empty list to print in the merge_to_run.sh file afterwards
list.paste[[1]] <- "#!/bin/bash"
list.paste[[2]] <- "#SBATCH -p long,short,normal"
list.paste[[3]] <- "#SBATCH --cpus-per-task=6"
list.paste[[4]] <- "#SBATCH --mem-per-cpu 8Gb"
list.paste[[5]] <- "#SBATCH -J create_merge_file"
list.paste[[6]] <- "#SBATCH -o logs/runR.%J.out"
list.paste[[7]] <- "#SBATCH -e logs/runR.%J.err"

for (i in 1:nrow(zcat)) {
  true_cases <- length(which(apply(zcat[i, 1:ncol(zcat)], 2, complete.cases) == T))
  fastqfiles <- zcat[i, 1:(true_cases - 1)] # We add "-1" because the last element of the zcat table is the output file
  
  if (length(grep(".fastq.gz$", zcat$Output_name[i])) == 1) { # if the output file name HAS ".fastq.gz" in the end, replace it by "fastq
    zcat$Output_name[i] = gsub(".fastq.gz$", ".fastq", zcat$Output_name[i])
  } else if (length(grep(".fastq$", zcat$Output_name[i])) == 0) { # if the output file name does NOT have ".fastq.gz" nor ".fastq" in the end, add "fastq"
    zcat$Output_name[i] = paste0(zcat$Output_name[i], ".fastq")
  }
  
  # Append the first zcat command separately without a separator
  list.paste[[i + 7]] <- paste0("zcat ", fastqfiles[1], " > ", zcat$Output_name[i])
  
  # Loop through the rest of the zcat commands and append them with " ; "
  for (j in 2:(true_cases - 1)) {
    list.paste[[i + 7]] <- paste(list.paste[[i + 7]], paste("zcat ", fastqfiles[j], " >> ", zcat$Output_name[i]), sep = " ; ")
  }
}

write.table(x=unlist(list.paste),quote=FALSE,sep="\n", file=file.path(outputDir,"merge_to_run.sh"),row.names = F, col.names = F)
