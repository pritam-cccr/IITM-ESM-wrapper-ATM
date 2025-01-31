#!/bin/bash
# DESCRIPTION: Plotting script for IITM_ESM diagnostics
# Last updated: November 2024



# Source user inputs from the external file
source ./user_inputs_atm.sh

IFS=',' read -r -a var_list <<< "$plot_var"


# Error handling function
function check_error {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Function to verify file existence
function verify_file {
    if [ ! -f "$1" ]; then
        echo "Error: File $1 not found. Skipping..."
        echo "$1: Missing file" >> "$skipped_log"
        return 1
    fi
}

# Initialize variables
plev_variables=()
no_plev_variables=()
season=""
projection=""
lat_range=""
lon_range=""
model1_prefix=""
model2_prefix=""
obs_prefix=""
start_year=""
end_year=""
plot_var=""
separator_found=false

# Debug mode flag
debug=false
if [ "$1" == "-d" ]; then
    debug=true
    shift
fi

# Parse arguments
separator_found=false
non_plev_finished=false
declare -a plev_variables
declare -a no_plev_variables

# Parse arguments
for arg in "$@"; do
    if [ "$arg" == "<SEP>" ]; then
        separator_found=true
        continue
    fi

    if ! $separator_found; then
        # Add to pressure-level variables before separator
        plev_variables+=("$arg")
    elif ! $non_plev_finished; then
        # Add to non-pressure-level variables after separator
        if [[ "$arg" == "JJAS" || "$arg" == "DJF" || "$arg" == "MAM" || "$arg" == "SON" ]]; then
            non_plev_finished=true
        else
            no_plev_variables+=("$arg")
            continue
        fi
    fi

    # Assign remaining fixed variables in order
    if $non_plev_finished; then
        case "" in
            "$season") season="$arg" ;;
            "$projection") projection="$arg" ;;
            "$lat_range") lat_range="$arg" ;;
            "$lon_range") lon_range="$arg" ;;
            "$model1_prefix") model1_prefix="$arg" ;;
            "$model2_prefix") [[ "$arg" != "$output_dir/final_obs_" ]] && model2_prefix="$arg" ;;
            "$obs_prefix") obs_prefix="$arg" ;;
        esac
    fi
done


# Debug: Print parsed arguments only once
if $debug; then
    echo "Debug: Check inputs for plotting function to work:"
    echo "  Pressure-Level Variables: ${plev_variables[@]}"
    echo "  Non-Pressure-Level Variables: ${no_plev_variables[@]}"
    echo "	PLOT Var:$plot_var"
    echo "  Season: $season"
    echo "  Projection: $projection"
    echo "  Latitude Range: $lat_range"
    echo "  Longitude Range: $lon_range"
    echo "  Model 1 Prefix: $model1_prefix"
    echo "  Model 2 Prefix: ${model2_prefix:-'Not Used'}"
    echo "  Observation Prefix: $obs_prefix"
fi

# Ensure all required inputs are set
if [[ -z "$season" || -z "$projection" || -z "$lat_range" || -z "$lon_range" || -z "$model1_prefix" || -z "$obs_prefix" ]]; then
    echo "Error: Missing required arguments. Check input variables."
    exit 1
fi

# Define output directory
output_dir="./output_data"
mkdir -p "$output_dir"

# Define variable mappings
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

# Log skipped variables
skipped_log="$output_dir/skipped_plot_variables.log"
> "$skipped_log"

