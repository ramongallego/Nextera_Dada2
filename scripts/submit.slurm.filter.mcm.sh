#!/usr/bin/env bash

#SBATCH --job-name=slurmfilter
#SBATCH --output=log.filter

#SBATCH --mail-user=ramon.gallegosimon@noaa.gov
# See manual for other options for --mail-type
#SBATCH --mail-type=ALL


#SBATCH -c 16
#SBATCH -t 6000
echo this works


# Load R from modules
module load R

# Move to the correct folders
#cd /home/rgallegosimon/

# Run R Script
# R CMD BATCH pipeline/Nextera_Dada2/scripts/skeleton_dada2.r "${1}"
Rscript --vanilla /home/rgallegosimon/pipeline/Nextera_Dada2/scripts/Filter.and.trim.mcm.r  "${1}"
 
