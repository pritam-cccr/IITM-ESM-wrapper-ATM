#!/bin/bash
# DESCRIPTION: Specialized plotting script for ua and va (wind) with bias calculation and plotting
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
if [ "$#" -lt 8 ]; then
    echo "Usage: $0 <obs_annual_regridded_ua> <obs_annual_regridded_va> <model1_annual_ua> <model1_annual_va> <projection> <lat_range> <lon_range> <season> [<model2_annual_ua> <model2_annual_va>]"
    exit 1
fi

# Input arguments
obs_annual_ua="$1"
obs_annual_va="$2"
model1_annual_ua="$3"
model1_annual_va="$4"
projection="$5"
lat_range="$6"
lon_range="$7"
season="$8"
model2_annual_ua="${9:-}"  # Optional
model2_annual_va="${10:-}"  # Optional

# Output directory
output_dir="./plots_ua_va"
mkdir -p "$output_dir"

# Desired pressure levels in descending order
pressure_levels=(1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 10 5 1)

# Function to reorder pressure levels
reorder_pressure_levels() {
    input_file="$1"       # Input file
    output_file="$2"      # Output file
    var="$3"              # Variable name
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
obs_ua_output="${output_dir}/obs_ua_regridded_ordered.nc"
obs_va_output="${output_dir}/obs_va_regridded_ordered.nc"
model1_ua_output="${output_dir}/model1_ua_annual_ordered.nc"
model1_va_output="${output_dir}/model1_va_annual_ordered.nc"
model2_ua_output="${output_dir}/model2_ua_annual_ordered.nc"
model2_va_output="${output_dir}/model2_va_annual_ordered.nc"

# Reorder pressure levels for observation ua and va
reorder_pressure_levels "$obs_annual_ua" "$obs_ua_output" "u"
reorder_pressure_levels "$obs_annual_va" "$obs_va_output" "v"

# Reorder pressure levels for Model 1 ua and va
reorder_pressure_levels "$model1_annual_ua" "$model1_ua_output" "ua"
reorder_pressure_levels "$model1_annual_va" "$model1_va_output" "va"

# Reorder pressure levels for Model 2 ua and va (if provided)
if [ -n "$model2_annual_ua" ] && [ -n "$model2_annual_va" ]; then
    reorder_pressure_levels "$model2_annual_ua" "$model2_ua_output" "ua"
    reorder_pressure_levels "$model2_annual_va" "$model2_va_output" "va"
fi

# Bias Calculation (850 hPa and 200 hPa)
bias_obs_model1_ua_850="${output_dir}/bias_obs_model1_ua_850.nc"
bias_obs_model1_ua_200="${output_dir}/bias_obs_model1_ua_200.nc"
bias_obs_model1_va_850="${output_dir}/bias_obs_model1_va_850.nc"
bias_obs_model1_va_200="${output_dir}/bias_obs_model1_va_200.nc"

bias_obs_model2_ua_850="${output_dir}/bias_obs_model2_ua_850.nc"
bias_obs_model2_ua_200="${output_dir}/bias_obs_model2_ua_200.nc"
bias_obs_model2_va_850="${output_dir}/bias_obs_model2_va_850.nc"
bias_obs_model2_va_200="${output_dir}/bias_obs_model2_va_200.nc"

bias_model1_model2_ua_850="${output_dir}/bias_model1_model2_ua_850.nc"
bias_model1_model2_ua_200="${output_dir}/bias_model1_model2_ua_200.nc"
bias_model1_model2_va_850="${output_dir}/bias_model1_model2_va_850.nc"
bias_model1_model2_va_200="${output_dir}/bias_model1_model2_va_200.nc"

obs_ua_850="${output_dir}/obs_ua_850.nc"
obs_ua_200="${output_dir}/obs_ua_200.nc"
obs_va_850="${output_dir}/obs_va_850.nc"
obs_va_200="${output_dir}/obs_va_200.nc"

model1_va_850="${output_dir}/model1_va_850.nc"
model1_va_200="${output_dir}/model1_va_200.nc"
model1_ua_850="${output_dir}/model1_ua_850.nc"
model1_ua_200="${output_dir}/model1_ua_200.nc"

model2_ua_850="${output_dir}/model2_ua_850.nc"
model2_ua_200="${output_dir}/model2_ua_200.nc"
model2_va_850="${output_dir}/model2_va_850.nc"
model2_va_200="${output_dir}/model2_va_200.nc"

echo "Calculating bias for 850 hPa and 200 hPa..."

# Extract 850 hPa and 200 hPa levels for ua
cdo sellevel,850 "$obs_ua_output" "$obs_ua_850"
cdo sellevel,200 "$obs_ua_output" "$obs_ua_200"
cdo sellevel,850 "$model1_ua_output" "$model1_ua_850"
cdo sellevel,200 "$model1_ua_output" "$model1_ua_200"

if [ -n "$model2_ua_output" ]; then
    cdo sellevel,850 "$model2_ua_output" "$model2_ua_850"
    cdo sellevel,200 "$model2_ua_output" "$model2_ua_200"
fi

# Extract 850 hPa and 200 hPa levels for va
cdo sellevel,850 "$obs_va_output" "$obs_va_850"
cdo sellevel,200 "$obs_va_output" "$obs_va_200"
cdo sellevel,850 "$model1_va_output" "$model1_va_850"
cdo sellevel,200 "$model1_va_output" "$model1_va_200"

if [ -n "$model2_va_output" ]; then
    cdo sellevel,850 "$model2_va_output" "$model2_va_850"
    cdo sellevel,200 "$model2_va_output" "$model2_va_200"
fi



echo "Bias calculations will be done during plot for 850 hPa and 200 hPa."

# Remaining unchanged parts, including plotting, will stay as they are.


# Plotting
echo "  Latitude Range: $lat_range"
    echo "  Longitude Range: $lon_range"
# Check if lat_range and lon_range are non-empty
if [ -z "$lat_range" ] || [ -z "$lon_range" ]; then
    echo "Error: Latitude or Longitude range is empty."
    exit 1
fi
lat_range=$(echo "$lat_range" | sed 's/,/ /g')
lon_range=$(echo "$lon_range" | sed 's/,/ /g')

IFS=' ' read -r LAT_MIN LAT_MAX <<< "$lat_range"
IFS=' ' read -r LON_MIN LON_MAX <<< "$lon_range"


# Debug: Print the parsed values
echo "Parsed Latitude Range: LAT_MIN=$LAT_MIN, LAT_MAX=$LAT_MAX"
echo "Parsed Longitude Range: LON_MIN=$LON_MIN, LON_MAX=$LON_MAX"

# Validate parsed values
if [ -z "$LAT_MIN" ] || [ -z "$LAT_MAX" ] || [ -z "$LON_MIN" ] || [ -z "$LON_MAX" ]; then
    echo "Error: Failed to parse latitude or longitude ranges. Check input format."
    exit 1
fi

# Validate numerical values
if ! [[ "$LAT_MIN" =~ ^-?[0-9]+([.][0-9]+)?$ && "$LAT_MAX" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: Latitude range contains non-numeric values."
    exit 1
fi
if ! [[ "$LON_MIN" =~ ^-?[0-9]+([.][0-9]+)?$ && "$LON_MAX" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: Longitude range contains non-numeric values."
    exit 1
fi
# Export parsed values as environment variables
export lat_min="$LAT_MIN"
export lat_max="$LAT_MAX"
export lon_min="$LON_MIN"
export lon_max="$LON_MAX"

# Debug: Confirm exported values
echo "Exported Latitude Range: lat_min=$lat_min, lat_max=$lat_max"
echo "Exported Longitude Range: lon_min=$lon_min, lon_max=$lon_max"
# Call the NCL script with arguments

ncl wind_850.ncl
ncl wind_200.ncl
ncl wind_850_season.ncl
ncl wind_200_season.ncl
ncl zonal_wind_200.ncl
ncl zonal_wind_850.ncl

ncl meridional_wind_850.ncl
ncl meridional_wind_200.ncl

ncl Zonal_wind_level_lat_ann.ncl
ncl Zonal_wind_level_lat_season.ncl
ncl Zonal_wind_level_lat_ann_log.ncl
ncl Zonal_wind_level_lat_season_log.ncl

ncl precip_wind850_season.ncl







check_error "Wind plotting script"

echo "Bias calculations, reordering, and plotting completed for ANN ua and va."

