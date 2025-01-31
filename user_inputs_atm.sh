#!/bin/bash
# User inputs for IITM_ESM diagnostic wrapper script
# Last updated: November 2024

# Diagnostic settings
diagnostic_type="climate_analysis"  # Example: "climate_analysis" or "model_comparison"
component_type="ATM"                # Component type: "ATM" (Atmosphere), "OCN" (Ocean), "ICE" (Ice)

# Variables to process (comma-separated lists for pressure-level and non-pressure-level variables)
plev_variables="slp"   #ua,va,ta,slp,hght       # Variables that require pressure-level data (e.g., "tas,ua,va")
no_plev_variables="tas,pr" #tas,pr,rsdt,rlut,rsut         # Variables without pressure-level data (e.g., "pr,psl")

# Output directory for all generated files
plot_dir="/home/iitm/IITM_ESM_WRAPPER/OUTPUT"  # Specify where output files should be saved
plot_var="slp,tas,pr"
# Model 1 data settings
netcdf_dir_model1="/media/iitm/TOSHIBA_PRITAM/CMIP7-2390-2442/ATM"  # Directory containing Model 1 data files
start_year_model1=2391             # Start year for Model 1 data
end_year_model1=2395                    # End year for Model 1 data
output_prefix_model1="model1"                     # Output file prefix for Model 1
# Model 2 data settings (optional for comparison)
netcdf_dir_model2="/media/iitm/TOSHIBA_PRITAM/CMIP6/ATM"  # Directory containing Model 2 data files (leave blank if not comparing)
start_year_model2=1990                  # Start year for Model 2 data (if using Model 2)
end_year_model2=2014              # End year for Model 2 data (if using Model 2)
output_prefix_model2="model2"         # Output file prefix for Model 2 (only if comparing)
# Observation data settings
obs_data_dir="/media/iitm/TOSHIBA_PRITAM/OBS_1990_2020"  # Directory containing observational data files
start_year_obs=1990                     # Start year for observational data
end_year_obs=2020                   # End year for observational data

# Seasonal settings
season="JJAS"                             # Season to analyze (e.g., "DJF", "MAM", "JJA", "SON", "JJAS")

# Plot settings (customized per component type)
if [ "$component_type" = "ATM" ]; then
    projection="Robinson"                 # Projection type for atmospheric data (e.g., "robinson")
    lat_range="-90,90"                    # Latitude range for global analysis
    lon_range="0,360"                     # Longitude range for global analysis
elif [ "$component_type" = "OCN" ]; then
    projection="mercator"                 # Projection for ocean data
    lat_range="-50,50"                    # Focused latitude range for ocean data
    lon_range="120,290"                   # Focused longitude range for ocean data
elif [ "$component_type" = "ICE" ]; then
    projection="polar"                    # Polar projection for ice data
    lat_range="60,90"                     # High-latitude range for ice analysis
    lon_range="0,360"                     # Full longitude range
else
    echo "Error: Invalid component type. Must be 'ATM', 'OCN', or 'ICE'."
    exit 1
fi

if [ "$debug" = true ]; then
    set -x  # Enable verbose output
fi

