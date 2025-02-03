#!/bin/bash
# Script to calculate biases and plot annual data for rsdt, rlut, and rsut.
# ==============================================================================
# Copyright (C) 2025 Centre for Climate Change Research (CCCR), IITM
#
# This script is part of the CCCR IITM_ESM diagnostics system.
#
# Author: [Pritam Das Mahapatra]
# Date: January 2025
# ==============================================================================

# Function for error handling
function check_error {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Validate input arguments
if [ "$#" -lt 12 ]; then
    echo "Usage: $0 <obs_rsdt> <obs_rlut> <obs_rsut> <model1_rsdt> <model1_rlut> <model1_rsut> <projection> <lat_range> <lon_range> <season> [<model2_rsdt> <model2_rlut> <model2_rsut>]"
    exit 1
fi

# Assign input arguments
obs_rsdt="$1"
obs_rlut="$2"
obs_rsut="$3"
model1_rsdt="$4"
model1_rlut="$5"
model1_rsut="$6"
projection="$7"
lat_range="$8"
lon_range="$9"
season="${10}"
model2_rsdt="${11:-}"  # Optional
model2_rlut="${12:-}"  # Optional
model2_rsut="${13:-}"  # Optional

# Define output directory for biases
output_dir="./bias_radiation_ann"
mkdir -p "$output_dir"

# Output files
bias1_rsdt="${output_dir}/bias_model1_obs_annual_rsdt.nc"
bias2_rsdt="${output_dir}/bias_model2_obs_annual_rsdt.nc"
bias3_rsdt="${output_dir}/bias_model1_model2_annual_rsdt.nc"

bias1_rlut="${output_dir}/bias_model1_obs_annual_rlut.nc"
bias2_rlut="${output_dir}/bias_model2_obs_annual_rlut.nc"
bias3_rlut="${output_dir}/bias_model1_model2_annual_rlut.nc"

bias1_rsut="${output_dir}/bias_model1_obs_annual_rsut.nc"
bias2_rsut="${output_dir}/bias_model2_obs_annual_rsut.nc"
bias3_rsut="${output_dir}/bias_model1_model2_annual_rsut.nc"

# Calculate biases for rsdt
echo "Calculating biases for rsdt..."
if [ ! -f "$bias1_rsdt" ]; then
    cdo sub "$model1_rsdt" "$obs_rsdt" "$bias1_rsdt"
    check_error "Calculating bias for Model 1 - Obs (annual rsdt)"
fi

if [ -n "$model2_rsdt" ] && [ ! -f "$bias2_rsdt" ]; then
    cdo sub "$model2_rsdt" "$obs_rsdt" "$bias2_rsdt"
    check_error "Calculating bias for Model 2 - Obs (annual rsdt)"
fi

if [ -n "$model2_rsdt" ] && [ ! -f "$bias3_rsdt" ]; then
    cdo sub "$model1_rsdt" "$model2_rsdt" "$bias3_rsdt"
    check_error "Calculating bias for Model 1 - Model 2 (annual rsdt)"
fi

# Calculate biases for rlut
echo "Calculating biases for rlut..."
if [ ! -f "$bias1_rlut" ]; then
    cdo sub "$model1_rlut" "$obs_rlut" "$bias1_rlut"
    check_error "Calculating bias for Model 1 - Obs (annual rlut)"
fi

if [ -n "$model2_rlut" ] && [ ! -f "$bias2_rlut" ]; then
    cdo sub "$model2_rlut" "$obs_rlut" "$bias2_rlut"
    check_error "Calculating bias for Model 2 - Obs (annual rlut)"
fi

if [ -n "$model2_rlut" ] && [ ! -f "$bias3_rlut" ]; then
    cdo sub "$model1_rlut" "$model2_rlut" "$bias3_rlut"
    check_error "Calculating bias for Model 1 - Model 2 (annual rlut)"
fi

# Calculate biases for rsut
echo "Calculating biases for rsut..."
if [ ! -f "$bias1_rsut" ]; then
    cdo sub "$model1_rsut" "$obs_rsut" "$bias1_rsut"
    check_error "Calculating bias for Model 1 - Obs (annual rsut)"
fi

if [ -n "$model2_rsut" ] && [ ! -f "$bias2_rsut" ]; then
    cdo sub "$model2_rsut" "$obs_rsut" "$bias2_rsut"
    check_error "Calculating bias for Model 2 - Obs (annual rsut)"
fi

if [ -n "$model2_rsut" ] && [ ! -f "$bias3_rsut" ]; then
    cdo sub "$model1_rsut" "$model2_rsut" "$bias3_rsut"
    check_error "Calculating bias for Model 1 - Model 2 (annual rsut)"
fi

# Debugging Information
echo "Bias calculations completed. Output files are saved in $output_dir."

ncl rlut_mean_bias_ann.ncl
ncl rsut_mean_bias_ann.ncl
ncl toa_rad_mean_bias_ann.ncl




# Define the target grid file

inputdir="./output_data"
targetgrid="${inputdir}/model1_grid.txt"

# Define input and output files for each variable
# Shortwave (SW) radiation variables
obs_rsdt_input="${inputdir}/obs_solar_mon_all_years.nc"
obs_rsdt_output="${inputdir}/obs_solar_mon_all_years_regrid.nc"

model2_rsdt_input="${inputdir}/model2_rsdt_annual_all_year_no_plev.nc"
model2_rsdt_output="${inputdir}/model2_rsdt_annual_all_year_no_plev_regrid.nc"

obs_rsut_input="${inputdir}/obs_toa_sw_all_mon_all_years.nc"
obs_rsut_output="${inputdir}/obs_toa_sw_all_mon_all_years_regrid.nc"

model2_rsut_input="${inputdir}/model2_rsut_annual_all_year_no_plev.nc"
model2_rsut_output="${inputdir}/model2_rsut_annual_all_year_no_plev_regrid.nc"

# Longwave (LW) radiation variables
obs_rlut_input="${inputdir}/obs_toa_lw_all_mon_all_years.nc"
obs_rlut_output="${inputdir}/obs_toa_lw_all_mon_all_years_regrid.nc"

model2_rlut_input="${inputdir}/model2_rlut_annual_all_year_no_plev.nc"
model2_rlut_output="${inputdir}/model2_rlut_annual_all_year_no_plev_regrid.nc"

# Regridding function
function regrid_file {
    local input_file=$1
    local output_file=$2

    if [ ! -f "$output_file" ]; then
        echo "Regridding $input_file to $output_file..."
        cdo remapbil,$targetgrid "$input_file" "$output_file"
        if [ $? -ne 0 ]; then
            echo "Error: Regridding failed for $input_file."
            exit 1
        fi
    else
        echo "Regridded file $output_file already exists. Skipping..."
    fi
}

# Perform regridding for each file
echo "Starting regridding of radiation variables..."

# Shortwave radiation
regrid_file "$obs_rsdt_input" "$obs_rsdt_output"
regrid_file "$model2_rsdt_input" "$model2_rsdt_output"
regrid_file "$obs_rsut_input" "$obs_rsut_output"
regrid_file "$model2_rsut_input" "$model2_rsut_output"

# Longwave radiation
regrid_file "$obs_rlut_input" "$obs_rlut_output"
regrid_file "$model2_rlut_input" "$model2_rlut_output"

echo "Regridding completed for all SW and LW radiation variables."



# Define input files for each variable
inputdir="./output_data"
# Shortwave (SW) radiation variables
obs_rsdt_regrid="${inputdir}/obs_solar_mon_all_years_regrid.nc"
model1_rsdt="${inputdir}/model1_rsdt_annual_all_year_no_plev.nc"
model2_rsdt_regrid="${inputdir}/model2_rsdt_annual_all_year_no_plev_regrid.nc"

obs_rsut_regrid="${inputdir}/obs_toa_sw_all_mon_all_years_regrid.nc"
model1_rsut="${inputdir}/model1_rsut_annual_all_year_no_plev.nc"
model2_rsut_regrid="${inputdir}/model2_rsut_annual_all_year_no_plev_regrid.nc"

# Longwave (LW) radiation variables
obs_rlut_regrid="${inputdir}/obs_toa_lw_all_mon_all_years_regrid.nc"
model1_rlut="${inputdir}/model1_rlut_annual_all_year_no_plev.nc"
model2_rlut_regrid="${inputdir}/model2_rlut_annual_all_year_no_plev_regrid.nc"

# Output files for field means
output_dir="./bias_radiation_ann"
mkdir -p "$output_dir"

obs_rsdt_fldmean="${output_dir}/fldmean_obs_rsdt.nc"
model1_rsdt_fldmean="${output_dir}/fldmean_model1_rsdt.nc"
model2_rsdt_fldmean="${output_dir}/fldmean_model2_rsdt.nc"

obs_rsut_fldmean="${output_dir}/fldmean_obs_rsut.nc"
model1_rsut_fldmean="${output_dir}/fldmean_model1_rsut.nc"
model2_rsut_fldmean="${output_dir}/fldmean_model2_rsut.nc"

obs_rlut_fldmean="${output_dir}/fldmean_obs_rlut.nc"
model1_rlut_fldmean="${output_dir}/fldmean_model1_rlut.nc"
model2_rlut_fldmean="${output_dir}/fldmean_model2_rlut.nc"

# Function to calculate field mean
function calculate_fldmean {
    local input_file=$1
    local output_file=$2

    if [ ! -f "$output_file" ]; then
        echo "Calculating field mean for $input_file..."
        cdo fldmean "$input_file" "$output_file"
        if [ $? -ne 0 ]; then
            echo "Error: Field mean calculation failed for $input_file."
            exit 1
        fi
    else
        echo "Field mean file $output_file already exists. Skipping..."
    fi
}

# Perform field mean calculations
echo "Starting field mean calculations for radiation variables..."

# Shortwave radiation
calculate_fldmean "$obs_rsdt_regrid" "$obs_rsdt_fldmean"
calculate_fldmean "$model1_rsdt" "$model1_rsdt_fldmean"
calculate_fldmean "$model2_rsdt_regrid" "$model2_rsdt_fldmean"

calculate_fldmean "$obs_rsut_regrid" "$obs_rsut_fldmean"
calculate_fldmean "$model1_rsut" "$model1_rsut_fldmean"
calculate_fldmean "$model2_rsut_regrid" "$model2_rsut_fldmean"

# Longwave radiation
calculate_fldmean "$obs_rlut_regrid" "$obs_rlut_fldmean"
calculate_fldmean "$model1_rlut" "$model1_rlut_fldmean"
calculate_fldmean "$model2_rlut_regrid" "$model2_rlut_fldmean"

echo "Field mean calculations completed for all radiation variables."

ncl toa_rad_timeseries.ncl

check_error "Plotting radiation variables (annual)"
echo "Radiation plotting for annual data completed successfully."

