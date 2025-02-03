#!/bin/bash
# DESCRIPTION: Specialized plotting script for hght (geopotential height) with bias calculation and plotting
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
if [ "$#" -lt 5 ]; then
    echo "Usage: $0 <obs_annual_regridded_hght> <model1_annual_hght> <projection> <lat_range> <lon_range> [<model2_annual_hght>]"
    exit 1
fi

# Input arguments
obs_annual_hght="$1"
model1_annual_hght="$2"
projection="$3"
lat_range="$4"
lon_range="$5"
season="$6"
model2_annual_hght="${7:-}"  # Optional

# Output directory
output_dir="./plots_hght"
mkdir -p "$output_dir"

# Desired pressure levels in descending order
pressure_levels=(1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 10 5 1)

# Function to reorder pressure levels
reorder_pressure_levels() {
    input_file="$1"       # Input file
    output_file="$2"      # Output file
    var="hght"            # Variable name
    temp_files=()

    if [ -f "$output_file" ]; then
        echo "File $output_file already exists. Skipping reordering for $var."
        return
    fi

    echo "Reordering pressure levels for file: $input_file (Variable: $var)"

    for p in "${pressure_levels[@]}"; do
        temp_file="${output_dir}/temp_${var}_level_${p}.nc"
        cdo sellevel,$p "$input_file" "$temp_file"
        check_error "Selecting pressure level $p for $var"
        temp_files+=("$temp_file")
    done

    # Merge all selected levels into the output file
    cdo merge "${temp_files[@]}" "$output_file"
    check_error "Merging reordered pressure levels for $var"

    # Clean up temporary files
    rm -f "${temp_files[@]}"
    echo "Reordered file for $var saved as: $output_file"
}

# Define file paths for reordered outputs
obs_hght_output="${output_dir}/obs_hght_regridded_ordered.nc"
model1_hght_output="${output_dir}/model1_hght_annual_ordered.nc"
model2_hght_output="${output_dir}/model2_hght_annual_ordered.nc"

# Reorder pressure levels for observation hght
reorder_pressure_levels "$obs_annual_hght" "$obs_hght_output"

# Reorder pressure levels for Model 1 hght
reorder_pressure_levels "$model1_annual_hght" "$model1_hght_output"

# Reorder pressure levels for Model 2 hght (if provided)
if [ -n "$model2_annual_hght" ]; then
    reorder_pressure_levels "$model2_annual_hght" "$model2_hght_output"
fi

# Bias Calculation (850 hPa and 200 hPa)
bias_obs_model1_hght_850="${output_dir}/bias_obs_model1_hght_850.nc"
bias_obs_model1_hght_200="${output_dir}/bias_obs_model1_hght_200.nc"

bias_obs_model2_hght_850="${output_dir}/bias_obs_model2_hght_850.nc"
bias_obs_model2_hght_200="${output_dir}/bias_obs_model2_hght_200.nc"

bias_model1_model2_hght_850="${output_dir}/bias_model1_model2_hght_850.nc"
bias_model1_model2_hght_200="${output_dir}/bias_model1_model2_hght_200.nc"

obs_hght_850="${output_dir}/obs_hght_850.nc"
obs_hght_200="${output_dir}/obs_hght_200.nc"
model1_hght_850="${output_dir}/model1_hght_850.nc"
model1_hght_200="${output_dir}/model1_hght_200.nc"
model2_hght_850="${output_dir}/model2_hght_850.nc"
model2_hght_200="${output_dir}/model2_hght_200.nc"

echo "Calculating bias for 850 hPa and 200 hPa..."

echo "Scaling observation files from geopotential to geopotential height..."

scaled_obs_hght_output="${output_dir}/obs_hght_scaled.nc"

if [ ! -f "$scaled_obs_hght_output" ]; then
    cdo divc,9.80665 "$obs_hght_output" "$scaled_obs_hght_output"
    check_error "Scaling observation file to geopotential height"
else
    echo "Scaled observation file $scaled_obs_hght_output already exists. Skipping scaling..."
fi

# Update `obs_hght_output` to the scaled file for further calculations
obs_hght_output_s="$scaled_obs_hght_output"

echo "Scaling completed. Proceeding with bias calculations..."

echo "Calculating bias for 850 hPa and 200 hPa..."

# Extract 850 hPa and 200 hPa levels for hght
cdo sellevel,850 "$obs_hght_output_s" "$obs_hght_850"
cdo sellevel,200 "$obs_hght_output_s" "$obs_hght_200"
cdo sellevel,850 "$model1_hght_output" "$model1_hght_850"
cdo sellevel,200 "$model1_hght_output" "$model1_hght_200"

if [ -n "$model2_hght_output" ]; then
    cdo sellevel,850 "$model2_hght_output" "$model2_hght_850"
    cdo sellevel,200 "$model2_hght_output" "$model2_hght_200"
fi

# Calculate biases for hght (model - obs)
cdo sub "$model1_hght_850" "$obs_hght_850" "$bias_obs_model1_hght_850"
cdo sub "$model1_hght_200" "$obs_hght_200" "$bias_obs_model1_hght_200"

if [ -n "$model2_hght_output" ]; then
    cdo sub "$model2_hght_850" "$obs_hght_850" "$bias_obs_model2_hght_850"
    cdo sub "$model2_hght_200" "$obs_hght_200" "$bias_obs_model2_hght_200"
    cdo sub "$model2_hght_850" "$model1_hght_850" "$bias_model1_model2_hght_850"
    cdo sub "$model2_hght_200" "$model1_hght_200" "$bias_model1_model2_hght_200"
fi

echo "Bias calculations completed for 850 hPa and 200 hPa."

# Plotting
echo "  Latitude Range: $lat_range"
echo "  Longitude Range: $lon_range"

# Validate and export lat/lon ranges
lat_range=$(echo "$lat_range" | sed 's/,/ /g')
lon_range=$(echo "$lon_range" | sed 's/,/ /g')

IFS=' ' read -r LAT_MIN LAT_MAX <<< "$lat_range"
IFS=' ' read -r LON_MIN LON_MAX <<< "$lon_range"

export lat_min="$LAT_MIN"
export lat_max="$LAT_MAX"
export lon_min="$LON_MIN"
export lon_max="$LON_MAX"
export season="$season"

echo "Parsed and exported Latitude/Longitude ranges."

# Call NCL scripts for plotting
ncl hght_850.ncl
ncl hght_200.ncl

check_error "Height plotting script"

echo "Bias calculations, reordering, and plotting completed for ANN hght."

