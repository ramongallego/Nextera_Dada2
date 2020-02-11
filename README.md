# Nextera_Dada2
A wrapper around the process needed to process MiSeq reads with Dada2 when the libraries have been made with Nextera adapters
I have done this in UNIX (macOSX10.13.6 High Sierra - I will test it in Linux, macOSX Catalina)

# Dependecies

  - cutadapt (v1.)
  - R (v3.6 or above), Rstudio(if not then I think you need pandoc, knitr, rmarkdown)
  - R packages:
    * tidyverse
    * DADA2
    * rmarkdown
    * stringr
    * digest
    * knitr
    * kableExtra
    
  

# Installation

Of this pipeline, go to https://github.com/ramongallego/Nextera_Dada2 and clone or download this repository. Of the dependecies, I will update this with links that will break in the next month

# Input files

You will need: 

  - A folder with all the fastq files to be processed.
  - A metadata file with one row per sample and locus with the following columns:
  
  
        - Sample name - The name that makes sense to you and your project (No spaces in the name would be better)
        - Well  - in the 96-well plate
        - Set - In case there are more than 96 samples (1, 2, 3)
        - Locus: The name of the locus you want to use (e.g. Leray_COI)
        - PrimerF: The nucleotide sequence of the forward primer - supports IUPAC characters 
        - PrimerR: Ditto for the reverse primer (also in 5' -> 3' direction)
        - i7 Adapter: N701... See file Nextera_adapters_i7.csv in the data_sub subfolder.
        - i5 Adapter: S503... See file Nextera_adapters_i5.csv in the data_sub subfolder
        - File1: it should match exactly the output of the Miseq.
        - File2: Same for the second read.
        
  - An output folder.
        

# Output files

The pipeline will work in two stages. I have done this to make sure that you only have to run the cutadapt part once, and then you can reuse the output of cutadapt with different parameters.

## The cutadapt-wrapper

The first one will split the reads by locus (if there is more than one) and remove the primer from the sequences. It will deploy in your folder:

  - A series of fastq files, two per sample and locus (Forward and Reverse reads)
  - A new metadata file, that will have one row per sample and the following columns:
  
      - Sample_name
      - Locus  (the name from the original.metadata)
      - file1 (with the format Locus_original_file1_name.fastq)
      - file2 (with the same format)
      
And this is all you need to run the second part of the analysis

## The Dada2 tailing

This part of the process will quality trim the reads, merge them and detect the Amplicon Sequence Variants using Dada2. The inputs required are the series of fastq files and the new metadata we generated from step1. 

The outputs that you will obtain are:
 
  - ASV table: includes three columns: Hash, Sample, nReads
  - Hash_key, in .csv format, two columns: Hash, Sequence
  - Hash key, in .fasta format
  
The program also spits out a table with the summary statistics, a log file, and a Markdown. It will also create a copy of the parameter and metadata files

# Usage

## The cutadapt-wrapper

Operates in the bash shell. So open the terminal and run


`bash path\to\script\cutadapt.wrapper.sh path\to\folder\with\fastqs {metadata_file} {output_folder}`

## The Dada2-wrapper

Open the file dada2.Rmd in Rstudio. Click on the dropdown option `Knitr with parameters`. Add your selections

Currently working in getting a browse function that allows you to navigate to your target folder


