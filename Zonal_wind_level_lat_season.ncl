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
    base_dir = "./plots_ua_va/"
    pltDir   =  "./plots_ua_va/"
    pltName  = "ZonalWind_lat_season_mean_bias"
    pltPath  = pltDir + pltName
    
    
    ob_u_file =    base_dir + "obs_ua_season_regridded_ordered.nc"
    
    
    m1_u_file =    base_dir + "model1_ua_season_ordered.nc"
   
    
    m2_u_file =    base_dir + "model2_ua_season_ordered.nc"
    
      
    
    
    
    
  ;===================================
  ; Open observation file and read variable
    f1 = addfile(ob_u_file, "r")
    obs_u = f1->u(0,:,:,:)

    ; Open model1 file and read variable
    f2 = addfile(m1_u_file, "r")
    model1_u = f2->ua(0,:,:,:)

    ; Open model2 file and read variable
    f3 = addfile(m2_u_file, "r")
    model2_u = f3->ua(0,:,:,:) 
    
    
    ; Calculate biases
bias1_u = model1_u - obs_u
bias2_u = model2_u - obs_u
bias3_u = model1_u - model2_u

; Copy coordinates and attributes
copy_VarCoords(model1_u, bias1_u)
copy_VarAtts(model1_u, bias1_u)  ; Assuming model1_u has relevant metadata

copy_VarCoords(model2_u, bias2_u)
copy_VarAtts(model2_u, bias2_u)  ; Assuming model2_u has relevant metadata

copy_VarCoords(model1_u, bias3_u)
copy_VarAtts(model1_u, bias3_u)  ; Assuming model1_u has relevant metadata

    
    
    
    
    printVarSummary(obs_u)
    printVarSummary(model1_u)
    printVarSummary(model2_u)
    printVarSummary(bias1_u)
    printVarSummary(bias2_u)
    printVarSummary(bias3_u)
    

    
    ;=========================
    
    
    
; Perform zonal averaging (average over longitude dimension)
    obs_avg=dim_avg_n_Wrap(obs_u,2)
    model1_avg=dim_avg_n_Wrap(model1_u,2)
    model2_avg=dim_avg_n_Wrap(model2_u,2)
    ba1_avg=dim_avg_n_Wrap(bias1_u,2)
    ba2_avg=dim_avg_n_Wrap(bias2_u,2)
    ba3_avg=dim_avg_n_Wrap(bias3_u,2)
    
; Convert from Kelvin to Celsius
obs_avg_c    = obs_avg 
model1_avg_c = model1_avg
model2_avg_c = model2_avg 
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
    res@lbTitleString = "m/s-2"
    res@lbTitlePosition = "Bottom"
    res@lbTitleDirection = "Across"
    res@lbLabelStride = 1
    res@lbBoxEndCapStyle = "TriangleBothEnds"
    res@lbOrientation = "horizontal"
    res@pmLabelBarOrthogonalPosF = 0.1
    res@pmLabelBarWidthF = 0.8 
   res@tmYLMode ="Explicit"
    
    res@tmYLValues = (/1000.,  700.,  500.,  300., \
                     150.,  50.,  10.,  1./)

; Define labels for the pressure levels
res@tmYLLabels = (/"1000", "700",  "500", "300", \
                    "150", "50", "10","1"/)

    
    res_mean = res
    res_mean@cnFillPalette = "CBR_coldhot"
    res_mean@cnLevelSelectionMode = "ManualLevels"
    res_mean@cnMinLevelValF = -80
    res_mean@cnMaxLevelValF = 80.0
    res_mean@cnLevelSpacingF = 5.0

    res_bias = res
    res_bias@cnFillPalette = "MPL_RdGy"
    res_bias@cnLevelSelectionMode = "ManualLevels"
    res_bias@cnMinLevelValF = -30.0
    res_bias@cnMaxLevelValF = 30.0
    res_bias@cnLevelSpacingF =2

    ; Plot each variable
    res_mean@gsnCenterString = "Observation"
    plot(0) = gsn_csm_pres_hgt(wks, obs_avg_c({1000:1},:), res_mean)
    
res_bias@gsnCenterString = "Bias: CMIP7 - CMIP6"
    plot(1) = gsn_csm_pres_hgt(wks, ba3_avg_c({1000:1},:), res_bias)

    res_mean@gsnCenterString = "CMIP7"
    plot(2) = gsn_csm_pres_hgt(wks, model1_avg_c({1000:1},:), res_mean)
    

res_bias@gsnCenterString = "Bias: CMIP7 - Observation"
    plot(3) = gsn_csm_pres_hgt(wks, ba1_avg_c({1000:1},:), res_bias)

    
res_mean@lbLabelBarOn          = True
    res_mean@gsnCenterString = "CMIP6"
    plot(4) = gsn_csm_pres_hgt(wks, model2_avg_c({1000:1},:), res_mean)

    
res_bias@lbLabelBarOn          = True    
    res_bias@gsnCenterString = "Bias: CMIP6 - Observation"
    plot(5) = gsn_csm_pres_hgt(wks, ba2_avg_c({1000:1},:), res_bias)

    
    ; Panel plots
    ; Panel-specific resources
    resP                = True
    resP@gsnMaximize    = True
    resP@gsnFrame       = False
    resP@gsnPanelLeft   = 0.005
    resP@gsnPanelBottom = 0.05 
    resP@gsnPanelMainString = "Zonal Wind :Pressure vs. Latitude"
    resP@gsnPanelScalePlotIndex = 0  ; Scale all plots to match the first plot
    ; Draw panel
    gsn_panel(wks, plot, (/3, 2/), resP)
  

    ; Finalize the plot
    frame(wks)
   
end    
