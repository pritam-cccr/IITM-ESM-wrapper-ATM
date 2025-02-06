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

print("Season from getenv: " + season)

; Base directory for the files
base_dir = "./output_data/"

;====================================================
; Solar Files (Dynamic Season)
obs_file1 = base_dir + "obs_" + season + "_mean_solar_mon_regridded.nc"
model1_file1 = base_dir + "model1_" + season + "_mean_rsdt_no_plev.nc"
model2_file1 = base_dir + "model2_" + season + "_mean_rsdt_no_plev_regridded.nc"

; Open observation file and read variable
obs_file_handle1 = addfile(obs_file1, "r")
obs1 = obs_file_handle1->solar_mon(0,:,:)

; Open model1 file and read variable
model1_file_handle1 = addfile(model1_file1, "r")
model11 = model1_file_handle1->rsdt(0,:,:)

; Open model2 file and read variable
model2_file_handle1 = addfile(model2_file1, "r")
model21 = model2_file_handle1->rsdt(0,:,:)

;====================================================
; TOA SW Files (Dynamic Season)
obs_file2 = base_dir + "obs_" + season + "_mean_toa_sw_all_mon_regridded.nc"
model1_file2 = base_dir + "model1_" + season + "_mean_rsut_no_plev.nc"
model2_file2 = base_dir + "model2_" + season + "_mean_rsut_no_plev_regridded.nc"

; Open observation file and read variable
obs_file_handle2 = addfile(obs_file2, "r")
obs2 = obs_file_handle2->toa_sw_all_mon(0,:,:)

; Open model1 file and read variable
model1_file_handle2 = addfile(model1_file2, "r")
model12 = model1_file_handle2->rsut(0,:,:)

; Open model2 file and read variable
model2_file_handle2 = addfile(model2_file2, "r")
model22 = model2_file_handle2->rsut(0,:,:)

;====================================================
; TOA LW Files (Dynamic Season)
obs_file3 = base_dir + "obs_" + season + "_mean_toa_lw_all_mon_regridded.nc"
model1_file3 = base_dir + "model1_" + season + "_mean_rlut_no_plev.nc"
model2_file3 = base_dir + "model2_" + season + "_mean_rlut_no_plev_regridded.nc"

; Open observation file and read variable
obs_file_handle3 = addfile(obs_file3, "r")
obs3 = obs_file_handle3->toa_lw_all_mon(0,:,:)

; Open model1 file and read variable
model1_file_handle3 = addfile(model1_file3, "r")
model13 = model1_file_handle3->rlut(0,:,:)

; Open model2 file and read variable
model2_file_handle3 = addfile(model2_file3, "r")
model23 = model2_file_handle3->rlut(0,:,:)


    ; Open observation file and read variable
    obs_file_handle3 = addfile(obs_file3, "r")
    obs3 = obs_file_handle3->toa_lw_all_mon(0,:,:)

    ; Open model1 file and read variable
    model1_file_handle3 = addfile(model1_file3, "r")
    model13 = model1_file_handle3->rlut(0,:,:)

    ; Open model2 file and read variable
    model2_file_handle3 = addfile(model2_file3, "r")
    model23 = model2_file_handle3->rlut(0,:,:)

toa_net_cer= obs1-(obs2+obs3)
toa_net_cmip7= model11-(model12+model13)
toa_net_cmip6= model21-(model22+model23)

copy_VarCoords(model11, toa_net_cer)
    copy_VarCoords(model21, toa_net_cmip7)
    copy_VarCoords(model11, toa_net_cmip6)
    ; Calculate biases
    bias_model1_obs = toa_net_cmip7 - toa_net_cer
    bias_model2_obs = toa_net_cmip6 - toa_net_cer
    bias_model1_model2 = toa_net_cmip7 - toa_net_cmip6

    ; Copy coordinates to biases
    copy_VarCoords(model11, bias_model1_obs)
    copy_VarCoords(model21, bias_model2_obs)
    copy_VarCoords(model11, bias_model1_model2)
;printVarSummary(bias_model1_obs)


; Define output workspace
    pltDir = "./bias_radiation_ann/"
    pltName = "TOA_NetDownard_Rad_bias_season"
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
    res_mean@cnFillPalette = "cmocean_delta"
    res_mean@cnLevelSelectionMode = "ManualLevels"
    res_mean@cnMinLevelValF = -180.0
    res_mean@cnMaxLevelValF = 180.0
    res_mean@cnLevelSpacingF = 20.0

    res_bias = res
    res_bias@cnFillPalette = "temp_diff_18lev"
    res_bias@cnLevelSelectionMode = "ManualLevels"
    res_bias@cnMinLevelValF = -80.0
    res_bias@cnMaxLevelValF = 80.0
    res_bias@cnLevelSpacingF = 5.0

    ; Plot each variable
    res_mean@gsnCenterString = "Observation"
    plot(0) = gsn_csm_contour_map(wks, toa_net_cer, res_mean)
    
res_bias@gsnCenterString = "Bias: CMIP7 - CMIP6"
    plot(1) = gsn_csm_contour_map(wks, bias_model1_model2, res_bias)

    res_mean@gsnCenterString = "CMIP7"
    plot(2) = gsn_csm_contour_map(wks, toa_net_cmip7, res_mean)
    

res_bias@gsnCenterString = "Bias: Model1 - Obs"
    plot(3) = gsn_csm_contour_map(wks, bias_model1_obs, res_bias)

    
res_mean@lbLabelBarOn          = True
    res@gsnCenterString = "CMIP6"
    plot(4) = gsn_csm_contour_map(wks, toa_net_cmip6, res_mean)

    
res_bias@lbLabelBarOn          = True    
    res@gsnCenterString = "Bias: CMIP6 - Obs"
    plot(5) = gsn_csm_contour_map(wks, bias_model2_obs, res_bias)

    
    ; Panel plots
    ; Panel-specific resources
    resP                = True
    resP@gsnMaximize    = True
    resP@gsnFrame       = False
    resP@gsnPanelLeft   = 0.005
    resP@gsnPanelBottom = 0.05 
    ;resP@gsnPanelSave   = True      ; Save the state of the paneled plots so we can
    resP@gsnPanelMainString = "TOA Netdownward(rsdt-(rsut+rlut))"
    ; Draw panel
    gsn_panel(wks, plot, (/3, 2/), resP)
  

    ; Finalize the plot
    frame(wks)
end

