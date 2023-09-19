#! /bin/bash
# Contributors: Koichi Sakaguchi
# Purpose: transfer multiple files as archiving them together by htar command 

iyear=2016
months=(01 02 03)

#path to the directory where target files are stored
indir="/pscratch/sd/${USER}/datadir}" 

#destination HPSS path
archdir="/nersc/projects/m3314/ksa/wrf/runs/HI-SCALE/${pcase}/${icase}" 

testdir="/pscratch/sd/${USER}/htar_checksum"  #this is where we temporally download the archive file to check for errors
# the data there will be removed after checking

logdir="/pscratch/sd/${USER}/htar_logs"  #htar log files can be useful when we find a problem (e.g., missing files) later

#conditioning based on types of files, e.g., model history vs. restart outputs
save_hist=true

save_restart=false
hsi_restart=true #high-resolution restart file can be very large...


#history files -----------------------------------------------------------
if [ "$save_hist" = true ]; then
    echo "archiving history files"
    
    
    for imonth in "${months[@]}"
    do
        cd $indir
        
        files=$(ls modeloutput_${iyear}-${imonth}*nc) #get a list of files (e.g., daily) for a particular month

        #create a file name for the archive file
        archname="modeloutput_${iyear}-${imonth}_history.tar" 
        htar -Hcrc -cf ${archdir}/${archname} ${files}  #create htar archive

        #test the archived files
        cd $testdir
        echo "verify checksum of ${archname}"
        htar -Hverify=crc -xvf ${archdir}/${archname} >| ${logdir}/htar_checksum_${archname}.log
        errcode=$?
        if [ "$errcode" -ne 0 ]; then
            echo "verification failed for ${archname}"
            exit 21
        else
            echo "verification success"
            rm -rf ${testdir}/modeloutput_${iyear}-${imonth}*nc 
        fi          
    
    done

fi

#restart files -----------------------------------------------------------
if [ "$save_restart" = true ]; then
    echo "archiving restart files"
    
    for ihr in "${hours[@]}"
    do
        cd $indir
        ifile=wrfrst_${idomain}_${idate}_${ihr}_00_00 #only top of the hour
        
        if [ "$hsi_restart" = true ]; then
        
            echo "hsi put ${ifile} : ${archdir}/restart/${ifile}"
			hsi put ${ifile} : ${archdir}/restart/${ifile}
			errcode=$?
			if [ "$errcode" -ne 0 ]; then
				echo "hsi failed for ${ifile}"
				exit 25
			fi            

        
#        else
            #not sure if need to make tar file for each single file
            
#            archname="${icase}_${iyear}-${ihr}_restart.tar" 
#            echo htar -Hcrc -cf ${archdir}/${archname} ${files}
#           
#
#            cd $testdir
#            echo "verify checksum of ${archname}"
#            htar -Hverify=crc -xvf ${archdir}/${archname} >| ${logdir}/htar_checksum_${archname}.log
#            errcode=$?
#            if [ "$errcode" -ne 0 ]; then
#                echo "verification failed for ${archname}"
#                exit 22
#            else
#                echo "verification success"
#                rm -rf ${testdir}/*nc
#             fi                     
        fi
    
    done
    
else
    echo "skipping restart files"
        
fi
   

echo "done"
