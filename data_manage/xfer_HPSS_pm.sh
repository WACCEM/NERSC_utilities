#!/bin/bash -l
#SBATCH -A m3314
#SBATCH -q xfer
#SBATCH -t 10:00:00
#SBATCH -J htar_wrf
##SBATCH -L SCRATCH  #does not work. Gives an error
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=koichi.sakaguchi@pnnl.gov
##SBATCH --mem=15G

pwd

#capture starting time for log file name
idate=$(date "+%Y-%m-%d-%H%M")


#for history files
icase="les_test02"

echo "archiving outputs from ${icase}"

./htar_WRFoutput_pm.sh  >| htar_${icase}_${idate}.log

# use #SBATCH -M escori instead of loading the esslurm module
#check job status by this command:
#squeue -M escori -u ksa