# Function to regrid data
function regrid_data {
    local var="$1"
    local suffix="$2"
    local obs_var="${variable_mapping[$var]:-$var}"

    if $debug; then
        echo "Debug: Regridding data for $var ($suffix)..."
    fi

    # Define file paths
    local obs_annual="${obs_prefix}annual_mean_${obs_var}.nc"
    local obs_season="${obs_prefix}${season}_mean_${obs_var}.nc"
    local obs_annual_regridded="${output_dir}/obs_annual_mean_${obs_var}_regridded.nc"
    local obs_season_regridded="${output_dir}/obs_${season}_mean_${obs_var}_regridded.nc"

    local model1_annual="${model1_prefix}_annual_mean_${var}${suffix}.nc"
    local model1_season="${model1_prefix}_${season}_mean_${var}${suffix}.nc"
    local model2_annual="${model2_prefix}_annual_mean_${var}${suffix}.nc"
    local model2_season="${model2_prefix}_${season}_mean_${var}${suffix}.nc"

    local model1_grid="${model1_prefix}_grid.txt"
    if [ ! -f "$model1_grid" ]; then
        echo "Extracting grid for Model 1..."
        cdo griddes "$model1_annual" > "$model1_grid"
        check_error "Extracting grid for Model 1"
    fi

    # Regrid observation data
    if [ ! -f "$obs_annual_regridded" ]; then
        verify_file "$obs_annual" || return
        cdo -selvar,"$obs_var" "$obs_annual" temp_$obs_var.nc
        cdo remapbil,"$model1_grid" temp_$obs_var.nc "$obs_annual_regridded"
        rm temp_$obs_var.nc

        check_error "Regridding annual observation data for $var"
    fi
    if [ ! -f "$obs_season_regridded" ]; then
        verify_file "$obs_season" || return
        cdo -selvar,"$obs_var" "$obs_season" temp_$obs_var.nc
	cdo remapbil,"$model1_grid" temp_$obs_var.nc "$obs_season_regridded"
	rm temp_$obs_var.nc

        check_error "Regridding seasonal observation data for $var"
    fi

    # Regrid Model 2 data if provided
    if [[ -n "$model2_prefix" ]]; then
        echo "Regridding Model 2 data for $var..."
        if [ ! -f "${output_dir}/model2_annual_mean_${var}${suffix}_regridded.nc" ]; then
            verify_file "$model2_annual" || return
            cdo remapbil,"$model1_grid" "$model2_annual" "${output_dir}/model2_annual_mean_${var}${suffix}_regridded.nc"
            check_error "Regridding Model 2 annual data for $var"
        fi
        if [ ! -f "${output_dir}/model2_${season}_mean_${var}${suffix}_regridded.nc" ]; then
            verify_file "$model2_season" || return
            cdo remapbil,"$model1_grid" "$model2_season" "${output_dir}/model2_${season}_mean_${var}${suffix}_regridded.nc"
            check_error "Regridding Model 2 seasonal data for $var"
        fi
    fi
}

# Function to call specialized plot scripts
function call_specialized_plot {
    local var="$1"
    local suffix="$2"
    local obs_var="${variable_mapping[$var]:-$var}"

    if $debug; then
        echo "Debug: Calling specialized plot script for $var ($suffix)..."
    fi

    local plot_script="./special_plot_${var}.sh"
    if [ ! -f "$plot_script" ]; then
        echo "Error: Plotting script $plot_script not found. Skipping..."
        echo "$var: Plotting script not found" >> "$skipped_log"
        return
    fi

    local obs_annual_regridded="${output_dir}/obs_annual_mean_${obs_var}_regridded.nc"
    local obs_season_regridded="${output_dir}/obs_${season}_mean_${obs_var}_regridded.nc"
    local model1_annual="${model1_prefix}_annual_mean_${var}${suffix}.nc"
    local model1_season="${model1_prefix}_${season}_mean_${var}${suffix}.nc"
    local model2_annual_regridded="${output_dir}/model2_annual_mean_${var}${suffix}_regridded.nc"
    local model2_season_regridded="${output_dir}/model2_${season}_mean_${var}${suffix}_regridded.nc"

    # Call plot script
    if [[ -n "$model2_prefix" ]]; then
        "$plot_script" "$obs_annual_regridded" "$obs_season_regridded" "$model1_annual" "$model1_season"  "$projection" "$lat_range" "$lon_range" "$season" "$model2_annual_regridded" "$model2_season_regridded"
    else
        "$plot_script" "$obs_annual_regridded" "$obs_season_regridded" "$model1_annual" "$model1_season" "$projection" "$lat_range" "$lon_range" "$season"
    fi
}

