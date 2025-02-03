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
  mask_dir = "./"
  mask_file_name = mask_dir + "INDIA_mask.nc"

  base_dir = "./output_data/"
  model1_file = base_dir + "model1_pr_annual_all_year_no_plev_regrid.nc"
  model2_file = base_dir + "model2_pr_annual_all_year_no_plev_regrid.nc"
  obs_file    = base_dir + "obs_precip_all_years_regrid.nc"

  ;========================================================
  ; Open mask file and read mask variable
  ;========================================================
  mask_file = addfile(mask_file_name, "r")  ; Open the NetCDF file
  maskk = dble2flt(mask_file->mask(0,:,:))  ; Convert to float if it's double

  printVarSummary(maskk)  ; Print details (dimensions, attributes, etc.)

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
  ; Preserve coordinate attributes
  ;========================================================
  m1_masked@lat = m1@lat
  m1_masked@lon = m1@lon
  m1_masked@time = m1@time
  m1_masked@long_name = m1@long_name + " (Masked)"
  m1_masked@_FillValue = m1@_FillValue

  m2_masked@lat = m2@lat
  m2_masked@lon = m2@lon
  m2_masked@time = m2@time
  m2_masked@long_name = m2@long_name + " (Masked)"
  m2_masked@_FillValue = m2@_FillValue

  ob_masked@lat = ob@lat
  ob_masked@lon = ob@lon
  ob_masked@time = ob@time
  ob_masked@long_name = ob@long_name + " (Masked)"
  ob_masked@_FillValue = ob@_FillValue

  ; Print summaries
  printVarSummary(m1_masked)
  printVarSummary(m2_masked)
  printVarSummary(ob_masked)

  ;========================================================
  ; Compute Monthly Climatology
  ;========================================================
  m1_clim = clmMonTLL(m1_masked)  ; Model 1 climatology
  m2_clim = clmMonTLL(m2_masked)  ; Model 2 climatology
  ob_clim = clmMonTLL(ob_masked)  ; Observation climatology

  ; Convert climatology to mm/day (if applicable)
  global_mean1 = dim_avg_n_Wrap(m1_clim, (/1,2/)) * 86400
  global_mean2 = dim_avg_n_Wrap(m2_clim, (/1,2/)) * 86400
  global_mean3 = dim_avg_n_Wrap(ob_clim, (/1,2/))

  ; Print summaries and min/max for debugging
  printVarSummary(m1_clim)
  printVarSummary(m2_clim)
  printVarSummary(ob_clim)

  printMinMax(global_mean1, 0)
  printMinMax(global_mean2, 0)
  printMinMax(global_mean3, 0)
;==================================================
    pltDir   =  "./plots_pr/"
    pltName  = "precip_monthly_climatology_INDIA"
    pltPath  = pltDir + pltName

    ; Get the time dimension
    
    time_indices = ispan(0,11, 1)  ; Generate time indices for plotting

    ;========================================================
    ; Create a graphics workstation
    ;========================================================
    wks = gsn_open_wks("png", pltPath)

    ;========================================================
    ; Define plot resources
    ;========================================================
    res = True
    res@gsnMaximize           = True        ; Maximize plot in the frame
    res@vpWidthF         = 0.8                      ; set width and height
  res@vpHeightF        = 0.3
    res@xyLineThicknessF       = 2.0        ; Set line thickness
    res@tmLabelAutoStride      = True       ; Auto stride for time labels
    res@tiMainString           = "Climatology Precipitation (mm/day) [INDIA]"
    res@tiMainFontHeightF=0.02
    res@trYMinF                = 0        ; Set Y-axis minimum (adjust as needed)
   res@trYMaxF                = 10         ; Set Y-axis maximum (adjust as needed)
    res@trXMinF                = 0        ; Set Y-axis minimum (adjust as needed)
    res@trXMaxF                = 11         ; Set Y-axis maximum (adjust as needed)

    ; Set legend resources
    res@pmLegendDisplayMode    = "Always"   ; Always display the legend
    res@pmLegendWidthF         = 0.1        ; Set legend width
    res@pmLegendHeightF        = 0.05      ; Set legend height
    res@pmLegendParallelPosF   = 0.1       ; Move legend horizontally
    res@pmLegendOrthogonalPosF = -0.99      ; Move legend vertically
    res@lgPerimOn              = False      ; No border around the legend
    res@xyExplicitLegendLabels = (/"CMIP7", "CMIP6", "OBS"/)  ; Legend labels
;---Turn off some tickmarks
  res@tmXTOn                 = False    ; bottom off
  res@tmYROn                 = False    ; right off

  res@xyLineThicknessF       = 2.0      ; default is 1
  res@xyMonoDashPattern      = True     ; force all solid lines
res@tmXBMode   = "Explicit"       ; Use explicit X-axis labels
res@tmXBValues = ispan(0, 11, 1)  ; Index values for each time step
res@tmXBLabels = (/"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"/)  ; Array of labels
res@tmXBLabelFontHeightF = 0.015  ; Optional: Adjust label font size




    ;========================================================
    ; Plot all datasets
    ;========================================================
    res@xyLineColors           = (/"blue", "red", "black"/)   ; Line colors for datasets
    data = (/global_mean1, global_mean2, global_mean3/)                              ; Combine data arrays

    plot = gsn_csm_xy(wks, time_indices, data, res)          ; Create the plot

    ;========================================================
    ; Advance the frame
    ;========================================================
    ;frame(wks)

end

