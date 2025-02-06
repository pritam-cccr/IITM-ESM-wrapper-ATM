# ==============================================================================
#  Copyright (C) 2025 Centre for Climate Change Research (CCCR), IITM
#
#  This script is part of the CCCR IITM_ESM diagnostics system.
#
#  Author: Pritam Das Mahapatra
#  Date: January 2025
#  Version: 1.0
#
# ==============================================================================

import sys
import os
import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
import matplotlib
matplotlib.use('Agg')  # For non-interactive backend

# Read input arguments
model1_season = sys.argv[1]
model2_season = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] != "" else None
obs_season = sys.argv[3]
bias1_season = sys.argv[4]
bias2_season = sys.argv[5] if len(sys.argv) > 5 and sys.argv[5] != "" else None
bias3_season = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] != "" else None
var = sys.argv[7]
obs_var = sys.argv[8]
output_dir = sys.argv[9]
projection = sys.argv[10]
lat_range = sys.argv[11]
lon_range = sys.argv[12]
season = sys.argv[13]
print(f"Received lat_range: {lat_range}")
print(f"Received lon_range: {lon_range}")

lat_range = lat_range.strip()
lon_range = lon_range.strip()

# Parse latitude and longitude ranges
try:
    lat_min, lat_max = map(float, lat_range.split(","))
    lon_min, lon_max = map(float, lon_range.split(","))
except ValueError:
    print(f"Error: Latitude or Longitude range is not properly defined. Ensure ranges are in 'min,max' format.")
    sys.exit(1)

# Debugging Information
print("=== INPUT ARGUMENTS ===")
print(f"Model 1 season Mean: {model1_season}")
print(f"Model 2 season Mean: {model2_season if model2_season else 'Not provided'}")
print(f"Observation season: {obs_season}")
print(f"bias1 season: {bias1_season}")
print(f"bias2 season: {bias2_season}")
print(f"bias3 season: {bias3_season}")
print(f"Projection: {projection}")
print(f"Latitude Range: {lat_min} to {lat_max}")
print(f"Longitude Range: {lon_min} to {lon_max}")
print(f"Longitude Range: {var} and {obs_var}")
print(f"Season: {season}")
print("========================")



def create_levels(min_val, max_val, step=2.5):
    """Generate evenly spaced levels."""
    return np.arange(min_val, max_val + step, step)

def create_levelsB(min_val, max_val, step=0.5):
    """Generate evenly spaced levels."""
    return np.arange(min_val, max_val + step, step)

def get_projection(projection_name):
    """Retrieve Cartopy projection dynamically."""
    try:
        return getattr(ccrs, projection_name)()
    except AttributeError:
        print(f"Error: Projection '{projection_name}' not found.")
        sys.exit(1)
# Projection-specific plotting functions
def plot_platecarree(ax, data, lon_name, lat_name, levels, cmap, lat_min, lat_max, lon_min, lon_max, title):
    contour = ax.contourf(data[lon_name], data[lat_name], data, transform=ccrs.PlateCarree(), levels=levels, cmap=cmap, extend="both")
    ax.coastlines()
    ax.set_extent([lon_min, lon_max, lat_min, lat_max], crs=ccrs.PlateCarree())
    ax.set_xticks(np.linspace(lon_min, lon_max, 5), crs=ccrs.PlateCarree())
    ax.set_yticks(np.linspace(lat_min, lat_max, 5), crs=ccrs.PlateCarree())
    ax.xaxis.set_major_formatter(LongitudeFormatter())
    ax.yaxis.set_major_formatter(LatitudeFormatter())
    ax.tick_params(labelsize=10)
    ax.set_title(title)
    return contour

def plot_robinson(ax, data, lon_name, lat_name, levels, cmap, lat_min, lat_max, lon_min, lon_max, title):
    contour = ax.contourf(data[lon_name], data[lat_name], data, transform=ccrs.PlateCarree(), levels=levels, cmap=cmap, extend="both")
    ax.coastlines()
    ax.add_feature(cfeature.BORDERS)
    gl = ax.gridlines(draw_labels=True, linewidth=1, color="gray", alpha=0.5, linestyle="--")
    gl.xformatter = LongitudeFormatter()
    gl.yformatter = LatitudeFormatter()
    gl.top_labels = False
    gl.right_labels = False
    ax.set_title(title)
    return contour

