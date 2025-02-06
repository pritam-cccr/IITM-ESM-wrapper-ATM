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
    ;========================================================
    ; Define file paths and read data
    ;========================================================
    base_dir = "./bias_radiation_ann/"
    obs_file1 = base_dir + "fldmean_obs_rsdt.nc"
    model1_file1 = base_dir + "fldmean_model1_rsdt.nc"
    model2_file1 = base_dir + "fldmean_model2_rsdt.nc"

    obs_file2 = base_dir + "fldmean_obs_rsut.nc"
    model1_file2 = base_dir + "fldmean_model1_rsut.nc"
    model2_file2 = base_dir + "fldmean_model2_rsut.nc"

    obs_file3 = base_dir + "fldmean_obs_rlut.nc"
    model1_file3 = base_dir + "fldmean_model1_rlut.nc"
    model2_file3 = base_dir + "fldmean_model2_rlut.nc"

    ; Open files
    obs_handle1 = addfile(obs_file1, "r")
    model1_handle1 = addfile(model1_file1, "r")
    model2_handle1 = addfile(model2_file1, "r")

    obs_handle2 = addfile(obs_file2, "r")
    model1_handle2 = addfile(model1_file2, "r")
    model2_handle2 = addfile(model2_file2, "r")

    obs_handle3 = addfile(obs_file3, "r")
    model1_handle3 = addfile(model1_file3, "r")
    model2_handle3 = addfile(model2_file3, "r")

    ;========================================================
    ; Read variables from files
    ;========================================================
    obs1 = obs_handle1->solar_mon(:,0,0)    ; RSdt from observations
    model11 = model1_handle1->rsdt(:,0,0)  ; RSdt from Model1
    model21 = model2_handle1->rsdt(:,0,0)  ; RSdt from Model2

    obs2 = obs_handle2->toa_sw_all_mon(:,0,0)  ; RSut from observations
    model12 = model1_handle2->rsut(:,0,0)     ; RSut from Model1
    model22 = model2_handle2->rsut(:,0,0)     ; RSut from Model2

    obs3 = obs_handle3->toa_lw_all_mon(:,0,0)  ; RLut from observations
    model13 = model1_handle3->rlut(:,0,0)     ; RLut from Model1
    model23 = model2_handle3->rlut(:,0,0)     ; RLut from Model2

    ;========================================================
    ; Compute TOA net radiation
    ;========================================================
    toa_net_obs = obs1 - (obs2 + obs3)
    toa_net_model1 = model11 - (model12 + model13)
    toa_net_model2 = model21 - (model22 + model23)

    ; Copy coordinates
    copy_VarCoords(obs1, toa_net_obs)
    copy_VarCoords(model11, toa_net_model1)
    copy_VarCoords(model21, toa_net_model2)



   ;========================================================
; Compute Annual Means
;========================================================
toa_net_obs_annual = dim_avg_n_Wrap(reshape(toa_net_obs, (/dimsizes(toa_net_obs)/12, 12/)), 1)
toa_net_model1_annual = dim_avg_n_Wrap(reshape(toa_net_model1, (/dimsizes(toa_net_model1)/12, 12/)), 1)
toa_net_model2_annual = dim_avg_n_Wrap(reshape(toa_net_model2, (/dimsizes(toa_net_model2)/12, 12/)), 1)
;printVarSummary(toa_net_model2_annual)
;printVarSummary(toa_net_obs_annual)
;========================================================
; Define Time Indices for Model1
;========================================================
ntime_model1 = dimsizes(toa_net_model1_annual)          ; Number of annual data points for Model1
time_indices_model1 = ispan(0, ntime_model1 - 1, 1)     ; Create indices for Model1


;========================================================
    ; Define output path
    ;========================================================
    pltDir = "./bias_radiation_ann/"
    pltName = "TOA_rad_timeseries_two_panel"
    pltPath = pltDir + pltName

    ; Open graphics workstation
    wks = gsn_open_wks("png", pltPath)

    ;========================================================
