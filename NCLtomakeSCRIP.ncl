;----------------------------------------------------------------------
; http://www.ncl.ucar.edu/Applications/ESMF.shtml
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"


begin
    ;;;; parameters to specify the input file ;;;;;
    tgtres = "HadGEM2-ES_2deg"  ;   
   

    ;where to save SCRIP files for src
    ;tgtSCRIPdir ="/global/cfs/cdirs/m1660/ksa/regrid"  
    ;tgtSCRIPdir = "/global/cfs/cdirs/m1867/ksa/NCL/wgtFiles"
    tgtSCRIPdir ="/global/cfs/cdirs/m2637/ksa/gridmaps"
    ;tgtSCRIPdir ="/global/cfs/cdirs/m1867/ksa/NCL/wgtFiles";"/glade/u/home/ksa/dca/mapping"
    ;tgtSCRIPdir = "/global/cfs/cdirs/m1867/MPASinput/mp32-4a/rotated_1830914_4-32km_Tibet"
    
    ;output SCRIP file name
    tgtSCRIPfile = ("SCRIP_" + tgtres + ".nc")
    ;tgtSCRIPfile = ("SCRIP_" + tgtres + "_watermask.nc")
    ;tgtSCRIPfile = ("SCRIP_" + tgtres + "_lndmask.nc")
    
   
    latlondir ="/global/cfs/cdirs/m2637/ksa/hadgem2-es/mon"  
    latlonfile = "ua_Amon_HadGEM2-ES_historical_r1i1p1_195912-198411.nc"
    
  
    ; more details about the source grid    
    isegional = False ; regional grid or not (src); False for global grid
    
    ;static missing data points?
    MissingData = False       
    
    ;if True, what would be an appropriate name for the mask?
    MaskName = default_fillvalue("string")
    ;MaskName = "landmask"
       
    
    latname =  "lat" ; name of the variable lat in srcFileSample
    lonname =  "lon" ; name of the variable lon in srcFileSample
    GridType   = "rectilinear" ; "latlon", "unstructured"; "curvilinear" ; "rectilinear"
      ;capture the time and date to be included in the global attributes

   ;;for quick check of statistics
   dopt = True
   dopt@PrintStat = True

   TimeDate = systemfunc("date")

end
;----------------------------------------------------------------------
;  Generate a description file (SCRIP) for the source grid.
;----------------------------------------------------------------------
SrcOpt                = True
SrcOpt@ForceOverwrite = True
SrcOpt@Overwrite       = True
SrcOpt@PrintTimings   = True
SrcOpt@Debug          = True

if(latlonfile .ne. "none") then
    sfile = addfile((latlondir + "/" + latlonfile),"r")
else
    if ( tgtres .eq. "HISCALE_d01_v1_rectilinear" ) then
        gridfile = ("/global/cfs/cdirs/m1660/ksa/simulations/common/0830_test03_wrfinput_d01")
        f = addfile(gridfile,"r")
        xlat = f->XLAT(0,:,:)
        xlon = f->XLONG(0,:,:)    
        delete(f)        
    end if

    if ( tgtres .eq. "HISCALE_d02_v1_rectilinear" ) then
        gridfile = ("/global/cfs/cdirs/m1660/ksa/simulations/common/0830_test03_wrfinput_d02")
        f = addfile(gridfile,"r")
        xlat = f->XLAT(0,:,:)
        xlon = f->XLONG(0,:,:)    
        delete(f)        
    end if
    
end if