# Process each variable
for var in "${plev_variables[@]}" "${no_plev_variables[@]}"; do
    suffix="_plev"
    if [[ " ${no_plev_variables[@]} " =~ " $var " ]]; then
        suffix="_no_plev"
    fi
    regrid_data "$var" "$suffix"
    #call_specialized_plot "$var" "$suffix"
done


: << 'COMMENT_BLOCK'
echo "This part will be skipped."
COMMENT_BLOCK
#########========================
function is_variable_in_list {
    local pvar="$1"
    for item in "${var_list[@]}"; do
        if [[ "$item" == "$pvar" ]]; then
            return 0  # Found
        fi
    done
    return 1  # Not found
}

#==============================================
# Check if "tas" is in the variable list (ensure the function exists)
if is_variable_in_list "tas"; then
    echo "Processing TAS..."

    # Run fldmean calculations in parallel
    cdo fldmean "${model1_prefix}_tas_annual_all_year_no_plev.nc" "${model1_prefix}_tas_all_year_fldmean_no_plev.nc" &
    cdo fldmean "${model2_prefix}_tas_annual_all_year_no_plev.nc" "${model2_prefix}_tas_all_year_fldmean_no_plev.nc" &
    cdo fldmean "${output_dir}/obs_t2m_all_years.nc" "${output_dir}/obs_t2m_all_years_fldmean.nc" &

    # Wait for all CDO operations to finish before proceeding
    wait

    # Call specialized plot function for TAS
    suffix="_no_plev"
    call_specialized_plot "tas" "$suffix"

    # Run NCL scripts sequentially
    if [[ -f "TAS_timeseries_plot_ann.ncl" && -f "TAS_timeseries_plot_ann_24yr_common.ncl" ]]; then
        ncl TAS_timeseries_plot_ann.ncl
        ncl TAS_timeseries_plot_ann_24yr_common.ncl
    else
        echo "Error: One or both NCL scripts not found!"
    fi

    echo "TAS processing and plotting completed."
fi


######=================================================================
if is_variable_in_list "pr"; then
    echo "Processing PR..."
    
    # Call the specialized plot function
    suffix="_no_plev"
    call_specialized_plot "pr" "$suffix"

    # Define the target grid
    export target_grid="./India_grid.txt"

    # Check if the target grid file exists
    if [[ ! -f "$target_grid" ]]; then
        echo "Error: Target grid file $target_grid not found!"
        exit 1
    fi

    # Perform CDO regridding in parallel
    (
        if [[ -f output_data/model1_pr_annual_all_year_no_plev.nc ]]; then
            cdo remapbil,"$target_grid" output_data/model1_pr_annual_all_year_no_plev.nc \
                output_data/model1_pr_annual_all_year_no_plev_regrid.nc
        else
            echo "Warning: Model1 PR file not found!"
        fi
    ) &

    (
        if [[ -f output_data/model2_pr_annual_all_year_no_plev.nc ]]; then
            cdo remapbil,"$target_grid" output_data/model2_pr_annual_all_year_no_plev.nc \
                output_data/model2_pr_annual_all_year_no_plev_regrid.nc
        else
            echo "Warning: Model2 PR file not found!"
        fi
    ) &

    (
        if [[ -f output_data/obs_precip_all_years.nc ]]; then
            cdo remapbil,"$target_grid" -selvar,precip output_data/obs_precip_all_years.nc \
                output_data/obs_precip_all_years_regrid.nc
        else
            echo "Warning: Observational PR file not found!"
        fi
    ) &

    # Wait for all CDO processes to finish before moving on
    wait

    echo "Regridding completed for PR."

    # Check if NCL scripts exist before running
    if [[ -f precip_monthly_climatology_box1.ncl ]]; then
        ncl precip_monthly_climatology_box1.ncl
    else
        echo "Warning: precip_monthly_climatology_box1.ncl not found!"
    fi

    if [[ -f precip_monthly_climatology_box2.ncl ]]; then
        ncl precip_monthly_climatology_box2.ncl
    else
        echo "Warning: precip_monthly_climatology_box2.ncl not found!"
    fi

    echo "PR processing and plotting completed."
