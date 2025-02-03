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
    pltDir   = "./plots_ua_va/"
    pltName  = "ZonalWind_lat_annual_mean_bias_log"
    pltPath  = pltDir + pltName

    ob_u_file = base_dir + "obs_ua_regridded_ordered.nc"
    m1_u_file = base_dir + "model1_ua_annual_ordered.nc"
    m2_u_file = base_dir + "model2_ua_annual_ordered.nc"

    ;========================================================
    ; Open files and read variables
    ;========================================================
    f1 = addfile(ob_u_file, "r")
    obs_u = f1->u(0,:,:,:)

    f2 = addfile(m1_u_file, "r")
    model1_u = f2->ua(0,:,:,:)

    f3 = addfile(m2_u_file, "r")
    model2_u = f3->ua(0,:,:,:)

    ;========================================================
    ; Calculate biases
    ;========================================================
    bias1_u = model1_u - obs_u
    bias2_u = model2_u - obs_u
    bias3_u = model1_u - model2_u

    ; Copy coordinates and attributes
    copy_VarCoords(model1_u, bias1_u)
    copy_VarAtts(model1_u, bias1_u)

    copy_VarCoords(model2_u, bias2_u)
    copy_VarAtts(model2_u, bias2_u)

    copy_VarCoords(model1_u, bias3_u)
    copy_VarAtts(model1_u, bias3_u)

    ;========================================================
    ; Perform zonal averaging (average over longitude dimension)
    ;========================================================
    obs_avg = dim_avg_n_Wrap(obs_u, 2)
    model1_avg = dim_avg_n_Wrap(model1_u, 2)
    model2_avg = dim_avg_n_Wrap(model2_u, 2)
    ba1_avg = dim_avg_n_Wrap(bias1_u, 2)
    ba2_avg = dim_avg_n_Wrap(bias2_u, 2)
    ba3_avg = dim_avg_n_Wrap(bias3_u, 2)

    ;========================================================
    ; Define vertical pressure levels
    ;========================================================
    custom_ticks = (/1000,  500, 300, 200, 100, 50, 10,5,1/)  ; Preferred pressure levels

    ;========================================================
    ; Open graphics workstation and define plot resources
    ;========================================================
    wks = gsn_open_wks("pdf", pltPath)
    plot = new(3 * 2, "graphic")

    ; Common resources for all plots
    res = True
    res@gsnMaximize = True
    res@gsnFrame = False                   ; Don't advance the frame
    res@gsnDraw = False                    ; Don't draw immediately
    res@vpWidthF  = 0.9
    res@vpHeightF = 0.3
    res@cnFillOn = True                    ; Enable contour fill
    res@cnLinesOn = True                  ; Disable contour lines
    res@cnLineLabelsOn = False             ; Disable contour labels
    res@tmYLMode = "Explicit"              ; Explicitly set Y-axis labels
    res@tmYLValues = custom_ticks          ; Y-axis tick positions
    res@tmYLLabels = (/"1000",   "500", "300", "200", "100", "50", "10","5","1"/)
    res@trYReverse = True                  ; Reverse Y-axis (high to low pressure)
    res@gsnYAxisIrregular2Log = True       ; Logarithmic Y-axis for equidistant appearance
    res@lbTitleFontHeightF         = .02                ; make title smaller
    res@lbTitleString              = "m/s"            ; title string
    res@lbTitlePosition            = "Bottom"            ; title position
    res@lbTitleDirection           = "Across"            ; title direction
   
   res@lbBoxEndCapStyle = "TriangleBothEnds"
    res@lbOrientation = "horizontal"
    res@pmLabelBarOrthogonalPosF = 0.1
    res@pmLabelBarWidthF = 0.8 
   res@gsnLeftString = ""
   res@gsnRightString = ""
      ;
   res@tmYROn = False
    res@tmXTOn = False
    ; Resources for mean and bias plots
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
    res_bias@cnLevelSpacingF = 2.0

    ;========================================================
    ; Plot each variable
    ;========================================================
    res_mean@gsnCenterString = "Observation"
    plot(0) = gsn_csm_contour(wks, obs_avg({1000:1},:), res_mean)

    res_bias@gsnCenterString = " CMIP7 - CMIP6"
    plot(1) = gsn_csm_contour(wks, ba3_avg({1000:1},:), res_bias)

    res_mean@gsnCenterString = "CMIP7"
    plot(2) = gsn_csm_contour(wks, model1_avg({1000:1},:), res_mean)

    res_bias@gsnCenterString = " CMIP7 - Obs"
    plot(3) = gsn_csm_contour(wks, ba1_avg({1000:1},:), res_bias)

    res_mean@lbLabelBarOn = True
    res_mean@gsnCenterString = "CMIP6"
    plot(4) = gsn_csm_contour(wks, model2_avg({1000:1},:), res_mean)

    res_bias@lbLabelBarOn = True
    res_bias@gsnCenterString = " CMIP6 - Obs"
    plot(5) = gsn_csm_contour(wks, ba2_avg({1000:1},:), res_bias)

    ;========================================================
    ; Create panel plot
    ;========================================================
    resP = True
    resP@gsnMaximize = True
    resP@gsnFrame = False
    resP@gsnPanelLeft = 0.0005
    resP@gsnPanelBottom = 0.005
    resP@gsnPanelMainString = "Zonal Wind: Pressure vs. Latitude (Log Scale)"
    resP@gsnPanelScalePlotIndex = 0  ; Scale all plots to match the first plot
    gsn_panel(wks, plot, (/3, 2/), resP)

    ; Finalize the plot
    frame(wks)
end

