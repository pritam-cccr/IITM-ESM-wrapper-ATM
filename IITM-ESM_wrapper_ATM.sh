#!/bin/bash
# DESCRIPTION: Wrapper script for IITM_ESM diagnostics with optional model comparison
# Last updated: December 2024

######################################### USER INPUT SECTION ##########################################

# Check if the user input file exists
if [[ ! -f "user_inputs_atm.sh" ]]; then
    echo "Error: 'user_inputs.sh' file not found. Please create this file with required inputs."
    exit 1
fi

# Source user inputs from the external file
source ./user_inputs_atm.sh

# Check if output directory variable is set
if [[ -z "$output_dir" ]]; then
    echo "Error: Output directory variable 'output_dir' not set in user_inputs_atm.sh"
    exit 1
fi

# Initialize output directory
mkdir -p "$output_dir"
echo "Output files will be saved in $output_dir"
# Error handling and cleanup
function check_error {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

function cleanup {
    echo "Cleaning up temporary files..."
    rm -f temp_model1_*.nc temp_model2_*.nc temp_obs_*.nc model_grid_*.nc temp_*_*_data.nc 2>/dev/null || true
}
trap cleanup EXIT

# Ensure necessary arguments are provided
required_vars=(
    diagnostic_type plev_variables no_plev_variables netcdf_dir_model1 start_year_model1 end_year_model1
    season projection lat_range lon_range obs_data_dir start_year_obs end_year_obs
)

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: Required variable '$var' is missing in 'user_inputs.sh'."
        exit 1
    fi
done

# Check if a second model is provided
use_second_model=false
if [[ -n "$netcdf_dir_model2" && -n "$start_year_model2" && -n "$end_year_model2" ]]; then
    use_second_model=true
fi

# Convert variable lists to arrays
IFS=',' read -r -a plev_variables_array <<< "$plev_variables"
IFS=',' read -r -a no_plev_variables_array <<< "$no_plev_variables"

# Enable debug mode if requested
if [ "$debug" = true ]; then
    set -x
fi

# Display parsed variables
echo "Selected diagnostic type: $diagnostic_type"
echo "Pressure-level variables: ${plev_variables_array[@]}"
echo "Non-pressure-level variables: ${no_plev_variables_array[@]}"
echo "Season: $season"
echo "Projection: $projection"
echo "Latitude range: $lat_range"
echo "Longitude range: $lon_range"
echo "Using model 1 data directory: $netcdf_dir_model1"
if [ "$use_second_model" = true ]; then
    echo "Using model 2 data directory: $netcdf_dir_model2"
fi




######################################### MODEL PROCESSING ##########################################

# Function to run model data processing
function process_model {
    local model_num=$1
    local model_dir=$2
    local start_year=$3
    local end_year=$4
    local output_prefix=$5
    
    echo "Starting processing for Model $model_num with pressure-level variables..."
    ./process_model_data_plev.sh "${plev_variables_array[@]}" "$season" "$model_dir" "$start_year" "$end_year" "$output_prefix"
    check_error "Model $model_num processing with pressure levels failed."
    echo "Model $model_num processing for pressure-level variables completed."

    echo "Starting processing for Model $model_num with non-pressure-level variables..."
    ./process_model_data_no_plev.sh "${no_plev_variables_array[@]}" "$season" "$model_dir" "$start_year" "$end_year" "$output_prefix"
    check_error "Model $model_num processing without pressure levels failed."
    echo "Model $model_num processing for non-pressure-level variables completed."
}

# Process Model 1 with its prefix
process_model "1" "$netcdf_dir_model1" "$start_year_model1" "$end_year_model1" "$output_prefix_model1"

# Process Model 2 if present, with its prefix
if [ "$use_second_model" = true ]; then
    process_model "2" "$netcdf_dir_model2" "$start_year_model2" "$end_year_model2" "$output_prefix_model2"
fi

######################################### OBSERVATION PROCESSING ##########################################

echo "Starting observation data processing..."
# Pass plev and no_plev variables explicitly, followed by other arguments.
./observation_data_processing_atm.sh "${plev_variables_array[@]}" "<SEP>" "${no_plev_variables_array[@]}" "$obs_data_dir" "$start_year_obs" "$end_year_obs" "$season"
check_error "Observation data processing failed."
echo "Observation data processing completed."

######################################### PLOTTING ##########################################

echo "Starting plotting functions..."

# Validate required variables and arrays
if [ -z "$season" ] || [ -z "$projection" ] || [ -z "$lat_range" ] || [ -z "$lon_range" ]; then
    echo "Error: One or more required variables (season, projection, lat_range, lon_range) are not set."
    exit 1
fi

if [ ${#plev_variables_array[@]} -eq 0 ] && [ ${#no_plev_variables_array[@]} -eq 0 ]; then
    echo "Error: Both plev_variables_array and no_plev_variables_array are empty. Nothing to process."
    exit 1
fi

if [ -z "$output_dir" ] || [ -z "$output_prefix_model1" ]; then
    echo "Error: Output directory or Model 1 prefix is not set."
    exit 1
fi

# Debug mode handling
debug_flag=""
if $debug; then
    debug_flag="-d"
    echo "Debug: Starting plotting with the following inputs:"
    echo "  Pressure-Level Variables: ${plev_variables_array[@]}"
    echo "  Non-Pressure-Level Variables: ${no_plev_variables_array[@]}"
    echo "  Season: $season"
    echo "  Projection: $projection"
    echo "  Latitude Range: $lat_range"
    echo "  Longitude Range: $lon_range"
    echo "  Output Directory: $output_dir"
    echo "  Model 1 Prefix: $output_prefix_model1"
    echo "  Model 2 Prefix: ${output_prefix_model2:-'Not Used'}"
    echo "  Observation Prefix: final_obs_"
fi

# Verify plotting script existence
if [ ! -f "./plotting_functions_new.sh" ]; then
    echo "Error: Plotting script 'plotting_functions_new.sh' not found."
    exit 1
fi

# Run the plotting script
if [ "$use_second_model" = true ]; then
    ./plotting_functions_new.sh $debug_flag \
        "${plev_variables_array[@]}" "<SEP>" "${no_plev_variables_array[@]}" \
        "$season" "$projection" "$lat_range" "$lon_range" \
        "$output_dir/${output_prefix_model1}" "$output_dir/${output_prefix_model2}" "$output_dir/final_obs_" "$start_year" "$end_year"
else
    ./plotting_functions_new.sh $debug_flag \
        "${plev_variables_array[@]}" "<SEP>" "${no_plev_variables_array[@]}" \
        "$season" "$projection" "$lat_range" "$lon_range" \
        "$output_dir/${output_prefix_model1}" "$output_dir/final_obs_"
fi

if [ $? -ne 0 ]; then
    echo "Error: Plotting script failed to execute successfully."
    exit 1
fi


echo "Plotting completed successfully."



echo "Processing and plotting completed successfully. Outputs are saved in $output_dir."

echo "COPY ALL PLOTS into PLOT folder"
mkdir -p PLOT
find . -type f \( -iname "*.png" -o -iname "*.pdf" \) -exec cp {} PLOT/ \;

# Remove all .nc files from current and subdirectories
#find . -type f -name "*.nc" -exec rm -f {} \;
#
#echo "All .nc files have been removed from the current and subdirectories."