fi

####==============================================================================
for var in "slp" ; do
    suffix="_plev"
    call_specialized_plot "$var" "$suffix"
done
if is_variable_in_list "slp"; then
    echo "Processing SLP..."

    # Call the specialized plot function
    suffix="_plev"
    call_specialized_plot "slp" "$suffix"
    
    echo "SLP processing and plotting completed."
fi

: << 'COMMENT_BLOCK'
echo "This part will be skipped."
###############
for var in "evspsbl" ; do
    suffix="_no_plev"
    call_specialized_plot "$var" "$suffix"
done
######============================================================================
for var in "ta" ; do
    suffix="_plev"
    call_specialized_plot "$var" "$suffix"
    
    ncl ta_level_lat_ann.ncl
    ncl ta_level_lat_season.ncl
    ncl ta_level_lon_ann.ncl
    ncl ta_level_lon_season.ncl
    
    
done

#########========================================================================
# Define suffix for pressure levels
suffix="_plev"

# Define file paths for hght (annual and seasonal)
obs_annual_regridded_hght="${output_dir}/obs_annual_mean_z_regridded.nc"
obs_season_regridded_hght="${output_dir}/obs_${season}_mean_z_regridded.nc"
model1_annual_hght="${model1_prefix}_annual_mean_hght${suffix}.nc"
model1_season_hght="${model1_prefix}_${season}_mean_hght${suffix}.nc"
model2_annual_regridded_hght="${output_dir}/model2_annual_mean_hght${suffix}_regridded.nc"
model2_season_regridded_hght="${output_dir}/model2_${season}_mean_hght${suffix}_regridded.nc"

# Debugging info
echo "Processing Geopetential Height plots for hght: Annual and Seasonal"

# Call specialized plotting script for annual data (hght)
./special_plot_hght_ann.sh "$obs_annual_regridded_hght" "$model1_annual_hght" "$projection" "$lat_range" "$lon_range" "$season" "$model2_annual_regridded_hght" 

./special_plot_hght_season.sh "$obs_season_regridded_hght" "$model1_season_hght" "$projection" "$lat_range" "$lon_range" "$season" "$model2_season_regridded_hght"
echo "Height (hght) plotting completed."
#########=========================================================================

# Define suffix for pressure levels
suffix="_plev"

# Define file paths for ua and va (annual and seasonal)
obs_annual_regridded_ua="${output_dir}/obs_annual_mean_u_regridded.nc"
obs_season_regridded_ua="${output_dir}/obs_${season}_mean_u_regridded.nc"
model1_annual_ua="${model1_prefix}_annual_mean_ua${suffix}.nc"
model1_season_ua="${model1_prefix}_${season}_mean_ua${suffix}.nc"
model2_annual_regridded_ua="${output_dir}/model2_annual_mean_ua${suffix}_regridded.nc"
model2_season_regridded_ua="${output_dir}/model2_${season}_mean_ua${suffix}_regridded.nc"

obs_annual_regridded_va="${output_dir}/obs_annual_mean_v_regridded.nc"
obs_season_regridded_va="${output_dir}/obs_${season}_mean_v_regridded.nc"
model1_annual_va="${model1_prefix}_annual_mean_va${suffix}.nc"
model1_season_va="${model1_prefix}_${season}_mean_va${suffix}.nc"
model2_annual_regridded_va="${output_dir}/model2_annual_mean_va${suffix}_regridded.nc"
model2_season_regridded_va="${output_dir}/model2_${season}_mean_va${suffix}_regridded.nc"

# Debugging info
echo "Processing wind plots for both ua and va: Annual and Seasonal"

# Call specialized plotting script for annual data (ua and va together)
./special_plot_wind_ann.sh "$obs_annual_regridded_ua" "$obs_annual_regridded_va" "$model1_annual_ua" "$model1_annual_va" "$projection" "$lat_range" "$lon_range" "$season" "$model2_annual_regridded_ua" "$model2_annual_regridded_va"

