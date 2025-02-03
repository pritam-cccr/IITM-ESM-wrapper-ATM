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

; Load required libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
    ; Get the season from the environment variable
    season = getenv("season")
print("lat_min from getenv: " + getenv("lat_min"))
print("lat_max from getenv: " + getenv("lat_max"))
print("lon_min from getenv: " + getenv("lon_min"))
print("lon_max from getenv: " + getenv("lon_max"))
print("Season from getenv: " + season)

lat_min = tofloat(getenv("lat_min"))
    lat_max = tofloat(getenv("lat_max"))
    lon_min = tofloat(getenv("lon_min"))
    lon_max = tofloat(getenv("lon_max"))
    
    
    
    ; Define file paths dynamically based on the season
    base_dir = "./plots_hght/"
    obs_file    = base_dir + "obs_hght_200.nc"
    model1_file = base_dir + "model1_hght_200.nc"
    model2_file = base_dir + "model2_hght_200.nc"

    ; Open observation file and read variable
    obs_file_handle = addfile(obs_file, "r")
    obs = obs_file_handle->z(0,0,:,:)

    ; Open model1 file and read variable
    model1_file_handle = addfile(model1_file, "r")
    model1 = model1_file_handle->hght(0,0,:,:)

    ; Open model2 file and read variable
    model2_file_handle = addfile(model2_file, "r")
    model2 = model2_file_handle->hght(0,0,:,:)
    ; Calculate biases
    bias_model1_obs = model1 - obs
    bias_model2_obs = model2 - obs
    bias_model1_model2 = model1 - model2

    ; Copy coordinates to biases
    copy_VarCoords(model1, bias_model1_obs)
    copy_VarCoords(model2, bias_model2_obs)
    copy_VarCoords(model1, bias_model1_model2)

    ; Define output workspace
    ; Define output workspace
    pltDir = "./plots_hght/"
    pltName = "Geopot_200hPa_ann"
    pltType = "png"
    pltPath = pltDir + pltName
    wks = gsn_open_wks(pltType, pltPath)
 plot = new(3 * 2, "graphic")
    ; Define common plot resources
    res = True
    res@gsnMaximize = True
    res@gsnFrame = False                  ; Don't advance the frame
    res@gsnDraw = False                   ; Don't draw immediately
    res@mpFillOn = False                  ; Turn off map fill
    res@mpLimitMode = "LatLon"            ; Limit plot by latitude/longitude
    res@mpMinLatF = -90                   ; Minimum latitude
    res@mpMaxLatF = 90                    ; Maximum latitude
    res@mpMinLonF = 0                     ; Minimum longitude
    res@mpMaxLonF = 360                   ; Maximum longitude
    res@cnFillOn = True                   ; Turn on contour fill
    res@cnLinesOn = False                 ; Turn off contour lines
    res@cnLineLabelsOn = False            ; Turn off contour labels
    res@cnInfoLabelOn = False             ; Turn off contour info label
res@mpCenterLonF = 180
    ; Define color palettes
    res@tmYROn = False
    res@tmXTOn = False
    res@gsnLeftString = ""
res@gsnRightString = ""
res@lbLabelBarOn = False
    res@lbTitleFontHeightF = .02
    res@lbTitleString = "w/m2"
    res@lbTitlePosition = "Bottom"
    res@lbTitleDirection = "Across"
    res@lbLabelStride = 1
    res@lbBoxEndCapStyle = "TriangleBothEnds"
    res@lbOrientation = "horizontal"
    res@pmLabelBarOrthogonalPosF = 0.1
    res@pmLabelBarWidthF = 0.8 ;* (lon_max - lon_min) / 360.0
    
res_mean = res
    res_mean@cnFillPalette = "WhiteBlueGreenYellowRed"
    res_mean@cnLevelSelectionMode = "ManualLevels"
    res_mean@cnMinLevelValF = 11000
    res_mean@cnMaxLevelValF = 12500
    res_mean@cnLevelSpacingF =100.0

    res_bias = res
    res_bias@cnFillPalette = "hotcold_18lev"
    res_bias@cnLevelSelectionMode = "ManualLevels"
    res_bias@cnMinLevelValF = -150
    res_bias@cnMaxLevelValF = 150
   res_bias@cnLevelSpacingF = 10.0

    ; Plot each variable
    res_mean@gsnCenterString = "Observation"
    plot(0) = gsn_csm_contour_map(wks, obs, res_mean)
    
res_bias@gsnCenterString = "Bias: CMIP7 - CMIP6"
    plot(1) = gsn_csm_contour_map(wks, bias_model1_model2, res_bias)

    res_mean@gsnCenterString = "CMIP7"
    plot(2) = gsn_csm_contour_map(wks, model1, res_mean)
    
res_bias@gsnCenterString = "Bias: CMIP7 - Observation"
    plot(3) = gsn_csm_contour_map(wks, bias_model1_obs, res_bias)

    
res_mean@lbLabelBarOn          = True
    res_mean@gsnCenterString = "CMIP6"
    plot(4) = gsn_csm_contour_map(wks, model2, res_mean)

    
res_bias@lbLabelBarOn          = True    
    res_bias@gsnCenterString = "Bias: CMIP6 - Observation"
    plot(5) = gsn_csm_contour_map(wks, bias_model2_obs, res_bias)

    
    ; Panel plots
    ; Panel-specific resources
    resP                = True
    resP@gsnMaximize    = True
    resP@gsnFrame       = False
    resP@gsnPanelLeft   = 0.005
    resP@gsnPanelBottom = 0.05 
    ;resP@gsnPanelSave   = True      ; Save the state of the paneled plots so we can
    resP@gsnPanelMainString = "Geopotential Height 200hPa"
    ; Draw panel
    gsn_panel(wks, plot, (/3, 2/), resP)
  

    ; Finalize the plot
    frame(wks)
end

