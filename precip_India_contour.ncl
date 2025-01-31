; Load necessary libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;---Open shapefile and read lat/lon values.
  dir     = "./India-State-and-Country-Shapefile-Updated-Jan-2020-master/"
  shp_file= dir + "India_Country_Boundary.shp"
  f       = addfile(shp_file, "r")
  shp_lon = tofloat( f->y )
  shp_lat = tofloat( f->x )
  nshp    = dimsizes(shp_lon)

;---Get Max & Min lat/lon for the shape file 

  min_shp_lat = min(shp_lat) 
  max_shp_lat = max(shp_lat)
  min_shp_lon = min(shp_lon)
  max_shp_lon = max(shp_lon)
  
  print(min_shp_lon)
  print(max_shp_lon)
  print(min_shp_lat)
  print(max_shp_lat)
    ;========================================================
    ; Set paths and filenames
    base_dir = "./output_data/"
    pltDir   =  "./plots_pr/"
    pltName  = "precip_monthly_climatology_INDIA "
    pltPath  = pltDir + pltName

    model1_file = base_dir + "model1_pr_annual_all_year_no_plev_regrid.nc"
    model2_file = base_dir + "model2_pr_annual_all_year_no_plev_regrid.nc"
    obs_file    = base_dir + "obs_precip_all_years_regrid.nc"

;========================================================
; Open NetCDF files and read variables
;========================================================
f1 = addfile(model1_file, "r")
f2 = addfile(model2_file, "r")
f3 = addfile(obs_file, "r")

; Read the precipitation variables
m1 = f1->pr(:,{6.75:37.08},{68.12:97.4})
  m1_dimp=dimsizes(m1)
  m1_ntim    = m1_dimp(0)
  m1_nlat    = m1_dimp(1)
  m1_mlon    = m1_dimp(2)

m2 = f2->pr(:,{6.75:37.08},{68.12:97.4})
  m2_dimp=dimsizes(m2)
  m2_ntim    = m2_dimp(0)
  m2_nlat    = m2_dimp(1)
  m2_mlon    = m2_dimp(2)

ob = f3->precip(:,{6.75:37.08},{68.12:97.4})
  ob_dimp=dimsizes(m2)
  ob_ntim    = ob_dimp(0)
  ob_nlat    = ob_dimp(1)
  ob_mlon    = ob_dimp(2)
printVarSummary(m1)
printVarSummary(m2)
printVarSummary(ob)
;=============================================
;---Create arrays for masking and initialize with _FillValue
m1_pmask = new(dimsizes(m1), typeof(m1), m1@_FillValue)
m2_pmask = new(dimsizes(m2), typeof(m2), m2@_FillValue)
ob_pmask = new(dimsizes(ob), typeof(ob), ob@_FillValue)

;---Copy coordinates from original variables
copy_VarCoords(m1, m1_pmask)
copy_VarCoords(m2, m2_pmask)
copy_VarCoords(ob, ob_pmask)


;---Mask `m1`
m1_pmask = new(dimsizes(m1), typeof(m1), m1@_FillValue)  ; Create mask array
copy_VarCoords(m1, m1_pmask)                             ; Copy coordinates

do nl = 0, dimsizes(m1&latitude) - 1
  do ml = 0, dimsizes(m1&longitude) - 1
    if (gc_inout(m1&latitude(nl), m1&longitude(ml), shp_lat, shp_lon)) then
      m1_pmask(:, nl, ml) = m1(:, nl, ml)  ; Apply mask to `m1`
    end if
  end do
end do

;---Mask `m2`
m2_pmask = new(dimsizes(m2), typeof(m2), m2@_FillValue)  ; Create mask array
copy_VarCoords(m2, m2_pmask)                             ; Copy coordinates

do nl = 0, dimsizes(m2&latitude) - 1
  do ml = 0, dimsizes(m2&longitude) - 1
    if (gc_inout(m2&latitude(nl), m2&longitude(ml), shp_lat, shp_lon)) then
      m2_pmask(:, nl, ml) = m2(:, nl, ml)  ; Apply mask to `m2`
    end if
  end do
end do

;---Mask `ob`
ob_pmask = new(dimsizes(ob), typeof(ob), ob@_FillValue)  ; Create mask array
copy_VarCoords(ob, ob_pmask)                             ; Copy coordinates

