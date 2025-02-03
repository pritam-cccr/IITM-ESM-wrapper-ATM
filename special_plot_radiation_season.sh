#!/bin/bash
# Script to calculate biases and plot season data for rsdt, rlut, and rsut.
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
bias1_rsdt="${output_dir}/bias_model1_obs_season_rsdt.nc"
bias2_rsdt="${output_dir}/bias_model2_obs_season_rsdt.nc"
bias3_rsdt="${output_dir}/bias_model1_model2_season_rsdt.nc"

bias1_rlut="${output_dir}/bias_model1_obs_season_rlut.nc"
bias2_rlut="${output_dir}/bias_model2_obs_season_rlut.nc"
bias3_rlut="${output_dir}/bias_model1_model2_season_rlut.nc"

bias1_rsut="${output_dir}/bias_model1_obs_season_rsut.nc"
bias2_rsut="${output_dir}/bias_model2_obs_season_rsut.nc"
bias3_rsut="${output_dir}/bias_model1_model2_season_rsut.nc"

# Calculate biases for rsdt
echo "Calculating biases for rsdt..."
if [ ! -f "$bias1_rsdt" ]; then
    cdo sub "$model1_rsdt" "$obs_rsdt" "$bias1_rsdt"
    check_error "Calculating bias for Model 1 - Obs (season rsdt)"
fi

if [ -n "$model2_rsdt" ] && [ ! -f "$bias2_rsdt" ]; then
    cdo sub "$model2_rsdt" "$obs_rsdt" "$bias2_rsdt"
    check_error "Calculating bias for Model 2 - Obs (season rsdt)"
fi

if [ -n "$model2_rsdt" ] && [ ! -f "$bias3_rsdt" ]; then
    cdo sub "$model1_rsdt" "$model2_rsdt" "$bias3_rsdt"
    check_error "Calculating bias for Model 1 - Model 2 (season rsdt)"
fi

# Calculate biases for rlut
echo "Calculating biases for rlut..."
if [ ! -f "$bias1_rlut" ]; then
    cdo sub "$model1_rlut" "$obs_rlut" "$bias1_rlut"
    check_error "Calculating bias for Model 1 - Obs (season rlut)"
fi

if [ -n "$model2_rlut" ] && [ ! -f "$bias2_rlut" ]; then
    cdo sub "$model2_rlut" "$obs_rlut" "$bias2_rlut"
    check_error "Calculating bias for Model 2 - Obs (season rlut)"
fi

if [ -n "$model2_rlut" ] && [ ! -f "$bias3_rlut" ]; then
    cdo sub "$model1_rlut" "$model2_rlut" "$bias3_rlut"
    check_error "Calculating bias for Model 1 - Model 2 (season rlut)"
fi

# Calculate biases for rsut
echo "Calculating biases for rsut..."
if [ ! -f "$bias1_rsut" ]; then
    cdo sub "$model1_rsut" "$obs_rsut" "$bias1_rsut"
    check_error "Calculating bias for Model 1 - Obs (season rsut)"
fi

if [ -n "$model2_rsut" ] && [ ! -f "$bias2_rsut" ]; then
    cdo sub "$model2_rsut" "$obs_rsut" "$bias2_rsut"
    check_error "Calculating bias for Model 2 - Obs (season rsut)"
fi

if [ -n "$model2_rsut" ] && [ ! -f "$bias3_rsut" ]; then
    cdo sub "$model1_rsut" "$model2_rsut" "$bias3_rsut"
    check_error "Calculating bias for Model 1 - Model 2 (season rsut)"
fi

# Debugging Information
echo "Bias calculations completed. Output files are saved in $output_dir."

export season="$season"
echo "SEASON: $season"
ncl rlut_mean_bias_season.ncl
ncl rsut_mean_bias_season.ncl
ncl toa_rad_mean_bias_season.ncl
check_error "Plotting radiation variables (season)"
echo "Radiation plotting for season data completed successfully."

