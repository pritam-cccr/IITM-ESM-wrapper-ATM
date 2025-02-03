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
    pltDir   =  "./plots_tas/"
    pltName  = "Tas_annual_timeseries"
    pltPath  = pltDir + pltName

    model1_file = base_dir + "model1_tas_all_year_fldmean_no_plev.nc"
    model2_file = base_dir + "model2_tas_all_year_fldmean_no_plev.nc"
    obs_file    = base_dir + "obs_t2m_all_years_fldmean.nc"

    ;========================================================
    ; Open NetCDF files and read variables
    ;========================================================
    f1 = addfile(model1_file, "r")
    f2 = addfile(model2_file, "r")
    f3 = addfile(obs_file, "r")

    ; Read the temperature variables
    m1 = f1->tas
    m2 = f2->tas
    ob = f3->t2m

    ; Convert from Kelvin to Celsius
    m1_c = m1(:, 0, 0) - 273.15
    m2_c = m2(:, 0, 0) - 273.15
    ob_c = ob(:, 0, 0) - 273.15

; Number of time steps for 30 years
n_time1 = dimsizes(m1&time)       ; Full time length of `m1` (30 years)
n_time2 = dimsizes(m2&time)       ; Time length of `m2` (24 years)
n_time3 = dimsizes(ob&valid_time) ; Full time length of `ob` (30 years)

; Extend `m2` to 30 years with `_FillValue`
_FillValue = -9999.0  ; Define or extract `_FillValue` (use actual if available)
m2_extended = new(n_time1, typeof(m2_c), _FillValue)  ; Create extended array
m2_extended(0:n_time2-1) = m2_c                       ; Assign existing `m2` data
;;;;;;;
; Use `m1&time` as the common 30-year time axis
common_time_30 = m1&time

; Combine datasets
data = (/m1_c, m2_extended, ob_c/)


    ;========================================================
    ; Create a graphics workstation
    ;========================================================
    wks = gsn_open_wks("pdf", pltPath)

    ;========================================================
    ; Define plot resources
    ;========================================================
    res = True
    res@gsnMaximize           = True        ; Maximize plot in the frame
    res@xyLineThicknessF      = 2.0         ; Set line thickness
    res@tmLabelAutoStride     = True        ; Auto stride for time labels
    res@trYMinF               = 10          ; Set Y-axis minimum (adjust as needed)
    res@trYMaxF               = 20          ; Set Y-axis maximum (adjust as needed)
    res@pmLegendDisplayMode   = "Always"    ; Always display the legend
    res@pmLegendWidthF        = 0.1         ; Set legend width
    res@pmLegendHeightF       = 0.1         ; Set legend height
    res@pmLegendParallelPosF  = 0.9         ; Move legend horizontally
    res@pmLegendOrthogonalPosF = -0.3       ; Move legend vertically
    res@lgPerimOn             = False       ; No border around the legend
    res@xyExplicitLegendLabels = (/"CMIP7", "CMIP6", "OBS"/)  ; Legend labels
    res@xyLineColors          = (/"blue", "red", "black"/)    ; Line colors for datasets
    res@xyExplicitLegendLabels = (/"CMIP7", "CMIP6(Hist)", "Observations"/)
res@tmXBMode = "Explicit"
res@tmXBValues = ispan(0, dimsizes(common_time_30) - 1, 1)
res@tmXBLabels = sprinti("%i", common_time_30)  ; X-axis labels based on `m1&time`


    ;========================================================
    ; Plot all datasets
    ;========================================================
       plot = gsn_csm_xy(wks, ispan(0, dimsizes(m2&time) - 1, 1), data, res)

    ;========================================================
    ; Advance the frame
    ;========================================================
    frame(wks)

end

