## If you don't need the report, and just want to execute the dad2.Rmd script 
## with a params file 
## Run this script with 
## Rscript skeleton_dada2.r params.txt
## For the params file, make a copy of the /params.example.txt

#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library (tidyverse)
library (dada2)
library (digest)
library (seqinr)


# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else{params <- read_csv(args[1])}

params 
params <- params %>% pivot_wider(names_from = Argument, values_from=value)
params %>% mutate(across(.cols= starts_with("trimming"), .fn = as.numeric)) %>% 
  mutate(merge.overlap = as.numeric (merge.overlap)) -> params

### Chunk 0 

setwd(params$folder)

### Chunk 1
sample.metadata <- read_csv(params$metadata)
filt_path <- file.path(params$folder, "filtered")
getwd()
filt_path
# Check if output directory exists - if not create as a subfolder of input dir

if(!dir.exists(file.path(params$output.folder))){
  dir.create(path = file.path(params$output.folder),recursive = T)
  output.dir <- file.path(params$output.folder)
}else{
  output.dir <- file.path(params$output.folder)
}
output.dir

####
sample.metadata %>%
  separate(file1, into = "basename", sep= "_L001_R1", remove = F) %>% 
  mutate(filtF1 = file.path("filtered", paste0(basename, "_F1_filt.fastq.gz")),
         filtR1 = file.path("filtered", paste0(basename, "_R1_filt.fastq.gz"))) %>%
  select(-basename) %>% 
  mutate (outFs = pmap_dfr(.l= list (file1, filtF1, file2, filtR1),
                           .f = function(a, b, c, d) {
                             filterAndTrim(a,b,c,d,
                                           truncLen=c(params$trimming.length.Read1,params$trimming.length.Read2),
                                          # truncLen=c(263,60),
                                           maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
                                           compress=TRUE, multithread=TRUE ) %>% 
                               as.data.frame()
                           } )) -> after.filter
 write_rds(after.filter, file = "after.filter.rds")
after.filter %>% 
  filter (outFs$reads.out > 100)  %>% # Keep only cases in which there arest least 100  sequences passing filter
  mutate(
    errF1 = map(filtF1, ~ learnErrors(.x, multithread=TRUE,verbose = 0)),     # Calculate errors
    errR1 = map(filtR1, ~ learnErrors(.x, multithread=TRUE,verbose = 0)),
    derepF1 = map(filtF1, derepFastq),                   # dereplicate seqs
    derepR1 = map(filtR1, derepFastq),
    dadaF1  = map2(derepF1,errF1, ~ dada(.x, err = .y, multithread = TRUE)),  # dada2
    dadaR1  = map2(derepR1,errR1, ~ dada(.x, err = .y, multithread = TRUE)),
    mergers = pmap(.l = list(dadaF1,derepF1, dadaR1,derepR1),                 # merge things
                   .f = mergePairs,
                   minOverlap = params$merge.overlap)) -> output.dada2

## change dir to output directory
setwd(params$output.folder)
if ( params$keep.mid.files==TRUE){
  write_rds(output.dada2, path = "output.halfway.rds")}


seqtabF <- makeSequenceTable(output.dada2$mergers)
dim(seqtabF)

table(nchar(getSequences(seqtabF)))

## ----RemovingChimeras, message=F---------------------------------------------------------------
seqtab.nochim <- removeBimeraDenovo(seqtabF, method="consensus", multithread=TRUE)
dim(seqtab.nochim)
seqtab.nochim.df <- as.data.frame(seqtab.nochim)


## ----setting up output files-------------------------------------------------------------------
# Copy the metadata so it is all in one place
sample.metadata %>% write_csv("metadata.csv")
# Output files
conv_file <- "hash_key.csv"
conv_file.fasta <- "hash_key.fasta"

ASV_file <-  "ASV_table.csv"

print (conv_file)
print (conv_file.fasta)
print(ASV_file)


## ----Hash or not-------------------------------------------------------------------------------
if ( params$hash==TRUE)
{
  conv_table <- tibble( Hash = "", Sequence ="")
  
  
  map_chr (colnames(seqtab.nochim.df), ~ digest(.x, algo = "sha1", serialize = F, skip = "auto")) -> Hashes
  conv_table <- tibble (Hash = Hashes,
                        Sequence = colnames(seqtab.nochim.df))
  
  colnames(seqtab.nochim.df) <- Hashes
  
  
  
  write_csv(conv_table, conv_file) # write the table into a file
  write.fasta(sequences = as.list(conv_table$Sequence),
              names     = as.list(conv_table$Hash),
              file.out = conv_file.fasta)
  # dangerous use of bind_cols - use outputdada2 for.now
  
  seqtab.nochim.df <- bind_cols(output.dada2 %>%
                                  select(Sample_name, Locus),
                                seqtab.nochim.df)
  seqtab.nochim.df %>%
    pivot_longer(cols = c(- Sample_name, - Locus),
                 names_to = "Hash",
                 values_to = "nReads") %>%
    filter(nReads > 0) -> current_asv
  write_csv(current_asv, ASV_file)    }else{
    #What do we do if you don't want hashes: two things - Change the header of the ASV table, write only one file
    seqtab.nochim.df %>%
      bind_cols(output.dada2 %>%
                  select(Sample_name, Locus)) %>% 
      pivot_longer(cols = c(- Sample_name, - Locus),
                   names_to = "Sequence",
                   values_to = "nReads") %>%
      filter(nReads > 0) -> current_asv
    write_csv(current_asv, ASV_file)
  }


## ----output_summary----------------------------------------------------------------------------
getN <- function(x) sum(getUniques(x))

output.dada2 %>%
  select(-file1, -file2, -filtF1, -filtR1, -errF1, -errR1, -derepF1, -derepR1) %>%
  mutate_at(.vars = c("dadaF1", "dadaR1", "mergers"),
            ~ sapply(.x,getN)) %>%
  #  pull(outFs) -> test
  mutate(input = outFs$reads.in,
         filtered = outFs$reads.out,
         tabled  = rowSums(seqtabF),
         nonchim = rowSums(seqtab.nochim)) %>%
  select(Sample_name,
         Locus,
         input,
         filtered,
         denoised_F = dadaF1,
         denoised_R = dadaR1,
         merged = mergers,
         tabled,
         nonchim) -> track

write_csv(track, "dada2_summary.csv")


## ----drop--------------------------------------------------------------------------------------
if ( params$keep.mid.files==FALSE){
  unlink(filt_path, recursive = T)
}


## ----output_summary table and fig--------------------------------------------------------------
# kable (track, align= "c", format = "html") %>%
#   kable_styling(bootstrap_options= "striped", full_width = T, position = "center") %>%
#   column_spec(2, bold=T)




## ----output_summary plot-----------------------------------------------------------------------
# track %>%
#   mutate_if(is.numeric, as.integer) %>%
#   pivot_longer(cols = c(-Sample_name, -Locus),
#                names_to = "Step",
#                values_to = "Number of Sequences") %>%
#   mutate (Step = fct_relevel(Step,
#                              levels = c( "input","filtered","denoised_F" ,"denoised_R" , "merged" , "tabled", "nonchim"))) %>%
#   ggplot(aes(x = Step, y = `Number of Sequences`, group =  Sample_name, color = Sample_name)) +
#   geom_line() +
#   facet_wrap(~Sample_name) +
#   guides(color = "none")


