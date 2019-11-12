# Create the metadata file for the test data

folder <- "/Users/ramon.gallegosimon/Projects/Nextera_Dada2/data_sub"
library(tidyverse)
metadata <- tibble( filenames = list.files(path = folder, pattern = ".fastq"))



metadata %>% 
  separate(filenames, into = c("Sample", "direction"), sep = "_L001_", remove = F) %>% 
  mutate(direction = case_when(str_detect(direction, "R1")~ "file1",
                               TRUE                       ~ "file2")) %>% 
  pivot_wider(names_from = direction, values_from = filenames) %>% 
  mutate(Primer_F = "GYAATCACTTGTCTTTTAAATGAAGACC",
         Primer_R = "GGATTGCGCTGTTATCCCTA") -> metadata 
nsamples <- nrow(metadata)

Rows <- rep(LETTERS[1:8], 24)
Columns <- rep(1:24, each = 8)
Wells <- paste0(Rows, Columns)

metadata %>% 
  mutate(Row = Rows[1:nsamples],
         Column = Columns [1:nsamples],
         Well = Wells [1:nsamples]) -> metadata


metadata %>% 
  write_csv("/Users/ramon.gallegosimon/Projects/Nextera_Dada2/data_sub/metadata.csv")
  

### Create sample sheet

## Load the template
template.sample.sheet <- read_lines("/Users/ramon.gallegosimon/Projects/Nextera_Dada2/data_sub/SampleSheetLibPrep.csv")

# Locate terms

data.start <- str_which(template.sample.sheet, "^\\[Data]")
date.row  <- str_which(template.sample.sheet, "^\\Date")
Assay.row <- str_which(template.sample.sheet, "^Assay")
Index.row <- str_which(template.sample.sheet, "^Index Adapters")
Reads.row <- str_which(template.sample.sheet, "^\\[Reads]")
  
# Values

#1 merge  metadata with barcodes


  
Assay = "Nextera XT"
Index_Adapters = "Nextera XT Index Kit (96 Indexes 384 Samples)"
Reads = 301


str(template.sample.sheet)


template.sample.sheet[5] <- paste0("Date,",Sys.Date())

template.sample.sheet[13] <- paste0("Assay," ,Assay)
template.sample.sheet[15] <- paste0("Index Adapters,",Index_Adapters)
template.sample.sheet[25] <- template.sample.sheet[27] <- Reads

str_which(template.sample.sheet, "[Data]")


write_lines(template.sample.sheet,  "/Users/ramon.gallegosimon/Projects/Nextera_Dada2/data_sub/SampleSheetLibtest.csv")

## Load Illumina adapters

Nextera_Adapters_i7 <- read_csv("/Users/ramon.gallegosimon/Projects/Nextera_Dada2/data_sub/Nextera_adapters_i7.csv")

Nextera_Adapters_i5 <- read_csv("/Users/ramon.gallegosimon/Projects/Nextera_Dada2/data_sub/Nextera_adapters_i5.csv")

Nextera_Adapters_i7 %>% 
  mutate (Set = rep(c(1,2,3), each = 12)[1:26]) -> Nextera_Adapters_i7

Nextera_Adapters_i5 %>% 
  mutate (Set = rep(c(1,2,3), each = 8)[1:18]) -> Nextera_Adapters_i5

Nextera_Adapters_i7 %>% 
  filter (Set == 1) %>% 
  select(-Position, -`Bases in Adapter`, -Set) %>% 
  right_join(metadata, by = c("Column")) %>% 
  left_join(Nextera_Adapters_i5 %>% 
              filter(Set == 1) %>% 
              select(-Position, -`Bases in Adapter`, -Set)) %>% 
  select(Sample, everything()) -> metadata

## Make sample.data

sample.data = tibble (Sample_Name = metadata$Sample,
                      Sample_Plate = "",
                      Sample_Well = metadata$Well,
                      I7_Index_ID = metadata$I7_Index_ID,
                      index       = metadata$index,
                      I5_Index_ID = metadata$I5_Index_ID,
                      index2      = metadata$index2,
                      Sample_Project ="", 
                      Description = "") %>% 
  rownames_to_column("Sample_ID")

for (i in 1:nsamples){
  
  template.sample.sheet[i+44] <- paste(sample.data[i,], collapse = ",") 
  
  }

template.sample.sheet
write_lines(template.sample.sheet,  "/Users/ramon.gallegosimon/Projects/Nextera_Dada2/data_sub/SampleSheetLibtest.csv")
