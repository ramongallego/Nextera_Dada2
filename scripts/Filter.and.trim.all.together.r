### THe default version
## Take the metadata and run the fitler and trim 
## as it was on the original script

## Run Rscript Filter.and.trim.all.together.r params.csv

args = commandArgs(trailingOnly=TRUE)

library (tidyverse)
library (dada2)
library (digest)
library (seqinr)
library (tictoc)

tic()
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
                           } )) -> filter.data

write_rds(filter.data, "output.filter.rds")
toc()