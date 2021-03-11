#!/usr/bin/env bash

## Usage sbatch submit.slurm.cutadapt.sh <path_to_fastqs> <path_to_metadata> <path_to_output_folder>

#SBATCH --job-name=cutadapt
#SBATCH --output=log.trimming

#SBATCH --mail-user=ramon.gallegosimon@noaa.gov
# See manual for other options for --mail-type
#SBATCH --mail-type=ALL


#SBATCH -c 16
#SBATCH -t 6000
echo this works

mkdir "$3"

# activate  venv

#source /home/rgallegosimon/pipeline/bin/activate

# Move to the correct folders
#cd /home/rgallegosimon/pipeline/Nextera_Dada2

# Name vars

#FASTQ_folder={1}
#METADATA={2}
#OUTPUT_folder={3}


# bash scripts/cutadapt.wrapper.sh data_sub/fastqs/ data_sub/metadata.csv /home/rgallegosimon/test
# bash scripts/cutadapt.wrapper.sh "${1}" "${2}" "${3}"
