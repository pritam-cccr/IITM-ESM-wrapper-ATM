#!/bin/bash
# Script for processing model data without pressure levels (no_plev) for multiple variables,
# including annual and seasonal mean calculations.

# ==============================================================================
# Copyright (C) 2025 Centre for Climate Change Research (CCCR), IITM
#
# This script is part of the CCCR IITM_ESM diagnostics system.
#
# Author: [Pritam Das Mahapatra]
# Date: January 2025
# ==============================================================================
if [ "$#" -lt 6 ]; then
    echo "Usage: $0 <variable1 variable2 ...> <season> <netcdf_dir> <start_year> <end_year> <output_prefix>"
    exit 1
fi

variables=("${@:1:$#-5}")
season="${@: -5:1}"
netcdf_dir="${@: -4:1}"
start_year_model="${@: -3:1}"
end_year_model="${@: -2:1}"
output_prefix="${@: -1:1}"

echo "Processing variables: ${variables[@]}"
echo "Season: $season"
echo "NetCDF directory: $netcdf_dir"
echo "Start year: $start_year_model"
echo "End year: $end_year_model"
echo "Output prefix: $output_prefix"

function check_error {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}
# Define output directory from the wrapper
output_dir="./output_data"
function get_season_months {
    case "$1" in
        DJF) echo "12,1,2" ;;
        MAM) echo "3,4,5" ;;
        JJA) echo "6,7,8" ;;
        SON) echo "9,10,11" ;;
        JJAS) echo "6,7,8,9" ;;
        *) echo "Error: Invalid season $1"; exit 1 ;;
    esac
}

# Iterate over each variable and process
for var in "${variables[@]}"; do
    echo "Starting processing for variable: $var"

    # Define output files with prefix
    model_annual_mean_yr_file="${output_dir}/${output_prefix}_annual_mean_yearly_${var}_no_plev.nc"
    model_season_mean_yr_file="${output_dir}/${output_prefix}_${season}_mean_yearly_${var}_no_plev.nc"
    model_annual_mean_file="${output_dir}/${output_prefix}_annual_mean_${var}_no_plev.nc"
    model_season_mean_file="${output_dir}/${output_prefix}_${season}_mean_${var}_no_plev.nc"
    all_merged_annual="${output_dir}/${output_prefix}_${var}_annual_all_year_no_plev.nc"

    # Skip processing if all relevant files already exist
    if [ -f "$model_annual_mean_file" ] && [ -f "$model_season_mean_file" ] && \
       [ -f "$model_annual_mean_yr_file" ] && [ -f "$model_season_mean_yr_file" ] && \
       [ -f "$all_merged_annual" ]; then
        echo "All files for $var already exist. Skipping calculations."
        continue
    fi


    annual_mean_files=()
    seasonal_mean_files=()
    yearly_merged_files=()
    season_months=$(get_season_months "$season")

    for year in $(seq "$start_year_model" "$end_year_model"); do
        monthly_temp_files=()
        for month in $(seq -w 01 12); do
            monthly_file=$(ls "$netcdf_dir"/*"${year}_${month}"*.nc 2> /dev/null | grep -v "plev" | head -n 1)
            if [ -z "$monthly_file" ]; then
                echo "No file found for $year-$month. Skipping."
                continue
            fi

            if ! ncdump -h "$monthly_file" | grep -q " $var("; then
                echo "Variable $var not found in $monthly_file. Skipping."
                continue
            fi

            temp_var_file="temp_${output_prefix}${var}_${year}_${month}.nc"
            cdo selvar,"$var" "$monthly_file" "$temp_var_file"
            check_error "Selecting variable $var for $year-$month"
            monthly_temp_files+=("$temp_var_file")
        done

        if [ ${#monthly_temp_files[@]} -gt 0 ]; then
            yearly_merged_file="merged_${output_prefix}${var}_${year}.nc"
            cdo mergetime "${monthly_temp_files[@]}" "$yearly_merged_file"
            check_error "Merging monthly files for $var for year $year"
            yearly_merged_files+=("$yearly_merged_file")

            annual_mean_file="${output_prefix}annual_mean_${var}_${year}.nc"
            cdo timmean "$yearly_merged_file" "$annual_mean_file"
            check_error "Calculating annual mean for $var for year $year"
            annual_mean_files+=("$annual_mean_file")

            if [ -n "$season_months" ]; then
                seasonal_merged_file="selected_${output_prefix}${season}_${var}_${year}.nc"
                seasonal_mean_file="${output_prefix}${season}_mean_${var}_${year}.nc"
                cdo selmon,$season_months "$yearly_merged_file" "$seasonal_merged_file"
                check_error "Selecting $season months for $var for year $year"
                cdo timmean "$seasonal_merged_file" "$seasonal_mean_file"
                check_error "Calculating ${season} mean for $var for year $year"
                seasonal_mean_files+=("$seasonal_mean_file")
                rm "$seasonal_merged_file"
            fi

            # Remove temporary monthly files after processing
            rm "${monthly_temp_files[@]}"
        fi
    done

    # Merge yearly merged files into one file for all years
    if [ ${#yearly_merged_files[@]} -gt 0 ]; then
        cdo mergetime "${yearly_merged_files[@]}" "$all_merged_annual"
        check_error "Merging all yearly files for $var"
        rm "${yearly_merged_files[@]}"
    fi

    # Merge annual means into a time series and calculate overall annual mean
    if [ ${#annual_mean_files[@]} -gt 0 ]; then
        cdo mergetime "${annual_mean_files[@]}" "$model_annual_mean_yr_file"
        check_error "Creating annual mean time series for $var"
        cdo timmean "$model_annual_mean_yr_file" "$model_annual_mean_file"
        check_error "Calculating overall annual mean for $var"
        rm "${annual_mean_files[@]}"
    fi

    # Merge seasonal means into a time series and calculate overall seasonal mean
    if [ ${#seasonal_mean_files[@]} -gt 0 ]; then
        cdo mergetime "${seasonal_mean_files[@]}" "$model_season_mean_yr_file"
        check_error "Creating seasonal mean time series for $var"
        cdo timmean "$model_season_mean_yr_file" "$model_season_mean_file"
        check_error "Calculating overall seasonal mean for $var"
        rm "${seasonal_mean_files[@]}"
    fi

    echo "Completed processing for variable: $var"
done

echo "All variables processed successfully."

