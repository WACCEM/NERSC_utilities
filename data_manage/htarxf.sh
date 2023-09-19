#! /bin/bash
# exit when any command fails
set -e
#https://intoli.com/blog/exit-on-errors-in-bash-scripts/


pcase="0830"  #parent case, often resolutions
icase="JF_sensitivity5"  #experiment case name
idomain="d02"


#outdir="/global/cfs/cdirs/m3314/ksa/simulations/${pcase}/${icase}/wrfout_d02" 
outdir="/global/cfs/cdirs/m3314/ksa/simulations/${pcase}/0830_00/wrfout_d02" 


archdir="/nersc/projects/m3314/ksa/wrf/runs/HI-SCALE/${pcase}/${icase}" 

hsi_hist=false  #true to directly upload (hsi) instead of htar; needed for very large files


iyear=2016
imonth=08  #make sure to pad with 0 for months < 11
iday=30    #make sure to pad with 0 for days < 11

idate=${iyear}-${imonth}-${iday}

echo "retrieving $i{icase} history data"
echo ${idate}

hours=(14 15 16 17 18 19 20 21 22)  

cd ${outdir}
pwd

for ihr in "${hours[@]}"
do
    
    if [ "$hsi_hist" = true ]; then        
        for ifile in $files
        do
            echo "hsi get chdir}/history/${ifile}"
            hsi get ${archdir}/history/${ifile}
            errcode=$?
            if [ "$errcode" -ne 0 ]; then
                echo "hsi failed for ${ifile}"
                exit 24
            fi  
        done
    else
        archname="${icase}_${idomain}_${idate}_${ihr}_history.tar" 
        htar -xf ${archdir}/${archname}

    fi

done

echo "done"
