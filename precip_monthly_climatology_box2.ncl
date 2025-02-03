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
    ; Set paths and filenames
    ;========================================================
    base_dir = "./output_data/"
    pltDir   =  "./plots_pr/"
    pltName  = "precip_monthly_climatology_68E–90E_14–28N_"
    pltPath  = pltDir + pltName

    model1_file = base_dir + "model1_pr_annual_all_year_no_plev.nc"
    model2_file = base_dir + "model2_pr_annual_all_year_no_plev_regrid.nc"
    obs_file    = base_dir + "obs_precip_all_years_regrid.nc"

;========================================================
; Open NetCDF files and read variables
;========================================================
f1 = addfile(model1_file, "r")
f2 = addfile(model2_file, "r")
f3 = addfile(obs_file, "r")

; Read the precipitation variables
m1 = f1->pr(:,{16:26},{75:85})

m2 = f2->pr(:,{16:26},{75:85})

ob = f3->precip(:,{16:26},{75:85})

printVarSummary(m1)
printVarSummary(m2)
printVarSummary(ob)
;========================================================
; Compute Monthly Climatology
;========================================================
m1_clim = clmMonTLL(m1)  ; Model 1 climatology
m2_clim = clmMonTLL(m2)  ; Model 2 climatology
ob_clim = clmMonTLL(ob)  ; Observation climatology

printVarSummary(m1_clim)
printVarSummary(m2_clim)
printVarSummary(ob_clim)
printMinMax(ob_clim,0)

   global_mean1 = [dim_avg_n_Wrap(m1_clim, (/1,2/)) ] *86400
   global_mean2 =[ dim_avg_n_Wrap(m2_clim, (/1,2/)) ] *86400
   global_mean3 =[ dim_avg_n_Wrap(ob_clim, (/1,2/))]
   
   printMinMax(global_mean3, 0)

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
    res@xyLineThicknessF       = 2.0        ; Set line thickness
    res@tmLabelAutoStride      = True       ; Auto stride for time labels
    res@tiMainString           = "Climatology Precipitation Central India (mm/day) [75_88E, 14_26N]"
    res@trYMinF                = 0        ; Set Y-axis minimum (adjust as needed)
   res@trYMaxF                = 15        ; Set Y-axis maximum (adjust as needed)
    ;res@trXMinF                = 0        ; Set Y-axis minimum (adjust as needed)
  ; res@trMMaxF                = 11         ; Set Y-axis maximum (adjust as needed)

    ; Set legend resources
    res@pmLegendDisplayMode    = "Always"   ; Always display the legend
    res@pmLegendWidthF         = 0.1        ; Set legend width
    res@pmLegendHeightF        = 0.1       ; Set legend height
    res@pmLegendParallelPosF   = 0.9       ; Move legend horizontally
    res@pmLegendOrthogonalPosF = -0.9      ; Move legend vertically
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