./special_plot_wind_season.sh "$obs_season_regridded_ua" "$obs_season_regridded_va" "$model1_season_ua" "$model1_season_va" "$projection" "$lat_range" "$lon_range" "$season" "$model2_annual_regridded_ua" "$model2_annual_regridded_va"
check_error "Annual plotting for ua and va"


check_error "Seasonal plotting for ua and va"

echo "Wind plotting for both ua and va completed."


##########===========================================================================

# Define suffix for pressure levels
echo "Processing radiation data rsdt, rlut, and rsut: Annual and Seasonal"
suffix="_no_plev"

# Define file paths for rsdt, rlut, and rsut (annual and seasonal)
obs_annual_regridded_rsdt="${output_dir}/obs_annual_mean_solar_mon_regridded.nc"
obs_season_regridded_rsdt="${output_dir}/obs_${season}_mean_solar_mon_regridded.nc"
model1_annual_rsdt="${model1_prefix}_annual_mean_rsdt${suffix}.nc"
model1_season_rsdt="${model1_prefix}_${season}_mean_rsdt${suffix}.nc"
model2_annual_regridded_rsdt="${output_dir}/model2_annual_mean_rsdt${suffix}_regridded.nc"
model2_season_regridded_rsdt="${output_dir}/model2_${season}_mean_rsdt${suffix}_regridded.nc"

obs_annual_regridded_rlut="${output_dir}/obs_annual_mean_toa_lw_all_mon_regridded.nc"
obs_season_regridded_rlut="${output_dir}/obs_${season}_mean_toa_lw_all_mon_regridded.nc"
model1_annual_rlut="${model1_prefix}_annual_mean_rlut${suffix}.nc"
model1_season_rlut="${model1_prefix}_${season}_mean_rlut${suffix}.nc"
model2_annual_regridded_rlut="${output_dir}/model2_annual_mean_rlut${suffix}_regridded.nc"
model2_season_regridded_rlut="${output_dir}/model2_${season}_mean_rlut${suffix}_regridded.nc"

obs_annual_regridded_rsut="${output_dir}/obs_annual_mean_toa_sw_all_mon_regridded.nc"
obs_season_regridded_rsut="${output_dir}/obs_${season}_mean_toa_sw_all_mon_regridded.nc"
model1_annual_rsut="${model1_prefix}_annual_mean_rsut${suffix}.nc"
model1_season_rsut="${model1_prefix}_${season}_mean_rsut${suffix}.nc"
model2_annual_regridded_rsut="${output_dir}/model2_annual_mean_rsut${suffix}_regridded.nc"
model2_season_regridded_rsut="${output_dir}/model2_${season}_mean_rsut${suffix}_regridded.nc"

# Debugging info
echo "Processing radiation plots for rsdt, rlut, and rsut: Annual and Seasonal"

# Call specialized plotting script for annual data (rsdt, rlut, rsut together)
./special_plot_radiation_ann.sh "$obs_annual_regridded_rsdt" "$obs_annual_regridded_rlut" "$obs_annual_regridded_rsut" \
"$model1_annual_rsdt" "$model1_annual_rlut" "$model1_annual_rsut" \
"$projection" "$lat_range" "$lon_range" "$season" \
"$model2_annual_regridded_rsdt" "$model2_annual_regridded_rlut" "$model2_annual_regridded_rsut"
check_error "Annual plotting for rsdt, rlut, and rsut"

# Call specialized plotting script for seasonal data (rsdt, rlut, rsut together)
./special_plot_radiation_season.sh "$obs_season_regridded_rsdt" "$obs_season_regridded_rlut" "$obs_season_regridded_rsut" \
"$model1_season_rsdt" "$model1_season_rlut" "$model1_season_rsut" \
"$projection" "$lat_range" "$lon_range" "$season" \
"$model2_season_regridded_rsdt" "$model2_season_regridded_rlut" "$model2_season_regridded_rsut"
check_error "Seasonal plotting for rsdt, rlut, and rsut"

echo "Radiation plotting for rsdt, rlut, and rsut completed."

####===========================================================
COMMENT_BLOCK






echo "Plotting completed successfully. Outputs saved in $output_dir."

