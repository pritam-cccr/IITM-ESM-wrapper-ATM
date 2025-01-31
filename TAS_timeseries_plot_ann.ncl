; Load necessary libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
    ;========================================================
    ; Set paths and filenames
    ;========================================================
    base_dir = "./output_data/"
    pltDir   = "./plots_tas/"
    pltName  = "Tas_annual_and_monthly_panel"
    pltPath  = pltDir + pltName

    model1_file = base_dir + "model1_tas_all_year_fldmean_no_plev.nc"
    model2_file = base_dir + "model2_tas_all_year_fldmean_no_plev.nc"

    ;========================================================
    ; Open NetCDF files and read variables
    ;========================================================
    f1 = addfile(model1_file, "r")
    f2 = addfile(model2_file, "r")

    ; Read temperature variables
    m1 = f1->tas
    m2 = f2->tas
    time1 = m1&time
    time2 = m2&time

    ; Convert from Kelvin to Celsius
    m1_c = m1(:, 0, 0) - 273.15  ; Model 1 monthly data
    m2_c = m2(:, 0, 0) - 273.15  ; Model 2 monthly data

    ;========================================================
    ; Compute Annual Averages and Align Data
    ;========================================================
    ; Constants
    n_months = 12

    ; Model 1: Reshape and compute annual averages
    ntime1 = dimsizes(m1_c)
    n_years1 = ntime1 / n_months
    m1_reshaped = reshape(m1_c, (/n_years1, n_months/))
    m1_annual = dim_avg_n_Wrap(m1_reshaped, 1)

    ; Extend Model 1 annual averages
    m1_anom_extended = new(ntime1, typeof(m1_c), getFillValue(m1_c))
    do i = 0, n_years1 - 1
        m1_anom_extended(i * n_months:(i + 1) * n_months - 1) = m1_annual(i)
    end do

    ; Model 2: Reshape and compute annual averages
    ntime2 = dimsizes(m2_c)
    n_years2 = ntime2 / n_months
    m2_reshaped = reshape(m2_c, (/n_years2, n_months/))
    m2_annual = dim_avg_n_Wrap(m2_reshaped, 1)

    ; Extend Model 2 annual averages
    m2_anom_extended = new(ntime2, typeof(m2_c), getFillValue(m2_c))
    do i = 0, n_years2 - 1
        m2_anom_extended(i * n_months:(i + 1) * n_months - 1) = m2_annual(i)
    end do

    ;========================================================
    ; Create a graphics workstation
    ;========================================================
    wks = gsn_open_wks("png", pltPath)
    

    ;========================================================
    ; Define plot resources
    ;========================================================
    res = True
    res@gsnMaximize = False        ; Let `gsn_panel` manage dimensions
    res@xyLineThicknessF = 2.0     ; Line thickness
    res@gsnDraw           = False
        res@gsnFrame          = False
    res@xyLineColors = (/"black", "red","blue"/)  ; Line colors for monthly and annual series
    
    res@tiYAxisString = "Temperature ([~S~o~N~C])"
    res@trYMinF = 10  
    res@trYMaxF = 20  
    res@tmYROn=False
    res@tmXTOn=False
    
    
    
    res@trXMinF = 0
    res@trXMaxF = ntime1  
    
    
    
    
res@vpWidthF         = 0.8                      ; set width and height
  res@vpHeightF        = 0.3
    ;========================================================
    ; Create Individual Plots
    ;========================================================
    ; Model 1 Plot
    res@tiMainString = "CMIP7 TAS"
    data1 = new((/3, ntime1/), typeof(m1_c), getFillValue(m1_c))
    data1(0, :) = m1_c
    data1(1, :) = m1_anom_extended
    data1(2,:)=15
    res@vpXF             = 0.15
  res@vpYF             = 0.9
    plot1 = gsn_csm_xy(wks, ispan(0, ntime1 - 1, 1), data1, res)

    ; Model 2 Plot
    res@tiMainString = "CMIP6(1990-2014)"
    data2 = new((/3, ntime2/), typeof(m2_c), getFillValue(m2_c))
    data2(0, :) = m2_c
    data2(1, :) = m2_anom_extended
    data2(2,:) = 15
    res@vpXF             = 0.15
  res@vpYF             = 0.4
  
  res@trXMinF = 0
    res@trXMaxF = ntime2  
    plot2 = gsn_csm_xy(wks, ispan(0, ntime2 - 1, 1), data2, res)

    ;========================================================
    ; Combine Plots into a Panel
    ;========================================================
    psres = True                                                               
  maximize_output(wks,psres)  ; calls draw and frame for you 
    ;gsn_panel(wks, plot, (/2, 1/), panel_res)  ; 2 rows, 1 column

end