def plot_polar_stereo(ax, data, lon_name, lat_name, levels, cmap, lat_min, lat_max, lon_min, lon_max, title):
    contour = ax.contourf(data[lon_name], data[lat_name], data, transform=ccrs.PlateCarree(), levels=levels, cmap=cmap, extend="both")
    ax.coastlines()
    ax.add_feature(cfeature.BORDERS)
    gl = ax.gridlines(draw_labels=True, linewidth=1, color="gray", alpha=0.5, linestyle="--")
    gl.xformatter = LongitudeFormatter()
    gl.yformatter = LatitudeFormatter()
    gl.top_labels = False
    gl.right_labels = False
    ax.set_title(title)
    return contour


# Utility function for selecting and averaging over pressure levels
def average_over_levels(dataset, variable, min_plev, max_plev):
    """
    Dynamically selects the pressure level dimension and averages the variable.
    """
    possible_plev_dims = ["plev", "level", "pressure_level"]
    plev_dim = next((dim for dim in possible_plev_dims if dim in dataset.dims), None)

    if not plev_dim:
        print(f"Error: None of the expected pressure level dimensions ({possible_plev_dims}) found in dataset.")
        print(f"Available dimensions: {list(dataset.dims.keys())}")
        sys.exit(1)

    if variable not in dataset:
        print(f"Error: Variable '{variable}' not found in dataset.")
        print(f"Available variables: {list(dataset.data_vars.keys())}")
        sys.exit(1)

    return dataset[variable].sel({plev_dim: slice(min_plev, max_plev)}).mean(dim=plev_dim)

# Load and process all datasets
datasets = {
    "model1": (model1_season, var, False),
    "model2": (model2_season, var, False),
    "obs": (obs_season, obs_var, False),
    "bias1": (bias1_season, var, True),
    "bias2": (bias2_season, var, True),
    "bias3": (bias3_season, var, True)
}

processed_data = {}
min_plev, max_plev = 600, 200  # Pressure range in hPa

for key, (file_path, variable, is_bias) in datasets.items():
    if file_path:
        try:
            # Open the dataset
            ds = xr.open_dataset(file_path, decode_times=False)

            # Verify if the variable exists in the dataset
            if variable not in ds:
                print(f"Error: Variable '{variable}' not found in {key}. Available variables: {list(ds.data_vars.keys())}")
                sys.exit(1)

            # Perform pressure level averaging
            avg_data = average_over_levels(ds, variable, min_plev, max_plev)

            # Eliminate the 'time' or 'valid_time' dimension if it exists
            if "time" in avg_data.dims:
                avg_data = avg_data.isel(time=0).squeeze()
            elif "valid_time" in avg_data.dims:
                avg_data = avg_data.isel(valid_time=0).squeeze()
            else:
                print("No recognized time dimension found in the data.")

            # Skip transformations
            processed_data[key] = avg_data  # No unit conversion applied
            print(f"{key} processed successfully. Shape: {processed_data[key].shape}")

        except Exception as e:
            print(f"Error processing {key}: {e}")
            sys.exit(1)
    else:
        print(f"{key} not provided, skipping.")

            
# Dynamically identify coordinates
lon_name = "lon" if "lon" in processed_data["model1"].coords else "longitude"
lat_name = "lat" if "lat" in processed_data["model1"].coords else "latitude"

# Define levels
mean_levels = create_levels(220, 260)  # Adjust range for temperature data
bias_levels = create_levelsB(-8, 8)  # Adjust for bias range



mean_cmap = 'rainbow'  # For model and observation
bias_cmap = 'coolwarm'  # For bias


# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Get projection dynamically
proj = get_projection(projection)

