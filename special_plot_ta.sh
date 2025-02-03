#!/bin/bash
# DESCRIPTION: Specialized plotting script for ta (Air temperature)
## ==============================================================================
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
    echo "Usage: $0 <obs_annual_regridded> <obs_season_regridded> <model1_annual_mean> <model1_season_mean> <projection> <lat_range> <lon_range> <season> [<model2_annual_regridded> <model2_season_regridded>]"
    exit 1
fi

# Input arguments
obs_annual_regridded="$1"
obs_season_regridded="$2"
model1_annual_mean="$3"
model1_season_mean="$4"
projection="$5"
lat_range="$6"
lon_range="$7"
season="$8"
model2_annual_regridded="${9:-}"  # Optional
model2_season_regridded="${10:-}"  # Optional

# Output directory
output_dir="./plots_ta"
mkdir -p "$output_dir"

# Output filenames
annual_bias_model1_obs="${output_dir}/ta_annual_bias_obs_model1.nc"
season_bias_model1_obs="${output_dir}/ta_season_bias_obs_model1.nc"
annual_bias_model2_obs="${output_dir}/ta_annual_bias_obs_model2.nc"
season_bias_model2_obs="${output_dir}/ta_season_bias_obs_model2.nc"
annual_bias_model1_model2="${output_dir}/ta_annual_bias_model1_model2.nc"
season_bias_model1_model2="${output_dir}/ta_season_bias_model1_model2.nc"
annual_plot="${output_dir}/ta_annual_comparison.png"
season_plot="${output_dir}/ta_season_comparison.png"

# === INPUT VALIDATION ===
echo "=== INPUT INFORMATION ==="
echo "Observation Annual Regridded: $obs_annual_regridded"
echo "Observation Seasonal Regridded: $obs_season_regridded"
echo "Model 1 Annual Mean: $model1_annual_mean"
echo "Model 1 Seasonal Mean: $model1_season_mean"
echo "Projection: $projection"
echo "Latitude Range: $lat_range"
echo "Longitude Range: $lon_range"
echo "Season: $season"
if [ -n "$model2_annual_regridded" ]; then
    echo "Model 2 Annual Regridded: $model2_annual_regridded"
    echo "Model 2 Seasonal Regridded: $model2_season_regridded"
else
    echo "Model 2: Not Provided"
fi
echo "Output Directory: $output_dir"
echo "=========================="

# Validate required files
required_files=(
    "$obs_annual_regridded"
    "$obs_season_regridded"
    "$model1_annual_mean"
    "$model1_season_mean"
)
if [ -n "$model2_annual_regridded" ]; then
    required_files+=("$model2_annual_regridded" "$model2_season_regridded")
fi

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: Required file $file not found. Exiting."
        exit 1
    fi
done

# Desired pressure levels in descending order
pressure_levels=(1000 925 850 700 600 500 400 300 250 200 150 100 70 50 30 20 10 5 1)

# Function to reorder pressure levels
reorder_pressure_levels() {
    input_file="$1"
    output_file="$2"
    temp_files=()

    echo "Reordering pressure levels for file: $input_file"

    for p in "${pressure_levels[@]}"; do
        temp_file="${output_dir}/temp_level_${p}.nc"
        cdo sellevel,$p "$input_file" "$temp_file"
        check_error "Selecting pressure level $p"
        temp_files+=("$temp_file")
    done

    # Merge all selected levels into the output file
    cdo merge "${temp_files[@]}" "$output_file"
    check_error "Merging reordered pressure levels"
    
    # Clean up temporary files
    rm -f "${temp_files[@]}"
    echo "Reordered file saved as: $output_file"
}

# Example for observation annual data
obs_annual_regridded_ordered="${output_dir}/obs_annual_regridded_ordered.nc"
if [ ! -f "$obs_annual_regridded_ordered" ]; then
    reorder_pressure_levels "$obs_annual_regridded" "$obs_annual_regridded_ordered"
else
    echo "File $obs_annual_regridded_ordered already exists. Skipping."
fi

# Repeat for all required files
obs_season_regridded_ordered="${output_dir}/obs_season_regridded_ordered.nc"
if [ ! -f "$obs_season_regridded_ordered" ]; then
    reorder_pressure_levels "$obs_season_regridded" "$obs_season_regridded_ordered"
else
    echo "File $obs_season_regridded_ordered already exists. Skipping."
fi

model1_annual_mean_ordered="${output_dir}/model1_annual_mean_ordered.nc"
if [ ! -f "$model1_annual_mean_ordered" ]; then
    reorder_pressure_levels "$model1_annual_mean" "$model1_annual_mean_ordered"
else
    echo "File $model1_annual_mean_ordered already exists. Skipping."
fi

model1_season_mean_ordered="${output_dir}/model1_season_mean_ordered.nc"
if [ ! -f "$model1_season_mean_ordered" ]; then
    reorder_pressure_levels "$model1_season_mean" "$model1_season_mean_ordered"
else
    echo "File $model1_season_mean_ordered already exists. Skipping."
fi

if [ -n "$model2_annual_regridded" ]; then
    model2_annual_regridded_ordered="${output_dir}/model2_annual_regridded_ordered.nc"
    if [ ! -f "$model2_annual_regridded_ordered" ]; then
        reorder_pressure_levels "$model2_annual_regridded" "$model2_annual_regridded_ordered"
    else
        echo "File $model2_annual_regridded_ordered already exists. Skipping."
    fi

    model2_season_regridded_ordered="${output_dir}/model2_season_regridded_ordered.nc"
    if [ ! -f "$model2_season_regridded_ordered" ]; then
        reorder_pressure_levels "$model2_season_regridded" "$model2_season_regridded_ordered"
    else
        echo "File $model2_season_regridded_ordered already exists. Skipping."
    fi
