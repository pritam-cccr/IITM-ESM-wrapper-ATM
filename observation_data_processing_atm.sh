#!/bin/bash
# DESCRIPTION: Modular script for IITM_ESM diagnostics Obs data processing
# Last updated: November 2024

# Error handling function
function check_error {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Initialize arrays and variables
plev_variables=()
no_plev_variables=()
obs_data_dir=""
start_year_obs=""
end_year_obs=""
season=""

# Parse arguments
separator_found=false
for arg in "$@"; do
    if [ "$arg" == "<SEP>" ]; then
        separator_found=true
        continue
    fi

    if [ "$separator_found" = false ]; then
        # Arguments before the separator are plev variables
        plev_variables+=("$arg")
    else
        # After separator, treat arguments as no_plev variables until reaching the data directory and other params
        if [[ -z "$obs_data_dir" && "$arg" =~ ^[a-zA-Z] ]]; then
            no_plev_variables+=("$arg")
        elif [ -z "$obs_data_dir" ]; then
            obs_data_dir="$arg"
        elif [ -z "$start_year_obs" ]; then
            start_year_obs="$arg"
        elif [ -z "$end_year_obs" ]; then
            end_year_obs="$arg"
        elif [ -z "$season" ]; then
            season="$arg"
        fi
    fi
done

# Debugging and validation output
echo "Parsed plev variables: ${plev_variables[@]}"
echo "Parsed no_plev variables: ${no_plev_variables[@]}"
echo "Observation data directory: $obs_data_dir"
echo "Start year: $start_year_obs"
echo "End year: $end_year_obs"
echo "Season: $season"

# Validation
if [[ -z "$obs_data_dir" || -z "$start_year_obs" || -z "$end_year_obs" || -z "$season" ]]; then
    echo "Error: Missing observation data processing parameters."
    exit 1
fi

# Define output directory
output_dir="./output_data"
mkdir -p "$output_dir"
echo "Output files will be saved in $output_dir"

# Define the variable mappings for observations
declare -A variable_mapping=(
    ["tas"]="t2m"
    ["pr"]="precip"
    ["ta"]="t"
    ["ua"]="u"
    ["va"]="v"
    ["hght"]="z"
    ["slp"]="msl"
    ["rsdt"]="solar_mon"
    ["rsut"]="toa_sw_all_mon"
    ["rlut"]="toa_lw_all_mon"
    ["evspsbl"]="e"
)

# Function to determine months for each season
function get_season_months {
    case "$1" in
        DJF) echo "12,1,2" ;;  # December, January, February
        MAM) echo "3,4,5"  ;;  # March, April, May
        JJA) echo "6,7,8"  ;;  # June, July, August
        SON) echo "9,10,11" ;; # September, October, November
        JJAS) echo "6,7,8,9" ;; # June, July, August, September
        *) echo "Error: Invalid season $1"; exit 1 ;;
    esac
}

# Trap to clean up temporary files on exit
temp_files=()
trap 'rm -f "${temp_files[@]}"' EXIT

