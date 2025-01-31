#!/bin/bash
# DESCRIPTION: Specialized plotting script for precipitation (pr)
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
output_dir="./plots_pr"
mkdir -p "$output_dir"

# Output filenames
model1_annual_mm="${output_dir}/model1_annual_mean_pr_mm.nc"
model1_season_mm="${output_dir}/model1_season_mean_pr_mm.nc"
model2_annual_mm="${output_dir}/model2_annual_mean_pr_mm.nc"
model2_season_mm="${output_dir}/model2_season_mean_pr_mm.nc"
annual_bias_model1_obs="${output_dir}/pr_annual_bias_model1_obs.nc"
season_bias_model1_obs="${output_dir}/pr_season_bias_model1_obs.nc"
annual_bias_model2_obs="${output_dir}/pr_annual_bias_model2_obs.nc"
season_bias_model2_obs="${output_dir}/pr_season_bias_model2_obs.nc"
annual_bias_model1_model2="${output_dir}/pr_annual_bias_model1_model2.nc"
season_bias_model1_model2="${output_dir}/pr_season_bias_model1_model2.nc"
annual_plot="${output_dir}/pr_annual_comparison.png"
season_plot="${output_dir}/pr_season_comparison.png"

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

# === UNIT CONVERSION ===
echo "Converting Model 1 and Model 2 flux data to mm/day..."

# Convert Model 1 annual mean
if [ ! -f "$model1_annual_mm" ]; then
    cdo mulc,86400 "$model1_annual_mean" "$model1_annual_mm"
    check_error "Converting Model 1 annual mean to mm/day"
else
    echo "Debug: $model1_annual_mm already exists. Skipping conversion."
fi

# Convert Model 1 seasonal mean
if [ ! -f "$model1_season_mm" ]; then
    cdo mulc,86400 "$model1_season_mean" "$model1_season_mm"
    check_error "Converting Model 1 seasonal mean to mm/day"
else
    echo "Debug: $model1_season_mm already exists. Skipping conversion."
fi

# Convert Model 2 annual mean (if provided)
if [ -n "$model2_annual_regridded" ] && [ ! -f "$model2_annual_mm" ]; then
    cdo mulc,86400 "$model2_annual_regridded" "$model2_annual_mm"
    check_error "Converting Model 2 annual mean to mm/day"
else
    echo "Debug: $model2_annual_mm already exists. Skipping conversion."
fi

# Convert Model 2 seasonal mean (if provided)
if [ -n "$model2_season_regridded" ] && [ ! -f "$model2_season_mm" ]; then
    cdo mulc,86400 "$model2_season_regridded" "$model2_season_mm"
    check_error "Converting Model 2 seasonal mean to mm/day"
else
    echo "Debug: $model2_season_mm already exists. Skipping conversion."
fi

# === BIAS CALCULATION ===
echo "Calculating biases for pr..."

# Obs - Model 1 biases
if [ ! -f "$annual_bias_model1_obs" ]; then
    cdo sub "$model1_annual_mm" "$obs_annual_regridded" "$annual_bias_model1_obs"
    check_error "Calculating annual bias for pr (Obs - Model 1)"
else
    echo "Debug: $annual_bias_model1_obs already exists. Skipping..."
fi

if [ ! -f "$season_bias_model1_obs" ]; then
    cdo sub "$model1_season_mm" "$obs_season_regridded" "$season_bias_model1_obs"
    check_error "Calculating seasonal bias for pr (Obs - Model 1)"
else
    echo "Debug: $season_bias_model1_obs already exists. Skipping..."
fi

# Obs - Model 2 biases
if [ -n "$model2_annual_regridded" ]; then
    if [ ! -f "$annual_bias_model2_obs" ]; then
        cdo sub "$model2_annual_mm" "$obs_annual_regridded" "$annual_bias_model2_obs"
        check_error "Calculating annual bias for pr (Obs - Model 2)"
    else
        echo "Debug: $annual_bias_model2_obs already exists. Skipping..."
    fi

    if [ ! -f "$season_bias_model2_obs" ]; then
        cdo sub "$model2_season_mm" "$obs_season_regridded" "$season_bias_model2_obs"
        check_error "Calculating seasonal bias for pr (Obs - Model 2)"
    else
        echo "Debug: $season_bias_model2_obs already exists. Skipping..."
    fi
fi

# Model 1 - Model 2 biases
if [ -n "$model2_annual_mm" ]; then
    if [ ! -f "$annual_bias_model1_model2" ]; then
        cdo sub "$model1_annual_mm" "$model2_annual_mm" "$annual_bias_model1_model2"
        check_error "Calculating annual bias for pr (Model 1 - Model 2)"
    else
        echo "Debug: $annual_bias_model1_model2 already exists. Skipping..."
    fi

    if [ ! -f "$season_bias_model1_model2" ]; then
        cdo sub "$model1_season_mm" "$model2_season_mm" "$season_bias_model1_model2"
        check_error "Calculating seasonal bias for pr (Model 1 - Model 2)"
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
echo "Generating plots for pr Annual..."
if [ -n "$model2_annual_regridded" ]; then
    python3 pr_plotting_script_ann.py "$model1_annual_mm" "$model2_annual_mm" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "$annual_bias_model2_obs" \
    "$annual_bias_model1_model2" "pr" "precip" "$output_dir" "$projection" "$lat_range" "$lon_range"
else
    python3 pr_plotting_script_ann.py "$model1_annual_mean" "" \
    "$obs_annual_regridded" "$annual_bias_model1_obs" "" \
    "" "pr" "precip" "$output_dir" "$projection" "$lat_range" "$lon_range"
fi
check_error "Generating plots for pr Annual"

echo "Generating plots for pr Seasonal..."
if [ -n "$model2_season_regridded" ]; then
    python3 pr_plotting_script_season.py "$model1_season_mm" "$model2_season_mm" \
    "$obs_season_regridded" "$season_bias_model1_obs" "$season_bias_model2_obs" \
    "$season_bias_model1_model2" "pr" "precip" "$output_dir" "$projection" "$lat_range" \
    "$lon_range" "$season"
else
    python3 pr_plotting_script_season.py "$model1_season_mean" "" \
    "$obs_season_regridded" "$season_bias_model1_obs" "" \
    "" "pr" "precip" "$output_dir" "$projection" "$lat_range" \
    "$lon_range" "$season" 
fi
check_error "Generating plots for pr Seasonal"


echo "Specialized plotting for pr completed. Outputs saved to $output_dir"


