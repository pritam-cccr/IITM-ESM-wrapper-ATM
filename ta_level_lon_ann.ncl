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
    base_dir = "./plots_ta/"
    pltDir   =  "./plots_ta/"
    pltName  = "vertTemp_level_lon_annual_mean_bias"
    pltPath  = pltDir + pltName
    
    
    obs_file =    base_dir + "obs_annual_regridded_ordered.nc"
    model1_file = base_dir + "model1_annual_mean_ordered.nc"
    model2_file = base_dir + "model2_annual_regridded_ordered.nc"
    
    bias1_file=base_dir + "ta_annual_bias_obs_model1.nc"
    bias2_file=base_dir + "ta_annual_bias_obs_model2.nc"
    bias3_file=base_dir + "ta_annual_bias_model1_model2.nc"
    
  ;===================================
  ; Open observation file and read variable
    f1 = addfile(obs_file, "r")
    obs = f1->t(0,:,:,:)

    ; Open model1 file and read variable
    f2 = addfile(model1_file, "r")
    model1 = f2->ta(0,:,:,:)

    ; Open model2 file and read variable
    f3 = addfile(model2_file, "r")
    model2 = f3->ta(0,:,:,:) 
    
    f4 = addfile(bias1_file, "r")
    ba1 = f4->ta(0,:,:,:)

    ; Open model1 file and read variable
    f5 = addfile(bias2_file, "r")
    ba2 = f5->ta(0,:,:,:)

    ; Open model2 file and read variable
    f6 = addfile(bias3_file, "r")
    ba3 = f6->ta(0,:,:,:) 
    
    
    ;printVarSummary(obs)
    ;printVarSummary(model1)
    ;printVarSummary(model2)
    ;printVarSummary(ba1)
    ;printVarSummary(ba2)
    ;printVarSummary(ba3)
    
    
    
    ;=========================
    
; Perform zonal averaging (average over longitude dimension)
obs_avg    = dim_avg_n_Wrap(obs, 1)
model1_avg = dim_avg_n_Wrap(model1, 1)
model2_avg = dim_avg_n_Wrap(model2, 1)
ba1_avg    = dim_avg_n_Wrap(ba1, 1)
ba2_avg    = dim_avg_n_Wrap(ba2, 1)
ba3_avg    = dim_avg_n_Wrap(ba3, 1)

; Convert from Kelvin to Celsius
obs_avg_c    = obs_avg - 273.15
model1_avg_c = model1_avg - 273.15
model2_avg_c = model2_avg - 273.15
ba1_avg_c    = ba1_avg 
ba2_avg_c    = ba2_avg 
ba3_avg_c    = ba3_avg 

; Copy coordinates and attributes
copy_VarCoords(obs_avg, obs_avg_c)
copy_VarCoords(model1_avg, model1_avg_c)
copy_VarCoords(model2_avg, model2_avg_c)
copy_VarCoords(ba1_avg, ba1_avg_c)
copy_VarCoords(ba2_avg, ba2_avg_c)
copy_VarCoords(ba3_avg, ba3_avg_c)

copy_VarAtts(obs_avg, obs_avg_c)
copy_VarAtts(model1_avg, model1_avg_c)
copy_VarAtts(model2_avg, model2_avg_c)
copy_VarAtts(ba1_avg, ba1_avg_c)
copy_VarAtts(ba2_avg, ba2_avg_c)
copy_VarAtts(ba3_avg, ba3_avg_c)

    
   ; printVarSummary(obs_avg_c)
    ;printVarSummary(model1_avg)
    ;printVarSummary(model2_avg)
    ;printVarSummary(ba1_avg_c)
    ;printVarSummary(ba2_avg)
    ;printVarSummary(ba3_avg_c)
    
  ;=================
  ; Define output workspace
  
  custom_ticks = (/1000, 850, 500, 300, 100, 10/)  ; Define preferred pressure levels

    wks = gsn_open_wks("pdf", pltPath)
 plot = new(3 * 2, "graphic")
    ; Define common plot resources
    res = True
    res@gsnMaximize = True
    res@gsnFrame = False                  ; Don't advance the frame
    res@gsnDraw = False                   ; Don't draw immediately
     res@vpWidthF  = 0.8
res@vpHeightF = 0.4
  
    res@cnFillOn = True                   ; Turn on contour fill
    res@cnLinesOn = True                 ; Turn off contour lines
    res@cnLineLabelsOn = False            ; Turn off contour labels
    res@cnInfoLabelOn = False             ; Turn off contour info label
    res@gsnPresHgtHeightLabelOn=False
     ; Define color palettes
    res@tmYROn = False
    res@tmXTOn = False
    res@gsnLeftString = ""
res@gsnRightString = ""
res@lbLabelBarOn = False
    res@lbTitleFontHeightF = .02
    res@lbTitleString = "[~S~o~N~C]"
    res@lbTitlePosition = "Bottom"
    res@lbTitleDirection = "Across"
    res@lbLabelStride = 1
    res@lbBoxEndCapStyle = "TriangleBothEnds"
    res@lbOrientation = "horizontal"
    res@pmLabelBarOrthogonalPosF = 0.1
    res@pmLabelBarWidthF = 0.8 
   
    
    res_mean = res
    res_mean@cnFillPalette = "WhiteBlueGreenYellowRed"
    res_mean@cnLevelSelectionMode = "ManualLevels"
    res_mean@cnMinLevelValF = -80
    res_mean@cnMaxLevelValF = 40.0
    res_mean@cnLevelSpacingF = 5.0

    res_bias = res
    res_bias@cnFillPalette = "hotcold_18lev"
    res_bias@cnLevelSelectionMode = "ManualLevels"
    res_bias@cnMinLevelValF = -10.0
    res_bias@cnMaxLevelValF = 10.0
    res_bias@cnLevelSpacingF =1

    ; Plot each variable
    res_mean@gsnCenterString = "Observation"
    plot(0) = gsn_csm_pres_hgt(wks, obs_avg_c({1000:100},:), res_mean)
    
res_bias@gsnCenterString = "Bias: CMIP7 - CMIP6"
    plot(1) = gsn_csm_pres_hgt(wks, ba3_avg_c({1000:100},:), res_bias)

    res_mean@gsnCenterString = "CMIP7"
    plot(2) = gsn_csm_pres_hgt(wks, model1_avg_c({1000:100},:), res_mean)
    

res_bias@gsnCenterString = "Bias: CMIP7 - Observation"
    plot(3) = gsn_csm_pres_hgt(wks, ba1_avg_c({1000:100},:), res_bias)

    
res_mean@lbLabelBarOn          = True
    res_mean@gsnCenterString = "CMIP6"
    plot(4) = gsn_csm_pres_hgt(wks, model2_avg_c({1000:100},:), res_mean)

    
res_bias@lbLabelBarOn          = True    
    res_bias@gsnCenterString = "Bias: CMIP6 - Observation"
    plot(5) = gsn_csm_pres_hgt(wks, ba2_avg_c({1000:100},:), res_bias)

    
    ; Panel plots
    ; Panel-specific resources
    resP                = True
    resP@gsnMaximize    = True
    resP@gsnFrame       = False
    resP@gsnPanelLeft   = 0.005
    resP@gsnPanelBottom = 0.05 
    resP@gsnPanelMainString = "Temperature :Pressure vs. Longitude"
    resP@gsnPanelScalePlotIndex = 0  ; Scale all plots to match the first plot
    ; Draw panel
    gsn_panel(wks, plot, (/3, 2/), resP)
  

    ; Finalize the plot
    frame(wks)
end    