# Process each variable type separately
for var_type in "plev" "no_plev"; do
    if [ "$var_type" == "plev" ]; then
        variables=("${plev_variables[@]}")
    else
        variables=("${no_plev_variables[@]}")
    fi

    for var in "${variables[@]}"; do
        obs_var="${variable_mapping[$var]:-$var}"  # Map variable name, or use it directly if not mapped

        echo "Processing observation data for variable: $obs_var ($var_type)"
        
        # Define output paths for observation data
        obs_combined_annual_mean_file="${output_dir}/obs_annual_mean_yearly_${obs_var}.nc"
        obs_combined_season_mean_file="${output_dir}/obs_${season}_mean_yearly_${obs_var}.nc"
        final_annual_mean_file="${output_dir}/final_obs_annual_mean_${obs_var}.nc"
        final_season_mean_file="${output_dir}/final_obs_${season}_mean_${obs_var}.nc"
        all_years_merged_file="${output_dir}/obs_${obs_var}_all_years.nc"  # New merged file

        # Check if all necessary files exist, if so, skip processing
        if [[ -f "$obs_combined_annual_mean_file" && -f "$obs_combined_season_mean_file" && \
              -f "$all_years_merged_file" && -f "$final_annual_mean_file" && \
              -f "$final_season_mean_file" ]]; then
            echo "All files for $obs_var already exist. Skipping calculations."
            continue
        fi


        # Step 1: Calculate year-wise annual and seasonal means
        echo "Calculating year-wise means for years $start_year_obs to $end_year_obs..."
        yearly_annual_files=()
        yearly_season_files=()
        all_monthly_files=()  # Array to store all monthly files for merging
        season_months=$(get_season_months "$season")

        for year in $(seq "$start_year_obs" "$end_year_obs"); do
            monthly_files=()
            for month in {01..12}; do
                file=$(ls "$obs_data_dir"/*_"${obs_var}"_"${year}"_"${month}".nc 2>/dev/null)
                if [ -f "$file" ]; then
                    monthly_files+=("$file")
                    all_monthly_files+=("$file")  # Add to the global monthly file list
                else
                    echo "Warning: Missing file $file" | tee -a "$output_dir/missing_files.log"
                fi
            done

            if [ ${#monthly_files[@]} -gt 0 ]; then
                yearly_file="temp_obs_${year}_${obs_var}.nc"
                yearly_annual_mean_file="temp_annual_${year}_${obs_var}.nc"
                yearly_season_mean_file="temp_season_${year}_${obs_var}.nc"
                temp_files+=("$yearly_file" "$yearly_annual_mean_file" "$yearly_season_mean_file")

                # Concatenate monthly files into yearly file
                cdo cat "${monthly_files[@]}" "$yearly_file"
                check_error "Concatenating files for year $year"

                # Calculate year-wise annual mean
                cdo timmean "$yearly_file" "$yearly_annual_mean_file"
                check_error "Calculating annual mean for year $year"

                # Calculate year-wise seasonal mean
                cdo selmon,$season_months "$yearly_file" "temp_${obs_var}_season_${year}.nc"
                temp_files+=("temp_${obs_var}_season_${year}.nc")
                cdo timmean "temp_${obs_var}_season_${year}.nc" "$yearly_season_mean_file"
                check_error "Calculating seasonal mean for year $year"

                yearly_annual_files+=("$yearly_annual_mean_file")
                yearly_season_files+=("$yearly_season_mean_file")
            fi
        done

        # Step 2: Merge year-wise annual and seasonal means
        echo "Merging year-wise means into combined files..."
        if [ ${#yearly_annual_files[@]} -gt 0 ]; then
            cdo mergetime "${yearly_annual_files[@]}" "$obs_combined_annual_mean_file"
            check_error "Merging annual mean files"
        fi

        if [ ${#yearly_season_files[@]} -gt 0 ]; then
            cdo mergetime "${yearly_season_files[@]}" "$obs_combined_season_mean_file"
            check_error "Merging seasonal mean files"
        fi

        # Step 3: Create a merged file for all years
        if [ ${#all_monthly_files[@]} -gt 0 ]; then
            echo "Merging all monthly files for $obs_var into a single file..."
            cdo mergetime "${all_monthly_files[@]}" "$all_years_merged_file"
            check_error "Creating merged file for all years for $obs_var"
        fi

        # Step 4: Calculate final time means
        echo "Calculating time mean of combined annual and seasonal files..."
        cdo timmean "$obs_combined_annual_mean_file" "$final_annual_mean_file"
        check_error "Calculating final annual mean"

        cdo timmean "$obs_combined_season_mean_file" "$final_season_mean_file"
        check_error "Calculating final seasonal mean"
    done
done


echo "Observation data processing completed successfully."