if(MissingData) then ; Necessary if x has missing values.
    ;change the output file name
    tgtSCRIPfile = ("SCRIP_" + tgtres + "_" + MaskName + ".nc")
    
    ;for OAFlux
    if(tgtres .eq. "OAFlux_1deg") then
        svar  = rm_single_dims(sfile->evapr(0,:,:))  
        vscale = doubletofloat(svar@scale_factor)
        svar := short2flt(svar)

        misval = svar@missing_value_original
        delete(svar@missing_value)
    
        svar@_FillValue = doubletofloat(misval)*vscale
        istat = stat_dispersion(svar , dopt )  
        
        itemp = where(.not.ismissing(svar), 1 , 0) 
        copy_VarCoords(svar,itemp)
                
    end if
    

    ;for ERA5
    if(tgtres .eq. "ERA5_0.25deg") then
        svar  = rm_single_dims(sfile->LSM(0,:,:))  ; do not include time or vertical dimensions
        
        if(MaskName .eq. "ocnmask") then
            itemp = svar
        else
            itemp = where(svar .lt. 1.0, 1 , 0) 
            copy_VarCoords(svar,itemp)
        end if
        
    end if
    
    ;for SMAPDA
    if(tgtres .eq. "SMAPDA_lgdom_1km") then
        svar  = sfile->Qle_tavg  ; do not include time or vertical dimensions
        
        if(MaskName .eq. "ocnmask") then
            itemp = svar
        else
            itemp = where(ismissing(svar), 1 , 0) 
            copy_VarCoords(svar,itemp)
        end if
        
    end if
    
    ;for OSU-SM
    if(tgtres .eq. "osu_sm_800m") then
        svar  = sfile->vwc(0,0,:,:)  ; do not include time or vertical dimensions
        
        itemp = where(ismissing(svar), 1 , 0) 
        copy_VarCoords(svar,itemp)
        
    end if
    
    ;for CPC_US with ocean mask
    if(tgtres .eq. "CPC_US") then
        svar  = sfile->precip(0,:,:)  ; do not include time or vertical dimensions       
        
        itemp = where(ismissing(svar), 1 , 0) 
        copy_VarCoords(svar,itemp)
        
    end if
    
    SrcOpt@GridMask  = itemp     
    
end if
;warning:NetOpenFile: MissingToFillValue option set True, but missing_value attribute and data variable (evapr) types differ: not adding virtual _FillValue attribute
if ( isStrSubset(tgtres, "_rectilinear" )) then
    ilat = dim_avg_n(xlat,1)
    ilon = dim_avg_n(xlon,0)
    
    
else if(tgtres .eq. "SMAPDA_lgdom_1km") then
    ;the SMAP-DA lat and lon are 2d arrays, but idential in one dimension
    ; so essentially just 1d arrays for rectinilinear grid
    ilat:= dim_avg_n_Wrap(sfile->$srclatname$,1)
    ilon:= dim_avg_n_Wrap(sfile->$ilonname$,0)

else if(tgtres .eq. "wrf_NAM-22_6hr") then
    ;remove time dimension
    ilat:= ilat(0,:,:)
    ilon:= ilon(0,:,:)

else
    ilat = rm_single_dims(sfile->$latname$)
    ilon = rm_single_dims(sfile->$lonname$)
end if
end if
end if


if(GridType .eq. "latlon") then   ; uniform lat&lon grid, need to provide grid type
     print("calling latlon_to_SCRIP")
     latlon_to_SCRIP((tgtSCRIPdir + "/" + tgtSCRIPfile),latlongridname,SrcOpt) 
     
else if( GridType .eq. "rectilinear") then   ; non-uniform (can be) lat&lon grid
     print("calling rectilinear_to_SCRIP")
     rectilinear_to_SCRIP((tgtSCRIPdir + "/" + tgtSCRIPfile),ilat,ilon,SrcOpt)
     
else if( GridType .eq. "curvilinear") then  ;---If we have 2D lat/lon arrays.
     print("calling curvilinear_to_SCRIP")
     curvilinear_to_SCRIP((tgtSCRIPdir + "/" + tgtSCRIPfile),ilat,ilon,SrcOpt)
     
else if( GridType .eq. "unstructured") then ;unstructured grids. Only SE mesh.
     unstructured_to_ESMF((tgtSCRIPdir + "/" + tgtSCRIPfile),ilat,ilon,SrcOpt)
     
end if
end if
end if
end if
