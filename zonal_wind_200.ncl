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

; Start the script
begin
    ; Retrieve latitude and longitude ranges from environment variables and convert to float
    print("lat_min from getenv: " + getenv("lat_min"))
print("lat_max from getenv: " + getenv("lat_max"))
print("lon_min from getenv: " + getenv("lon_min"))
print("lon_max from getenv: " + getenv("lon_max"))

    lat_min = tofloat(getenv("lat_min"))
    lat_max = tofloat(getenv("lat_max"))
    lon_min = tofloat(getenv("lon_min"))
    lon_max = tofloat(getenv("lon_max"))

    ; Ensure valid values are received; print ranges for debugging
    print("Latitude range: " + lat_min + " to " + lat_max)
    print("Longitude range: " + lon_min + " to " + lon_max)

    ; Error handling: Default to global range if any input is invalid
    if (ismissing(lat_min) .or. ismissing(lat_max) .or. ismissing(lon_min) .or. ismissing(lon_max)) then
        print("Warning: Invalid lat/lon ranges detected. Defaulting to global range.")
        lat_min = -90.0
        lat_max = 90.0
        lon_min = 0.0
        lon_max = 360.0
    end if

    ; Define file paths for 200 hPa data
    base_dir = "./plots_ua_va/"
    ; Define file paths for 200 hPa data
base_dir = "./plots_ua_va/"
obs_u_200  = base_dir + "obs_ua_200.nc"
model1_ua_200 = base_dir + "model1_ua_200.nc"
model2_ua_200 = base_dir + "model2_ua_200.nc"


; Read variables for 200 hPa (zonal wind only)
obs_u_200_file  = addfile(obs_u_200, "r")
obs_u_200_data  = obs_u_200_file->u(0,0,:,:)

model1_ua_200_file = addfile(model1_ua_200, "r")
model1_ua_200_data = model1_ua_200_file->ua(0,0,:,:)

model2_ua_200_file = addfile(model2_ua_200, "r")
model2_ua_200_data = model2_ua_200_file->ua(0,0,:,:)

;========================================================
; Calculate wind vector biases (u and v components)
;========================================================
; Model1 - Observation
bias_model1_obs_u_200 = model1_ua_200_data - obs_u_200_data
copy_VarCoords(model1_ua_200_data, bias_model1_obs_u_200)



; Model2 - Observation
bias_model2_obs_u_200 = model2_ua_200_data - obs_u_200_data
copy_VarCoords(model2_ua_200_data, bias_model2_obs_u_200)


; Model1 - Model2
bias_model1_model2_u_200 = model1_ua_200_data - model2_ua_200_data
copy_VarCoords(model1_ua_200_data, bias_model1_model2_u_200)


; Proceed with the rest of your plotting logic

    ; Define output workspace
    pltDir = "./plots_ua_va/"
    pltName = "Zonal_wind_200hPa_mean_bias"
    pltType = "pdf"
    pltPath = pltDir + pltName
    wks = gsn_open_wks(pltType, pltPath)

    ; Define resources
    ; Define common resources
    res = True
    res@gsnFrame = False                     ; Don't advance the frame
    res@gsnDraw = False                      ; Don't draw immediately
    res@mpProjection = "CylindricalEquidistant"
    res@mpFillDrawOrder            = "PostDraw"
    res@mpLimitMode = "LatLon"
    res@mpMinLatF = lat_min
    res@mpMaxLatF = lat_max
    res@mpMinLonF = lon_min
    res@mpMaxLonF = lon_max
    res@mpCenterLonF = (lon_min+lon_max)/2.         ; Center the map at 180 degrees longitude
    
  
    res@cnInfoLabelOn       = False           ; turn off cn info label
    res@cnFillOn = True                      ; Turn on color for contours
    res@cnLinesOn = False                    ; Turn off contour lines
    res@cnLineLabelsOn = False               ; Turn off contour line labels
    res@lbLabelBarOn        = False           ; turn off individual cb's
    res@pmTickMarkDisplayMode = "Always"  ; nicer map tickmarks
    res@mpFillOn               =  False    
    res@mpOutlineOn            =  True  
    res@mpOutlineOn            =  True  
    res@tmYROn                     = False
    res@tmXTOn                     = False
    
    res@lbTitleFontHeightF         = .02                ; make title smaller
    res@lbTitleString              = "m/s"            ; title string
    res@lbTitlePosition            = "Bottom"            ; title position
    res@lbTitleDirection           = "Across"            ; title direction
    res@lbLabelStride              = 1
    ;res@lbLabelFontHeightF         = 0.025
    ;res@pmLabelBarHeightF          = 0.07
    res@lbBoxEndCapStyle           = "TriangleBothEnds"
        res@lbOrientation = "horizontal"        ; Set label bar to horizontal
    res@pmLabelBarOrthogonalPosF = 0.1      ; Move label bar further away (default is 0.0)
    ;res@pmLabelBarParallelPosF = 0.0        ; Center label bar relative to the plot

    ; Dynamically set label bar width based on longitude range
    res@pmLabelBarWidthF = 0.8 * (lon_max - lon_min) / 360.0  ; Scale width based on actual longitude span

    
    
    if (lat_min.eq.-90 .and. lat_max.eq.90 .and. lon_min.eq.0 .and. lon_max.eq.360) then
    res@gsnAddCyclic = True
