load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
  ;--- Define file paths
  shapefile_dir = "./India-State-and-Country-Shapefile-Updated-Jan-2020-master/"
  shapefile_name = "India_Country_Boundary.shp"
  shapefile_path = shapefile_dir + shapefile_name

  base_dir = "./output_data/"
  model1_file = base_dir + "model1_pr_annual_all_year_no_plev_regrid.nc"
  model2_file = base_dir + "model2_pr_annual_all_year_no_plev_regrid.nc"
  obs_file    = base_dir + "obs_precip_all_years_regrid.nc"



  ;========================================================
  ; Open shapefile and read coordinates
  ;========================================================
  shp_file = addfile(shapefile_path, "r")
  shp_lon = tofloat(shp_file->y)
  shp_lat = tofloat(shp_file->x)

  ; Print shapefile bounds
  print("Shapefile Latitude Bounds: " + min(shp_lat) + " to " + max(shp_lat))
  print("Shapefile Longitude Bounds: " + min(shp_lon) + " to " + max(shp_lon))
  

  ;========================================================
  ; Open NetCDF files and read data
  ;========================================================
  f1 = addfile(model1_file, "r")
  f2 = addfile(model2_file, "r")
  f3 = addfile(obs_file, "r")

  ; Print dataset bounds for validation
  print("Dataset Latitude Bounds: " + min(f1&latitude) + " to " + max(f1&latitude))
  print("Dataset Longitude Bounds: " + min(f1&longitude) + " to " + max(f1&longitude))

  ;========================================================
  ; Adjust shapefile bounds to fit within dataset bounds
  ;========================================================
    
; Extract shapefile bounds (ensure scalar values)
shp_min_lat = min(tofloat(shp_lat))
shp_max_lat = max(tofloat(shp_lat))
shp_min_lon = min(tofloat(shp_lon))
shp_max_lon = max(tofloat(shp_lon))

; Extract dataset bounds (ensure scalar values)
data_min_lat = min(tofloat(f1&latitude))
data_max_lat = max(tofloat(f1&latitude))
data_min_lon = min(tofloat(f1&longitude))
data_max_lon = max(tofloat(f1&longitude))

; Initialize adjusted bounds with shapefile bounds
min_shp_lat = shp_min_lat
max_shp_lat = shp_max_lat
min_shp_lon = shp_min_lon
max_shp_lon = shp_max_lon

; Adjust minimum latitude
if (shp_min_lat .lt. data_min_lat) then
  min_shp_lat = data_min_lat
end if

; Adjust maximum latitude
if (shp_max_lat .gt. data_max_lat) then
  max_shp_lat = data_max_lat
end if

; Adjust minimum longitude
if (shp_min_lon .lt. data_min_lon) then
  min_shp_lon = data_min_lon
end if

; Adjust maximum longitude
if (shp_max_lon .gt. data_max_lon) then
  max_shp_lon = data_max_lon
end if

; Debugging outputs
print("Adjusted Latitude Bounds: " + min_shp_lat + " to " + max_shp_lat)
print("Adjusted Longitude Bounds: " + min_shp_lon + " to " + max_shp_lon)




  ;========================================================
  ; Subset the data using adjusted bounds
  ;========================================================
  m1 = f1->pr(:, {min_shp_lat:max_shp_lat}, {min_shp_lon:max_shp_lon})
  m2 = f2->pr(:, {min_shp_lat:max_shp_lat}, {min_shp_lon:max_shp_lon})
  ob = f3->precip(:, {min_shp_lat:max_shp_lat}, {min_shp_lon:max_shp_lon})

;========================================================
; Precompute the mask
;========================================================

; Create 2D latitude and longitude grids
lat2D = conform_dims((/dimsizes(m1&latitude), dimsizes(m1&longitude)/), m1&latitude, 0)
lon2D = conform_dims((/dimsizes(m1&latitude), dimsizes(m1&longitude)/), m1&longitude, 1)

; Flatten grids for gc_inout
lat_flat = reshape(lat2D, (/dimsizes(lat2D)/))  ; Total size of lat2D
lon_flat = reshape(lon2D, (/dimsizes(lon2D)/))  ; Total size of lon2D

; Compute the mask
region_mask_flat = gc_inout(lat_flat, lon_flat, shp_lat, shp_lon)

; Reshape mask back to 2D
region_mask = reshape(region_mask_flat, dimsizes(lat2D))
printVarSummary(region_mask)

; Debugging: Check the mask
printVarSummary(region_mask)
printMinMax(region_mask, 0)

; Broadcast 2D mask to 3D
region_mask_3D = conform_dims(dimsizes(m1), region_mask, (/1, 2/))  ; Add time dimension

; Debugging: Check mask dimensions
printVarSummary(region_mask_3D)

; Apply the mask to all datasets
m1_pmask = where(region_mask_3D, m1, m1@_FillValue)
m2_pmask = where(region_mask_3D, m2, m2@_FillValue)
ob_pmask = where(region_mask_3D, ob, ob@_FillValue)

; Debugging: Check masked data
printVarSummary(m1_pmask)
printMinMax(m1_pmask, 0)



  ;========================================================
  ; Compute Monthly Climatology
  ;========================================================
  m1_clim = clmMonTLL(m1_pmask)  ; Model 1 climatology
  m2_clim = clmMonTLL(m2_pmask)  ; Model 2 climatology
  ob_clim = clmMonTLL(ob_pmask)  ; Observation climatology

  ; Convert climatology to mm/day (if applicable)
  global_mean1 = dim_avg_n_Wrap(m1_clim, (/1,2/)) * 86400
  global_mean2 = dim_avg_n_Wrap(m2_clim, (/1,2/)) * 86400
  global_mean3 = dim_avg_n_Wrap(ob_clim, (/1,2/))

  ; Print summaries and min/max for debugging
  printVarSummary(m1_clim)
  printVarSummary(m2_clim)
  printVarSummary(ob_clim)

  printMinMax(global_mean1, 0)
  printMinMax(global_mean2, 0)
  printMinMax(global_mean3, 0)
end


/;

    ; Get the time dimension
    
    time_indices = ispan(0,11, 1)  ; Generate time indices for plotting

    ;========================================================
    ; Create a graphics workstation
    ;========================================================
    wks = gsn_open_wks("pdf", pltPath)

    ;========================================================
    ; Define plot resources
    ;========================================================
    res = True
    res@gsnMaximize           = True        ; Maximize plot in the frame
    res@vpWidthF         = 0.8                      ; set width and height
  res@vpHeightF        = 0.3
    res@xyLineThicknessF       = 2.0        ; Set line thickness
    res@tmLabelAutoStride      = True       ; Auto stride for time labels
    res@tiMainString           = "Climatology Precipitation (mm/day) [INDIA]"
    res@tiMainFontHeightF=0.02
    res@trYMinF                = 0        ; Set Y-axis minimum (adjust as needed)
   res@trYMaxF                = 4         ; Set Y-axis maximum (adjust as needed)
    res@trXMinF                = 0        ; Set Y-axis minimum (adjust as needed)
    res@trXMaxF                = 11         ; Set Y-axis maximum (adjust as needed)

    ; Set legend resources
    res@pmLegendDisplayMode    = "Always"   ; Always display the legend
    res@pmLegendWidthF         = 0.1        ; Set legend width
    res@pmLegendHeightF        = 0.1       ; Set legend height
    res@pmLegendParallelPosF   = 0.9       ; Move legend horizontally
    res@pmLegendOrthogonalPosF = -0.3      ; Move legend vertically
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
;/