fi


# Update variables to use reordered files
obs_annual_regridded="$obs_annual_regridded_ordered"
obs_season_regridded="$obs_season_regridded_ordered"
model1_annual_mean="$model1_annual_mean_ordered"
model1_season_mean="$model1_season_mean_ordered"

if [ -n "$model2_annual_regridded" ]; then
    model2_annual_regridded="$model2_annual_regridded_ordered"
    model2_season_regridded="$model2_season_regridded_ordered"
fi


# === CONTINUE WITH BIAS CALCULATION ===
echo "Calculating biases after arranging pressure levels..."

# === BIAS CALCULATION ===
echo "Calculating biases for ta..."

# Check and calculate annual bias (Obs - Model 1)
if [ ! -f "$annual_bias_model1_obs" ]; then
    cdo sub "$model1_annual_mean" "$obs_annual_regridded" "$annual_bias_model1_obs"
    check_error "Calculating annual bias for ta (Obs - Model 1)"
else
    echo "Debug: $annual_bias_model1_obs already exists. Skipping..."
fi

# Check and calculate seasonal bias (Obs - Model 1)
if [ ! -f "$season_bias_model1_obs" ]; then
    cdo sub "$model1_season_mean" "$obs_season_regridded" "$season_bias_model1_obs"
    check_error "Calculating seasonal bias for ta (Obs - Model 1)"
else
    echo "Debug: $season_bias_model1_obs already exists. Skipping..."
fi

# Check and calculate biases for Model 2 if provided
if [ -n "$model2_annual_regridded" ]; then
    # Annual bias (Obs - Model 2)
    if [ ! -f "$annual_bias_model2_obs" ]; then
        cdo sub "$model2_annual_regridded" "$obs_annual_regridded" "$annual_bias_model2_obs"
        check_error "Calculating annual bias for ta (Obs - Model 2)"
    else
        echo "Debug: $annual_bias_model2_obs already exists. Skipping..."
    fi

    # Seasonal bias (Obs - Model 2)
    if [ ! -f "$season_bias_model2_obs" ]; then
        cdo sub "$model2_season_regridded" "$obs_season_regridded" "$season_bias_model2_obs"
        check_error "Calculating seasonal bias for ta (Obs - Model 2)"
    else
        echo "Debug: $season_bias_model2_obs already exists. Skipping..."
    fi

    # Annual bias (Model 1 - Model 2)
    if [ ! -f "$annual_bias_model1_model2" ]; then
        cdo sub "$model1_annual_mean" "$model2_annual_regridded" "$annual_bias_model1_model2"
        check_error "Calculating annual bias for ta (Model 1 - Model 2)"
    else
        echo "Debug: $annual_bias_model1_model2 already exists. Skipping..."
    fi

    # Seasonal bias (Model 1 - Model 2)
    if [ ! -f "$season_bias_model1_model2" ]; then
        cdo sub "$model1_season_mean" "$model2_season_regridded" "$season_bias_model1_model2"
        check_error "Calculating seasonal bias for ta (Model 1 - Model 2)"
    else
        echo "Debug: $season_bias_model1_model2 already exists. Skipping..."
    fi
fi



# Validate Latitude Range
if [[ ! "$lat_range" =~ ^-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Latitude range '$lat_range' is invalid. Expected format: 'min_lat,max_lat'."
    exit 1
fi

# Validate Longitude Range
if [[ ! "$lon_range" =~ ^-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Longitude range '$lon_range' is invalid. Expected format: 'min_lon,max_lon'."
    exit 1
fi

echo "Latitude Range (Bash): $lat_range"
echo "Longitude Range (Bash): $lon_range"




# === PLOTTING ===
echo "Generating plots for ta Annual..."
if [ -n "$model2_annual_regridded" ]; then
    python3 ta_plotting_script_ann.py "$model1_annual_mean" "$model2_annual_regridded" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "$annual_bias_model2_obs" \
    "$annual_bias_model1_model2" "ta" "t" "$output_dir" "$projection" "$lat_range" "$lon_range"
else
    python3 ta_plotting_script_ann.py "$model1_annual_mean" "" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "" \
    "" "ta" "t" "$output_dir" "$projection" "$lat_range" "$lon_range"
fi
check_error "Generating plots for ta Annual"


echo "Generating plots for pr Seasonal..."
if [ -n "$model2_season_regridded" ]; then
    python3 ta_plotting_script_season.py "$model1_season_mean" "$model2_season_regridded" \
    "$obs_season_regridded" "$season_bias_model1_obs" "$season_bias_model2_obs" \
    "$season_bias_model1_model2" "ta" "t" "$output_dir" "$projection" "$lat_range" \
    "$lon_range" "$season"
else
    python3 ta_plotting_script_season.py "$model1_season_mean" "" \
    "$obs_season_regridded" "$season_bias_model1_obs" "" \
    "" "ta" "t" "$output_dir" "$projection" "$lat_range" \
    "$lon_range" "$season" 
fi


echo "Generating plots for ta vertival Annual..."

if [ -n "$model2_annual_regridded" ]; then
    python3 ta_vert_plotting_script_ann.py "$model1_annual_mean" "$model2_annual_regridded" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "$annual_bias_model2_obs" \
    "$annual_bias_model1_model2" "ta" "t" "$output_dir" "$projection" "$lat_range" "$lon_range"
else
    python3 ta_vert_plotting_script_ann.py "$model1_annual_mean" "" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "" \
    "" "ta" "t" "$output_dir" "$projection" "$lat_range" "$lon_range"
fi
check_error "Generating plots for ta Annual"
echo "Generating plots for ta Seasonal..."



echo "Specialized plotting for ta completed. Outputs saved to $output_dir"


