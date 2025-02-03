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

import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import sys
import os
import numpy as np
import xarray as xr
import matplotlib.pyplot as plt

# Predefined pressure levels
predefined_pressure_levels = [
    1000, 925, 850, 700, 600, 500, 400, 300, 250, 200, 150, 100, 70, 50, 30,20, 10, 5,1
]

# Load and process data
def load_and_process(file_path, variable, convert_to_celsius=False):
    """
    Load data, remove time, average over lat/lon, and interpolate to predefined levels.
    """
    ds = xr.open_dataset(file_path, decode_times=False)
    if variable not in ds:
        print(f"Error: Variable '{variable}' not found in {file_path}.")
        sys.exit(1)

    data = ds[variable]

    # Remove time dimension
    if "time" in data.dims:
        data = data.isel(time=0).squeeze()
    elif "valid_time" in data.dims:
        data = data.isel(valid_time=0).squeeze()
    # Average over latitude and longitude
    if "lat" in data.dims and "lon" in data.dims:
        data = data.mean(dim=["lat", "lon"])
    elif "latitude" in data.dims and "longitude" in data.dims:
        data = data.mean(dim=["latitude", "longitude"])

    # Convert from Kelvin to Celsius if required
    if convert_to_celsius:
        data = data - 273.15

    # Interpolate to predefined pressure levels with extrapolation
    pressure_dim = next((dim for dim in data.dims if "level" in dim or "pressure_level" in dim), None)
    if not pressure_dim:
        print("Error: Pressure dimension not found.")
        sys.exit(1)

    print(f"Original Pressure Levels in {file_path}:", data[pressure_dim].values)

    data = data.interp({pressure_dim: predefined_pressure_levels}, method="linear", kwargs={"fill_value": "extrapolate"})

    print(f"Interpolated Pressure Levels in {file_path}:", data[pressure_dim].values)
    return data, pressure_dim

# Plotting function
def plot_profiles(profiles, labels, pressure_levels, output_path, xlabel, ylabel, title):
    """
    Plot vertical profiles with consistent pressure levels and specified colors.
    """
    plt.figure(figsize=(10, 8))  # Adjust the figure size for better visibility

    # Define custom colors for the profiles
    custom_colors = ["black", "blue", "red", "orange", "purple"]  # Add more as needed

    for profile, label, color in zip(profiles, labels, custom_colors):
        plt.plot(profile, pressure_levels, label=label, linewidth=2, color=color)  # Set line color and width

    plt.gca().invert_yaxis()  # Invert the y-axis so pressure decreases upwards
    plt.xlabel(xlabel, fontsize=14)
    plt.ylabel(ylabel, fontsize=14)
    plt.title(title, fontsize=16, weight='bold')

    plt.xticks(fontsize=12)  # Adjust font size of tick labels
    custom_ticks = [1000, 850,700, 600,500, 400,300, 200, 100, 50,1]  # Preferred pressure levels
    custom_labels = [f"{int(tick)}" for tick in custom_ticks]  # Convert to string labels

    plt.yticks(custom_ticks, custom_labels, fontsize=12)


    plt.grid(visible=True, linestyle='--', alpha=0.7)  # Add a grid for better visualization
    plt.legend(fontsize=12, loc="best", frameon=True)  # Adjust legend position and style
    plt.tight_layout()  # Ensure no overlap of labels and title
    plt.savefig(output_path, dpi=300)  # Save with high resolution
    plt.close()


# Load datasets and process
model1_profile, _ = load_and_process(sys.argv[1], "ta", convert_to_celsius=True)
model2_profile, _ = load_and_process(sys.argv[2], "ta", convert_to_celsius=True) if len(sys.argv) > 2 and sys.argv[2] else (None, None)
obs_profile, _ = load_and_process(sys.argv[3], "t", convert_to_celsius=True)

bias1_profile, _ = load_and_process(sys.argv[4], "ta", convert_to_celsius=False)
bias2_profile, _ = load_and_process(sys.argv[5], "ta", convert_to_celsius=False) if len(sys.argv) > 5 and sys.argv[5] else (None, None)
bias3_profile, _ = load_and_process(sys.argv[6], "ta", convert_to_celsius=False) if len(sys.argv) > 6 and sys.argv[6] else (None, None)

# Plot mean profiles
# Call the updated plotting function
plot_profiles(
    [obs_profile, model1_profile, model2_profile] if model2_profile is not None else [obs_profile, model1_profile],
    ["Observation (°C)", "CMIP7 (°C)", "CMIP6 (°C)"] if model2_profile is not None else ["Observation (°C)", "Model 1 (°C)"],
    predefined_pressure_levels,
    os.path.join(sys.argv[9], "vertical_profile_mean.pdf"),
    "Temperature (°C)",
    "Pressure (hPa)",
    "Vertical Temperature Profile (Mean)"
)

# Plot bias profiles
plot_profiles(
    [bias1_profile, bias2_profile] if bias3_profile is not None else [bias1_profile, bias2_profile],
    ["Bias (CMIP7 -Obs)", "Bias (CMIP6 - Obs)"] if bias3_profile is not None else ["Bias (Obs - Model 1)", "Bias (Obs - Model 2)"],
    predefined_pressure_levels,
    os.path.join(sys.argv[9], "vertical_profile_bias.png"),
    "Temperature Bias (K)",
    "Pressure (hPa)",
    "Vertical Temperature Bias Profile"
)

print("Plots saved successfully!")
