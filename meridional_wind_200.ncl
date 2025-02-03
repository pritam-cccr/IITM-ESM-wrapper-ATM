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
    ; Retrieve latitude and longitude ranges from environment variables
    print("lat_min from getenv: " + getenv("lat_min"))
    print("lat_max from getenv: " + getenv("lat_max"))
    print("lon_min from getenv: " + getenv("lon_min"))
    print("lon_max from getenv: " + getenv("lon_max"))

    lat_min = tofloat(getenv("lat_min"))
    lat_max = tofloat(getenv("lat_max"))
    lon_min = tofloat(getenv("lon_min"))
    lon_max = tofloat(getenv("lon_max"))

    ; Ensure valid values are received
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

    ; Define file paths for 200 hPa meridional wind data
    base_dir = "./plots_ua_va/"
    obs_v_200  = base_dir + "obs_va_200.nc"
    model1_va_200 = base_dir + "model1_va_200.nc"
    model2_va_200 = base_dir + "model2_va_200.nc"
   

    ; Read variables for 200 hPa (meridional wind only)
    obs_v_200_file  = addfile(obs_v_200, "r")
    obs_v_200_data  = obs_v_200_file->v(0,0,:,:)

    model1_va_200_file = addfile(model1_va_200, "r")
    model1_va_200_data = model1_va_200_file->va(0,0,:,:)

    model2_va_200_file = addfile(model2_va_200, "r")
    model2_va_200_data = model2_va_200_file->va(0,0,:,:)

;========================================================
; Calculate wind vector biases (u and v components)
;========================================================
; Model1 - Observation
bias_model1_obs_v_200 = model1_va_200_data - obs_v_200_data
copy_VarCoords(model1_va_200_data, bias_model1_obs_v_200)

; Model2 - Observation
bias_model2_obs_v_200 = model2_va_200_data - obs_v_200_data
copy_VarCoords(model2_va_200_data, bias_model2_obs_v_200)

; Model1 - Model2
bias_model1_model2_v_200 = model1_va_200_data - model2_va_200_data
copy_VarCoords(model1_va_200_data, bias_model1_model2_v_200)
    ; Define output workspace
    pltDir = "./plots_ua_va/"
    pltName = "Meridional_wind_200hPa_mean_bias"
    pltType = "pdf"
    pltPath = pltDir + pltName
    wks = gsn_open_wks(pltType, pltPath)

    ; Copy your resource list as-is
    res = True
    res@gsnFrame = False
    res@gsnDraw = False
    res@mpProjection = "CylindricalEquidistant"
    res@mpLimitMode = "LatLon"
    res@mpMinLatF = lat_min
    res@mpMaxLatF = lat_max
    res@mpMinLonF = lon_min
    res@mpMaxLonF = lon_max
    res@mpCenterLonF = (lon_min + lon_max) / 2.0

    if (lat_min.eq.-90 .and. lat_max.eq.90 .and. lon_min.eq.0 .and. lon_max.eq.360) then
        res@gsnAddCyclic = True
    else
        res@gsnAddCyclic = False
    end if

    res@cnInfoLabelOn = False
    res@cnFillOn = True
    res@cnLinesOn = False
    res@cnLineLabelsOn = False
    res@lbLabelBarOn = False
    res@pmTickMarkDisplayMode = "Always"
    res@mpFillOn = False
    res@mpOutlineOn = True
    res@tmYROn = False
    res@tmXTOn = False
    res@lbTitleFontHeightF = .02
    res@lbTitleString = "m/s"
    res@lbTitlePosition = "Bottom"
    res@lbTitleDirection = "Across"
    res@lbLabelStride = 1
    res@lbBoxEndCapStyle = "TriangleBothEnds"
    res@lbOrientation = "horizontal"
    res@pmLabelBarOrthogonalPosF = 0.1
    res@pmLabelBarWidthF = 0.8 * (lon_max - lon_min) / 360.0
    
res@gsnLeftString = "Meridional Wind"
res@gsnRightString = ""
    ; Separate resources for mean and bias panels
    res_mean = res
    res_mean@cnFillPalette = "wind_17lev"
    res_mean@cnLevelSelectionMode = "ManualLevels"
    res_mean@cnMinLevelValF = -10.0
    res_mean@cnMaxLevelValF = 15.0
    res_mean@cnLevelSpacingF = 1.0

    res_bias = res
    res_bias@cnFillPalette = "MPL_bwr"
    res_bias@cnLevelSelectionMode = "ManualLevels"
    res_bias@cnMinLevelValF = -5.0
    res_bias@cnMaxLevelValF = 5.0
    res_bias@cnLevelSpacingF = 1.0

    ; Create panel plots
    nrow = 3
    ncol = 2
    plot = new(nrow * ncol, "graphic")

    res_mean@gsnCenterString = "Obs"
    plot(0) = gsn_csm_contour_map(wks, obs_v_200_data, res_mean)

    res_bias@gsnCenterString = "Bias CMIP7-CMIP6"
    plot(1) = gsn_csm_contour_map(wks, bias_model1_model2_v_200, res_bias)

    res_mean@gsnCenterString = "CMIP7"
    plot(2) = gsn_csm_contour_map(wks, model1_va_200_data, res_mean)

    res_bias@gsnCenterString = "Bias CMIP7 - Obs"
    plot(3) = gsn_csm_contour_map(wks, bias_model1_obs_v_200, res_bias)

res_mean@lbLabelBarOn          = True
    res_mean@gsnCenterString = "CMIP6"
    plot(4) = gsn_csm_contour_map(wks, model2_va_200_data, res_mean)
    res_bias@lbLabelBarOn          = True
    res_bias@gsnCenterString = "Bias CMIP6 - Obs"
    plot(5) = gsn_csm_contour_map(wks, bias_model2_obs_v_200, res_bias)

    ; Panel-specific resources
    resP                = True
    resP@gsnMaximize    = True
    resP@gsnFrame       = False
    resP@gsnPanelLeft   = 0.005
    resP@gsnPanelBottom = 0.05 
    ;resP@gsnPanelSave   = True      ; Save the state of the paneled plots so we can
    resP@gsnPanelMainString = "200 hPa Meridional Wind with wind speed contour"
    ; Draw panel
    gsn_panel(wks, plot, (/nrow, ncol/), resP)
    frame(wks)
end