;========================================================
; Create Plot for Model1 (Standalone: Panel 1)
;========================================================
res1 = True
res1@tiMainString = " (Annual Mean): CMIP7"
res1@tiMainFontHeightF = 0.02   ; Adjust font size (default is larger)
res1@xyLineColors = (/"blue"/)                       ; Line color for Model1
res1@xyLineThicknessF = 2.0                          ; Line thickness
res1@trXMinF = 0                                     ; X-axis starts at index 0
res1@trXMaxF = ntime_model1 - 1                      ; X-axis ends at the last index
res1@trYMinF = -3                                   ; Minimum Y-axis value
res1@trYMaxF = 3                                    ; Maximum Y-axis value
res1@gsnFrame = False                  ; Don't advance the frame
    res1@gsnDraw = False                   ; Don't draw immediately
plot1 = gsn_csm_xy(wks, time_indices_model1, toa_net_model1_annual, res1)

;========================================================
; Define Year Ranges
;========================================================
x_model2_years = ispan(1990, 2014, 1)  ; Years for Model2
x_obs_years = ispan(2001, 2020, 1)     ; Years for Obs

;========================================================
; Create Base Plot for Model2
;========================================================
res2 = True
res2@tiMainString = " (Annual Mean): CMIP6 and Obs"
res2@tiMainFontHeightF = 0.02   ; Adjust font size (default is larger)
res2@xyLineColors = (/"red"/)                        ; Line color for Model2
res2@xyLineThicknessF = 2.0                          ; Line thickness
res2@trXMinF = 1990                                  ; Start X-axis at 1990
res2@trXMaxF = 2020                                  ; End X-axis at 2020
res2@trYMinF = -2                                  ; Minimum Y-axis value
res2@trYMaxF = 2                                    ; Maximum Y-axis value
res2@gsnFrame = False                  ; Don't advance the frame
    res2@gsnDraw = False                   ; Don't draw immediately


; Legend settings
res2@pmLegendDisplayMode = "Always"                   ; Always display the legend
res2@pmLegendWidthF = 0.2                              ; Width of the legend box
res2@pmLegendHeightF = 0.1                             ; Height of the legend box
res2@pmLegendParallelPosF = 0.7                       ; Center the legend horizontally
res2@pmLegendOrthogonalPosF = -0.4                     ; Position legend below the plot
res2@lgPerimOn = False                                 ; Remove border around legend
res2@xyExplicitLegendLabels = (/"CMIP6", "Obs"/)      ; Legend labels for Model2 and Obs



; Set explicit X-axis labels
res2@tmXBMode = "Explicit"                           ; Explicit X-axis labeling
res2@tmXBValues = ispan(1990, 2020, 5)               ; Tick marks every 5 years
res2@tmXBLabels = (/"1990", "1995", "2000", "2005", "2010", "2015", "2020"/)

; Plot Model2 with Year-Based X-Axis
plot_model2 = gsn_csm_xy(wks, x_model2_years, toa_net_model2_annual, res2)

;========================================================
; Overlay Plot for Obs
;========================================================
res3 = True
res3@xyLineColors = (/"black"/)                      ; Line color for Obs
res3@xyLineThicknessF = 2.0                          ; Line thickness
res3@trXMinF = 1990                                  ; Align X-axis with 1990
res3@trXMaxF = 2020                                  ; Align X-axis with 2020
res3@trYMinF = -2                                  ; Ensure shared Y-axis range
res3@trYMaxF = 2                                    ; Ensure shared Y-axis range
res3@gsnFrame = False                  ; Don't advance the frame
    res3@gsnDraw = False                   ; Don't draw immediately
; Plot Obs with Year-Based X-Axis
plot_obs = gsn_csm_xy(wks, x_obs_years, toa_net_obs_annual, res3)

;========================================================
; Overlay Obs on Model2
;========================================================
NhlAddOverlay(plot_model2, plot_obs, plot_model2)          ; Overlay Obs on Model2
; Draw the overlaid plot

;========================================================
; Combine Both Panels
;========================================================
resP = True
resP@gsnMaximize = True
resP@gsnPanelMainString = "TOA Net Radiation"
resP@gsnPanelMainFontHeightF = 0.02   ; Adjust font size (default is larger)
resP@gsnPanelScalePlotIndex = 0  ; Scale all plots to match the first plot
gsn_panel(wks, (/plot1, plot_model2/), (/2, 1/), resP)



end
