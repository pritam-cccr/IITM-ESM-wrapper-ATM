#!/bin/bash
# DESCRIPTION: Specialized plotting script for TAS (surface air temperature)
# Last updated: November 2024

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
output_dir="./plots_tas"
mkdir -p "$output_dir"

# Output filenames
annual_bias_model1_obs="${output_dir}/tas_annual_bias_obs_model1.nc"
season_bias_model1_obs="${output_dir}/tas_season_bias_obs_model1.nc"
annual_bias_model2_obs="${output_dir}/tas_annual_bias_obs_model2.nc"
season_bias_model2_obs="${output_dir}/tas_season_bias_obs_model2.nc"
annual_bias_model1_model2="${output_dir}/tas_annual_bias_model1_model2.nc"
season_bias_model1_model2="${output_dir}/tas_season_bias_model1_model2.nc"
annual_plot="${output_dir}/tas_annual_comparison.png"
season_plot="${output_dir}/tas_season_comparison.png"

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

# === BIAS CALCULATION ===
# === BIAS CALCULATION ===
echo "Calculating biases for TAS..."

# Check and calculate annual bias (Obs - Model 1)
if [ ! -f "$annual_bias_model1_obs" ]; then
    cdo sub "$model1_annual_mean" "$obs_annual_regridded" "$annual_bias_model1_obs"
    check_error "Calculating annual bias for TAS (Obs - Model 1)"
else
    echo "Debug: $annual_bias_model1_obs already exists. Skipping..."
fi

# Check and calculate seasonal bias (Obs - Model 1)
if [ ! -f "$season_bias_model1_obs" ]; then
    cdo sub "$model1_season_mean" "$obs_season_regridded" "$season_bias_model1_obs"
    check_error "Calculating seasonal bias for TAS (Obs - Model 1)"
else
    echo "Debug: $season_bias_model1_obs already exists. Skipping..."
fi

# Check and calculate biases for Model 2 if provided
if [ -n "$model2_annual_regridded" ]; then
    # Annual bias (Obs - Model 2)
    if [ ! -f "$annual_bias_model2_obs" ]; then
        cdo sub "$model2_annual_regridded" "$obs_annual_regridded" "$annual_bias_model2_obs"
        check_error "Calculating annual bias for TAS (Obs - Model 2)"
    else
        echo "Debug: $annual_bias_model2_obs already exists. Skipping..."
    fi

    # Seasonal bias (Obs - Model 2)
    if [ ! -f "$season_bias_model2_obs" ]; then
        cdo sub "$model2_season_regridded" "$obs_season_regridded" "$season_bias_model2_obs"
        check_error "Calculating seasonal bias for TAS (Obs - Model 2)"
    else
        echo "Debug: $season_bias_model2_obs already exists. Skipping..."
    fi

    # Annual bias (Model 1 - Model 2)
    if [ ! -f "$annual_bias_model1_model2" ]; then
        cdo sub "$model1_annual_mean" "$model2_annual_regridded" "$annual_bias_model1_model2"
        check_error "Calculating annual bias for TAS (Model 1 - Model 2)"
    else
        echo "Debug: $annual_bias_model1_model2 already exists. Skipping..."
    fi

    # Seasonal bias (Model 1 - Model 2)
    if [ ! -f "$season_bias_model1_model2" ]; then
        cdo sub "$model1_season_mean" "$model2_season_regridded" "$season_bias_model1_model2"
        check_error "Calculating seasonal bias for TAS (Model 1 - Model 2)"
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
echo "Generating plots for TAS Annual..."
if [ -n "$model2_annual_regridded" ]; then
    python3 tas_plotting_script_ann.py "$model1_annual_mean" "$model2_annual_regridded" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "$annual_bias_model2_obs" \
    "$annual_bias_model1_model2" "tas" "t2m" "$output_dir" "$projection" "$lat_range" "$lon_range"
else
    python3 tas_plotting_script_ann.py "$model1_annual_mean" "" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "" \
    "" "tas" "t2m" "$output_dir" "$projection" "$lat_range" "$lon_range"
fi
check_error "Generating plots for TAS Annual"

echo "Generating plots for TAS Seasonal..."
if [ -n "$model2_season_regridded" ]; then
    python3 tas_plotting_script_season.py "$model1_season_mean" "$model2_season_regridded" \
    "$obs_season_regridded" "$season_bias_model1_obs" "$season_bias_model2_obs" \
    "$season_bias_model1_model2" "tas" "t2m" "$output_dir" "$projection" "$lat_range" \
    "$lon_range" "$season"
else
    python3 tas_plotting_script_season.py "$model1_season_mean" "" \
    "$obs_season_regridded" "$season_bias_model1_obs" "" \
    "" "tas" "t2m" "$output_dir" "$projection" "$lat_range" \
    "$lon_range" "$season" 
fi
check_error "Generating plots for TAS Seasonal"


echo "Specialized plotting for TAS completed. Outputs saved to $output_dir"