do nl = 0, dimsizes(ob&latitude) - 1
  do ml = 0, dimsizes(ob&longitude) - 1
    if (gc_inout(ob&latitude(nl), ob&longitude(ml), shp_lat, shp_lon)) then
      ob_pmask(:, nl, ml) = ob(:, nl, ml)  ; Apply mask to `ob`
    end if
  end do
end do


  ;=================================
  printVarSummary(m1_pmask)
printVarSummary(m2_pmask)
printVarSummary(ob_pmask)
 
;=============
   m1_mean = [dim_avg_n_Wrap(m1_pmask, 0) ] *86400
   m2_mean =[ dim_avg_n_Wrap(m2_pmask, 0) ] *86400
   ob_mean =[ dim_avg_n_Wrap(ob_pmask, 0)]
   
   printVarSummary(m1_mean)
printVarSummary(m2_mean)
printVarSummary(ob_mean)
  ;=================================
 /;  
    m1_mean&lat@units="degrees_north" 
    m1_mean&lon@units="degrees_east" 
   
   
printVarSummary(m1_mean)
printVarSummary(m2_mean)
printVarSummary(ob_mean)
  ;=================================
  
  wks = gsn_open_wks("pdf", pltPath)
 plot = new(3 * 1, "graphic")
    ; Define common plot resources
    res = True
    res@gsnMaximize = True
    res@gsnFrame = False                  ; Don't advance the frame
    res@gsnDraw = False                   ; Don't draw immediately
    res@mpFillOn = False                  ; Turn off map fill
 res@gsnAddCyclic         =  False
    res@cnFillOn = True                   ; Turn on contour fill
    res@cnLinesOn = False                 ; Turn off contour lines
    res@cnLineLabelsOn = False            ; Turn off contour labels
    res@cnInfoLabelOn = False             ; Turn off contour info label

    ; Define color palettes
    res@tmYROn = False
    res@tmXTOn = False
    res@gsnLeftString = ""
res@gsnRightString = ""
res@lbLabelBarOn = False
    res@lbTitleFontHeightF = .02
    res@lbTitleString = "mm/day"
    res@lbTitlePosition = "Bottom"
    res@lbTitleDirection = "Across"
    res@lbLabelStride = 1
    res@lbBoxEndCapStyle = "TriangleBothEnds"
    res@lbOrientation = "horizontal"
    res@pmLabelBarOrthogonalPosF = 0.1
    res@pmLabelBarWidthF = 0.8 ;* (lon_max - lon_min) / 360.0
    res@mpMinLatF = 66                   ; Minimum latitude
    res@mpMaxLatF = 90                    ; Maximum latitude
    res@mpMinLonF = 6                     ; Minimum longitude
    res@mpMaxLonF = 38                   ; Maximum longitude
res_mean = res
    res_mean@cnFillPalette = "CBR_wet"
    res_mean@cnLevelSelectionMode = "ManualLevels"
    res_mean@cnMinLevelValF = 0.0
    res_mean@cnMaxLevelValF = 10.0
    res_mean@cnLevelSpacingF = 2.0

    res_bias = res
    res_bias@cnFillPalette = "hotcold_18lev"
    res_bias@cnLevelSelectionMode = "ManualLevels"
    res_bias@cnMinLevelValF = -60.0
    res_bias@cnMaxLevelValF = 60.0
    res_bias@cnLevelSpacingF = 5.0

    ; Plot each variable
    res_mean@gsnCenterString = "Observation"
    plot(0) = gsn_csm_contour_map(wks, ob_mean, res_mean)
    


    res_mean@gsnCenterString = "CMIP7"
    plot(1) = gsn_csm_contour_map(wks, m1_mean, res_mean)


    
res_mean@lbLabelBarOn          = True
    res_mean@gsnCenterString = "CMIP6"
    plot(2) = gsn_csm_contour_map(wks, m2_mean, res_mean)



    
    ; Panel plots
    ; Panel-specific resources
    resP                = True
    resP@gsnMaximize    = True
    resP@gsnFrame       = False
    resP@gsnPanelLeft   = 0.005
    resP@gsnPanelBottom = 0.05 
    ;resP@gsnPanelSave   = True      ; Save the state of the paneled plots so we can
    resP@gsnPanelMainString = "Precipitation"
    ; Draw panel
    gsn_panel(wks, plot, (/3, 1/), resP)
  

    ; Finalize the plot
    frame(wks)
;/

end
