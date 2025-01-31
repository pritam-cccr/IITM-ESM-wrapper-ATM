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
model1_annual = sys.argv[1]
model2_annual = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] != "" else None
obs_annual = sys.argv[3]
bias1_annual = sys.argv[4]
bias2_annual = sys.argv[5] if len(sys.argv) > 5 and sys.argv[5] != "" else None
bias3_annual = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] != "" else None
var = sys.argv[7]
obs_var = sys.argv[8]
output_dir = sys.argv[9]
projection = sys.argv[10]
lat_range = sys.argv[11]
lon_range = sys.argv[12]

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
print(f"Model 1 Annual Mean: {model1_annual}")
print(f"Model 2 Annual Mean: {model2_annual if model2_annual else 'Not provided'}")
print(f"Observation Annual: {obs_annual}")
print(f"Projection: {projection}")
print(f"Latitude Range: {lat_min} to {lat_max}")
print(f"Longitude Range: {lon_min} to {lon_max}")
print(f"Longitude Range: {var} and {obs_var}")
print("========================")

# Utility functions
def apply_variable_transformations(data, var, obs_var):
    """Apply unit conversions for specific variables."""
    if var == "tas" and obs_var == "t2m":
        return data - 273.15  # Convert Kelvin to Celsius
    return data

def create_levels(min_val, max_val, step=2):
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
    contour = ax.contourf(data[lon_name], data[lat_name], data, transform=ccrs.PlateCarree(central_longitude=0), levels=levels, cmap=cmap, extend="both")
    ax.coastlines()
    
    gl = ax.gridlines(draw_labels=True, linewidth=1, color="gray", alpha=0.5, linestyle="--")
    gl.xformatter = LongitudeFormatter()
    gl.yformatter = LatitudeFormatter()
    gl.top_labels = False
    gl.right_labels = False
    ax.set_title(title)
    return contour

def plot_polar_stereo(ax, data, lon_name, lat_name, levels, cmap, lat_min, lat_max, lon_min, lon_max, title):
    contour = ax.contourf(data[lon_name], data[lat_name], data, transform=ccrs.PlateCarree(central_longitude=180), levels=levels, cmap=cmap, extend="both")
    ax.coastlines()
    gl = ax.gridlines(draw_labels=True, linewidth=1, color="gray", alpha=0.5, linestyle="--")
    gl.xformatter = LongitudeFormatter()
    gl.yformatter = LatitudeFormatter()
    gl.top_labels = False
    gl.right_labels = False
    ax.set_title(title)
    return contour

# Load datasets
try:
    model1_annual_data = xr.open_dataset(model1_annual, decode_times=False)[var].isel(time=0)
    model2_annual_data = xr.open_dataset(model2_annual, decode_times=False)[var].isel(time=0) if model2_annual else None
    obs_annual_data = xr.open_dataset(obs_annual, decode_times=False)[obs_var].isel(valid_time=0)
    bias1_annual_data = xr.open_dataset(bias1_annual, decode_times=False)[var].isel(time=0)
    bias2_annual_data = xr.open_dataset(bias2_annual, decode_times=False)[var].isel(time=0) if bias2_annual else None
    bias3_annual_data = xr.open_dataset(bias3_annual, decode_times=False)[var].isel(time=0) if bias3_annual else None
except Exception as e:
    print(f"Error loading datasets: {e}")
    sys.exit(1)

# Apply transformations
model1_annual_data = apply_variable_transformations(model1_annual_data, var, obs_var)
obs_annual_data = apply_variable_transformations(obs_annual_data, var, obs_var)
if model2_annual_data is not None:
    model2_annual_data = apply_variable_transformations(model2_annual_data, var, obs_var)

# Dynamically identify coordinates
lon_name = "lon" if "lon" in model1_annual_data.coords else "longitude"
lat_name = "lat" if "lat" in model1_annual_data.coords else "latitude"

# Define levels
mean_levels = create_levels(-20, 45)  # Adjust range for temperature data
bias_levels = create_levelsB(-8, 8)  # Adjust for bias range



mean_cmap = 'Spectral_r'  # For model and observation
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
if model2_annual_data is not None:
    # Create a 3x2 grid for plotting when Model 2 data is present
    fig, axes = plt.subplots(3, 2, figsize=(15, 18), subplot_kw={"projection": proj})

    # Plot Observation Annual Mean
    contour1 = plot_function(axes[0, 0], obs_annual_data, lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Observation Annual Mean")
    fig.colorbar(contour1, ax=axes[0, 0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Bias between Model 1 and Model 2
    contour2 = plot_function(axes[0, 1], bias3_annual_data, lon_name, lat_name, bias_levels, bias_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Bias (CMIP7 - CMIP6)")
    fig.colorbar(contour2, ax=axes[0, 1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Model 1 Annual Mean
    contour3 = plot_function(axes[1, 0], model1_annual_data, lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "CMIP7 Annual Mean")
    fig.colorbar(contour3, ax=axes[1, 0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Model 2 Annual Mean
    contour4 = plot_function(axes[2, 0], model2_annual_data, lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "CMIP6 Annual Mean")
    fig.colorbar(contour4, ax=axes[2, 0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Bias between Model 1 and Observation
    contour5 = plot_function(axes[1, 1], bias1_annual_data, lon_name, lat_name, bias_levels, bias_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Bias (CMIP7 - Obs)")
    fig.colorbar(contour5, ax=axes[1, 1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Bias between Model 2 and Observation
    contour6 = plot_function(axes[2,1 ], bias2_annual_data, lon_name, lat_name, bias_levels, bias_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Bias (CMIP6 - Obs)")
    fig.colorbar(contour6, ax=axes[2, 1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Save plot
    output_file = os.path.join(output_dir, f"{var}_annual_comparison_with_model2_{projection}.png")

else:
    # Create a 1x3 grid for plotting when Model 2 data is absent
    fig, axes = plt.subplots(1, 3, figsize=(18, 6), subplot_kw={"projection": proj})

    # Plot Observation Annual Mean
    contour1 = plot_function(axes[0], obs_annual_data, lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Observation Annual Mean")
    fig.colorbar(contour1, ax=axes[0], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Model 1 Annual Mean
    contour2 = plot_function(axes[1], model1_annual_data, lon_name, lat_name, mean_levels, mean_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Model 1 Annual Mean")
    fig.colorbar(contour2, ax=axes[1], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Plot Bias between Model 1 and Observation
    contour3 = plot_function(axes[2], bias1_annual_data, lon_name, lat_name, bias_levels, bias_cmap,
                             lat_min, lat_max, lon_min, lon_max, "Bias (CMIP7 - Obs)")
    fig.colorbar(contour3, ax=axes[2], orientation='horizontal', pad=0.1, fraction=0.05, shrink=0.8)

    # Save plot
    output_file = os.path.join(output_dir, f"{var}_annual_comparison_without_model2_{projection}.png")

# Save the plot
plt.savefig(output_file)
print(f"Plot saved to {output_file}")
plt.close()