else
    res@gsnAddCyclic = False
end if

    res@gsnLeftString = "Zonal Wind"
    ; Separate resources for mean and bias panels

    res_mean= res
    res_mean@cnFillPalette = "wind_17lev"          ; Subset the color map
    res_mean@cnLevelSelectionMode = "ManualLevels"
    res_mean@cnMinLevelValF = -15.0          ; Set min contour level for mean
    res_mean@cnMaxLevelValF = 50.0           ; Set max contour level for mean
    res_mean@cnLevelSpacingF = 1.0           ; Set contour spacing for mean
   
   
    
    
    res_bias= res
    res_bias@cnFillPalette = "MPL_bwr"         ; Subset the color map
    res_bias@cnLevelSelectionMode = "ManualLevels"
    res_bias@cnMinLevelValF = -10.0          ; Set min contour level for bias
    res_bias@cnMaxLevelValF = 10.0           ; Set max contour level for bias
    res_bias@cnLevelSpacingF = 1.0           ; Set contour spacing for bias
    
    ;****************************************************************************
    ; Panel layout
    nrow = 3
    ncol = 2                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                          
    plot = new(nrow*ncol , "graphic")
        
    res_mean@gsnCenterString = "Obs"    
    plot(0) = gsn_csm_contour_map(wks, obs_u_200_data, res_mean)  ; Observation Mean
    res_bias@gsnCenterString = "Bias CMIP7-CMIP6"
    plot(1) = gsn_csm_contour_map(wks, bias_model1_model2_u_200, res_bias)  ; Bias1
    
    res_mean@gsnCenterString = "CMIP7"
    plot(2) = gsn_csm_contour_map(wks, model1_ua_200_data, res_mean)  ; Model1 Mean
    
    res_bias@gsnCenterString = "Bias CMIP7 - Obs"
    plot(3) = gsn_csm_contour_map(wks, bias_model1_obs_u_200,res_bias)  ; Bias2
    
    
    res_mean@lbLabelBarOn          = True
    res_mean@gsnCenterString = "CMIP6"
    plot(4) = gsn_csm_contour_map(wks, model2_ua_200_data, res_mean)  ; Model2 Mean
    
    
    res_bias@lbLabelBarOn          = True
    res_bias@gsnCenterString = "Bias CMIP6 - Obs"
    plot(5)= gsn_csm_contour_map(wks, bias_model2_obs_u_200, res_bias)  ; Bias3


    ; Panel-specific resources
    resP                = True
    resP@gsnMaximize    = True
    resP@gsnFrame       = False
    resP@gsnPanelLeft   = 0.005
    resP@gsnPanelBottom = 0.05 
    ;resP@gsnPanelSave   = True      ; Save the state of the paneled plots so we can
    resP@gsnPanelMainString = "200 hPa Wind with wind speed contour"

    ; Draw panel
    gsn_panel(wks, plot, (/nrow, ncol/), resP)
    frame(wks)
end