# Select the correct plotting function based on the projection
if isinstance(proj, ccrs.PlateCarree):
    plot_function = plot_platecarree
elif isinstance(proj, ccrs.Robinson):
    plot_function = plot_robinson
elif isinstance(proj, (ccrs.NorthPolarStereo, ccrs.SouthPolarStereo)):
    plot_function = plot_polar_stereo
else:
    print(f"Error: Unsupported projection type '{projection}'")
    sys.exit(1)

# Conditional plotting based on the presence of Model 2
if "model2" in processed_data and processed_data["model2"] is not None:
    # Create a 3x2 grid for plotting when Model 2 data is present
    fig, axes = plt.subplots(3, 2, figsize=(15, 18), subplot_kw={"projection": proj})

    # Plot Observation season Mean
    contour1 = plot_function(axes[0, 0], processed_data["obs"], lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Observation season Mean (°C)")
    fig.colorbar(contour1, ax=axes[0, 0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Bias between Model 1 and Model 2
    if "bias3" in processed_data and processed_data["bias3"] is not None:
        contour2 = plot_function(axes[0, 1], processed_data["bias3"], lon_name, lat_name, bias_levels, bias_cmap,
                                 lat_min, lat_max, lon_min, lon_max, "Bias (CMIP7 - CMIP6)")
        fig.colorbar(contour2, ax=axes[0, 1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)
    else:
        axes[0, 1].remove()

    # Plot Model 1 season Mean
    contour3 = plot_function(axes[1, 0], processed_data["model1"], lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "CMIP7 season Mean (°C)")
    fig.colorbar(contour3, ax=axes[1, 0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Model 2 season Mean
    contour4 = plot_function(axes[2, 0], processed_data["model2"], lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "CMIP6 season Mean (°C)")
    fig.colorbar(contour4, ax=axes[2, 0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Bias between Model 1 and Observation
    if "bias1" in processed_data and processed_data["bias1"] is not None:
        contour5 = plot_function(axes[1, 1], processed_data["bias1"], lon_name, lat_name, bias_levels, bias_cmap,
                                 lat_min, lat_max, lon_min, lon_max, "Bias (CMIP7 - Obs)")
        fig.colorbar(contour5, ax=axes[1, 1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)
    else:
        axes[2, 0].remove()

    # Plot Bias between Model 2 and Observation
    if "bias2" in processed_data and processed_data["bias2"] is not None:
        contour6 = plot_function(axes[2, 1], processed_data["bias2"], lon_name, lat_name, bias_levels, bias_cmap,
                                 lat_min, lat_max, lon_min, lon_max, "Bias (CMIP6 - Obs)")
        fig.colorbar(contour6, ax=axes[2, 1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)
    else:
        axes[2, 1].remove()

    # Save plot
    output_file = os.path.join(output_dir, f"{var}_season_comparison_with_model2_{projection}_600-200hPa.png")

else:
    # Create a 1x3 grid for plotting when Model 2 data is absent
    fig, axes = plt.subplots(1, 3, figsize=(18, 6), subplot_kw={"projection": proj})

    # Plot Observation season Mean
    contour1 = plot_function(axes[0], processed_data["obs"], lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Observation season Mean (°C)")
    fig.colorbar(contour1, ax=axes[0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Model 1 season Mean
    contour2 = plot_function(axes[1], processed_data["model1"], lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Model 1 season Mean (°C)")
    fig.colorbar(contour2, ax=axes[1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Bias between Model 1 and Observation
    if "bias1" in processed_data and processed_data["bias1"] is not None:
        contour3 = plot_function(axes[2], processed_data["bias1"], lon_name, lat_name, bias_levels, bias_cmap,
                                 lat_min, lat_max, lon_min, lon_max, "Bias (Obs - Model 1)")
        fig.colorbar(contour3, ax=axes[2], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)
    else:
        axes[2].remove()

    # Save plot
    output_file = os.path.join(output_dir, f"{var}_season_comparison_with_model2_{projection}.png")



# Save the plot
plt.savefig(output_file)
print(f"Plot saved to {output_file}")
plt.close()

