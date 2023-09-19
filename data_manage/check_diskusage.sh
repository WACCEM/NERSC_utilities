#!/bin/bash

workdir="/global/homes/k/ksa/CESM/model" #path of the parent directory where we want to get the size of each subdirectory

cd $workdir 

#list of target directories, either explicitly written as:
#target_dir=(temp temp2 scripts figures)

# or just do the ls command to show the list of directories under $workdir
target_dir=$(ls -d */) 

pwd

for idir in "${target_dir[@]}"
do
  #human-readable, varying units
  echo "${idir} size: "
  du -sh ${idir}
 
done


