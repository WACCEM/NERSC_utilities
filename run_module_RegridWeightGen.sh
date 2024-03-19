#!/bin/bash
#SBATCH -N 2
#SBATCH -C cpu
#SBATCH -q debug
#SBATCH -t 00:15:00
#SBATCH --account m1867                     
#SBATCH --job-name WeightGen                
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=your.email@pnnl.gov

#this example script uses 2 nodes and 32 cores per node on Perlmutter
workdir="'somewhere/youwant/to/run/ESMF_RegridWeightGen" #recommend scratch space

#Modules --------------------------------------------------------------------
module use /global/common/software/m1867/modulefiles
module load esmf_tools

# -------------------

export HDF5_USE_FILE_LOCKING=FALSE

#OpenMP settings: only one thread per task
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=spread


#-----------
cd $workdir

pwd

rm -rf PET*.RegridWeightGen.Log #remove log files from previous time


inres="mp32-4a_rotated_tibet"
outres="fv0.23x0.31"
remap_method="conserve2nd"

srcfile="./mp32-4a_rotated_tibet_scrip.nc"
dstfile="./Grid_fv0.23x0.31.nc"

mapdir=$workdir
mapfile=${mapdir}/${inres}_to_${outres}_${remap_method}.nc


srun -n 64 -c 8 --cpu_bind=cores ESMF_RegridWeightGen --64bit_offset --check --ignore_degenerate --ignore_unmapped -s $srcfile -d $dstfile -w $mapfile -m $remap_method             
    
#many command options. See
#https://earthsystemmodeling.org/docs/release/ESMF_8_0_1/ESMF_refdoc/node3.html#SECTION03020000000000000000
#some options I tried:
#options="--64bit_offset --check -r " #-> does not work, although the texts are identical
#remap_method:  bilinear|patch|nearestdtos|neareststod|conserve|conserve2nd]
# --no_log
# -r : specifying that BOTH the source and destination grids are regional grids.  
#      If the argument is not given, the grids are assumed to be global.                
# --src_regional: specifying that the source is a regional grid and the destination is a global grid.
# --dst_regional: specifying that the destination is a regional grid and the source is a global grid.
# --ignore_unmapped :ignore unmapped destination points. 
#If not specified the default is to stop with an error if an unmapped point is found.
#--ignore_degenerate - ignore degenerate cells in the input grids. If not specified the default is to stop with an 
#   error if an degenerate cell is found.
#--extrap_method   - an optional argument specifying which extrapolation method is used to handle unmapped destination locations.
#not supported with conservative remapping
#The value can be one of the following: none, neareststod, nearestidavg, creep
                            # --extrap_method neareststod
#https://earthsystemmodeling.org/docs/release/ESMF_8_0_1/ESMF_refdoc/node3.html#SECTION03020000000000000000
##--ignore_unmapped added to avoid failure due to 
    #There exist destination cells (e.g. id=1) which don't overlap with any source cell
    #see https://github.com/CDAT/cdms/issues/110    
#echo "${options}"


#command for an interactive job ------------------------------------
#salloc --nodes 1 --qos interactive --time 00:30:00 --constraint cpu --account=m2645
