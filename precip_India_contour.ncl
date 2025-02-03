; ==============================================================================
;  Copyright (C) 2025 Centre for Climate Change Research (CCCR), IITM
;
;  This script is part of the CCCR IITM_ESM diagnostics system.
;
;  Author: Pritam Das Mahapatra
;  Date: January 2025
;  Version: 1.0
;  Usage:
;  This script should be executed within an NCL environment and assumes 
;  required NetCDF files are available.
;
; ==============================================================================
; Load necessary libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

  ;========================================================
  ; Define file paths
  ;========================================================
  mask_file_name = "./INDIA_mask.nc"
  base_dir = "./output_data/"
  model1_file = base_dir + "model1_pr_annual_all_year_no_plev_regrid.nc"
  model2_file = base_dir + "model2_pr_annual_all_year_no_plev_regrid.nc"
  obs_file    = base_dir + "obs_precip_all_years_regrid.nc"

 

  ;========================================================
  ; Open mask file and read mask variable
  ;========================================================
  mask_file = addfile(mask_file_name, "r")  
  maskk = dble2flt(mask_file->mask(0,:,:))  

  ;========================================================
  ; Open NetCDF files and read precipitation data
  ;========================================================
  f1 = addfile(model1_file, "r")
  f2 = addfile(model2_file, "r")
  f3 = addfile(obs_file, "r")

  m1 = f1->pr(:,:,:)
  m2 = f2->pr(:,:,:)
  ob = f3->precip(:,:,:)

  ;========================================================
  ; Create empty masked arrays
  ;========================================================
  m1_masked = new(dimsizes(m1), typeof(m1), getFillValue(m1))
  m2_masked = new(dimsizes(m2), typeof(m2), getFillValue(m2))
  ob_masked = new(dimsizes(ob), typeof(ob), getFillValue(ob))

  ;========================================================
  ; Apply mask separately for each dataset due to different time dimensions
  ;========================================================
 
; Loop for Model 1 (m1)
do t = 0, dimsizes(m1(:,0,0)) - 1
    m1_masked(t,:,:) = m1(t,:,:)  ; Initialize with original data
    m1_masked(t,:,:) = where(maskk .eq. 1, m1_masked(t,:,:), m1@_FillValue)
end do

; Loop for Model 2 (m2)
do t = 0, dimsizes(m2(:,0,0)) - 1
    m2_masked(t,:,:) = m2(t,:,:)  ; Initialize with original data
    m2_masked(t,:,:) = where(maskk .eq. 1, m2_masked(t,:,:), m2@_FillValue)
end do

; Loop for Observation (ob)
do t = 0, dimsizes(ob(:,0,0)) - 1
    ob_masked(t,:,:) = ob(t,:,:)  ; Initialize with original data
    ob_masked(t,:,:) = where(maskk .eq. 1, ob_masked(t,:,:), ob@_FillValue)
end do
  ;========================================================
  ; Compute Time Mean (dim_avg_n_Wrap)
  ;========================================================
  m1_mean = dim_avg_n_Wrap(m1_masked, 0) * 86400
  m2_mean = dim_avg_n_Wrap(m2_masked, 0) * 86400
  ob_mean = dim_avg_n_Wrap(ob_masked, 0)  

  ;========================================================
  ; Assign correct latitude and longitude metadata
  ;========================================================
  copy_VarCoords(m1_masked(0,:,:), m1_mean)
  copy_VarCoords(m2_masked(0,:,:), m2_mean)
  copy_VarCoords(ob_masked(0,:,:), ob_mean)

  ;========================================================
  ; Compute Bias (Difference between datasets)
  ;========================================================
  bias1 = m1_mean - ob_mean   ; CMIP7 - Observation
  bias2 = m2_mean - ob_mean   ; CMIP6 - Observation
  bias3 = m1_mean - m2_mean   ; CMIP7 - CMIP6

  copy_VarCoords(m1_mean, bias1)
  copy_VarCoords(m2_mean, bias2)
  copy_VarCoords(m1_mean, bias3)

  ;========================================================
  ; Plotting
  ;========================================================
  pltDir   =  "./plots_pr/"
  pltName  = "precip_bias_INDIA"
  pltPath  = pltDir + pltName

  wks = gsn_open_wks("png", pltPath)
  plot = new(6, "graphic")

  res = True
  res@gsnMaximize = True
  res@gsnFrame = False                  
  res@gsnDraw = False                   
  res@mpOutlineOn   = False
  res@mpFillOn      = False                   
  res@gsnAddCyclic = False
  res@cnFillOn = True                   
  res@cnLinesOn = False                 
  res@cnLineLabelsOn = False            
  res@cnInfoLabelOn = False     
  res@gsnLeftString = ""
  res@gsnRightString = ""
  ;res@lbLabelBarOn = False
  res@lbTitleFontHeightF = .02
  res@lbTitleString = "mm/day"
  res@lbTitlePosition = "Bottom"
  res@lbTitleDirection = "Across"
  res@lbLabelStride = 1
  res@lbBoxEndCapStyle = "TriangleBothEnds"
  res@lbOrientation = "horizontal"
  res@pmLabelBarOrthogonalPosF = 0.1

  res@mpLimitMode = "LatLon"      
  res@mpMinLatF = 6                  
  res@mpMaxLatF = 40                  
  res@mpMinLonF = 66                  
  res@mpMaxLonF = 100                  

  ; Define color palettes
  res_mean = res
  res_mean@cnFillPalette = "CBR_wet"
  res_mean@cnLevelSelectionMode = "ManualLevels"
  res_mean@cnMinLevelValF = 0
  res_mean@cnMaxLevelValF = 8
  res_mean@cnLevelSpacingF = 0.25
  
  res_bias = res
  res_bias@cnFillPalette = "hotcold_18lev"
   res_bias@cnLevelSelectionMode = "ManualLevels"
  res_bias@cnMinLevelValF = -4
  res_bias@cnMaxLevelValF = 4
  res_bias@cnLevelSpacingF = 0.5

  ; Generate Mean Plots with Shapefile Overlay
  res_mean@gsnCenterString = "Observation"
  plot(0) = gsn_csm_contour_map(wks, ob_mean, res_mean)
  
  res_bias@gsnCenterString = "CMIP7 - CMIP6 Bias"
  plot(1) = gsn_csm_contour_map(wks, bias3, res_bias)

  res_mean@gsnCenterString = "CMIP7"
  plot(2) = gsn_csm_contour_map(wks, m1_mean, res_mean)
  
  res_bias@gsnCenterString = "CMIP7 - OBS Bias"
  plot(3) = gsn_csm_contour_map(wks, bias1, res_bias)

  res_mean@gsnCenterString = "CMIP6"
  plot(4) = gsn_csm_contour_map(wks, m2_mean, res_mean)

  res_bias@gsnCenterString = "CMIP6 - OBS Bias"
  plot(5) = gsn_csm_contour_map(wks, bias2, res_bias)

  ;--- Panel plots
  resP = True
  resP@gsnMaximize = True
  resP@lbLabelBarOn = True
  resP@gsnPanelMainString = "Precipitation Analysis"
  gsn_panel(wks, plot, (/3,2/), resP)

;  ;--- Add Shapefile Borders
;   shapefile_path = "./India_Country_Boundary_FINAL.shp"
  
;  plres = True
;  plres@gsLineColor = "black"
;  gsn_add_shapefile_polylines(wks, plot, shapefile_path, plres)

  ;--- Finalize the plot
;  frame(wks)

end

