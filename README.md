# IITM-ESM\_WRAPPER\_ATM

## Description

IITM-ESM\_WRAPPER\_ATM is a wrapper script designed for **IITM-ESM diagnostics**. 
The script automates the processing, regridding, and visualization of climate model output data, specifically for atmospheric diagnostics. 
It supports multiple models and observational datasets, ensuring efficient workflow execution.

## Features

- **Automated Processing:** Handles model and observational data processing.
- **Field Mean Calculation:** Computes spatial averages using `cdo fldmean`.
- **Parallel Execution:** Optimized workflow to minimize processing time.
- **Plot Generation:** Calls NCL or Python scripts for visualization.
- **HTML Report Generation:** Automatically creates an HTML summary of plots.
- **Error Handling & Cleanup:** Ensures robustness by handling missing files and cleaning up temporary files.

## Requirements

- **Linux/macOS** (Recommended)
- **CDO (Climate Data Operators)**
- **NCL (NCAR Command Language)** (for NCL-based plots)
- **Python 3** (for HTML report generation and optional plotting scripts)
- **NetCDF Libraries** (`netCDF4` if using Python for processing)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/pritam-cccr/IITM-ESM-wrapper-ATM.git
   cd IITM-ESM-wrapper-ATM
   ```
2. Ensure dependencies are installed:
   ```bash
   
   # Install required libraries using pip
   pip install numpy xarray matplotlib cartopy netCDF4
   conda install -c conda-forge cartopy

   ```

## Usage

### **Execution Permission**

Before any execution, give execution permission:

```bash
chmod +x *.sh
chmod +x *.py
chmod +x *.ncl
```

### **Basic Execution**

To run the wrapper script:

```bash
./IITM-ESM_WRAPPER_ATM.sh
```

### **Processing Specific Variables**

You can process specific variables such as `tas`, `pr`, `slp`, `ua`, `va`, `ta`, `hght`, `rsdt`, `rlut`, `rsut`. Example:

```bash
./IITM-ESM_WRAPPER_ATM.sh --variable tas
```

### **Provide Information to user_inputs_atm.sh**

#### Variables to process:

```bash
plev_variables="slp"  # Variables requiring pressure-level data
no_plev_variables="tas,pr"  # Variables without pressure-level data
```

#### Output directory:

```bash
plot_dir="path to directory"
plot_var="var1,var2"
```

#### Model 1 settings:

```bash
netcdf_dir_model1="path to directory"
start_year_model1=start_year
end_year_model1=end_year
output_prefix_model1="model1"
```

#### Model 2 settings (optional for comparison):

```bash
netcdf_dir_model2="path to directory"
start_year_model2=1990
end_year_model2=2014
output_prefix_model2="model2"
```

#### Observation data settings:

```bash
obs_data_dir="path to directory"
start_year_obs=1990
end_year_obs=2020
```

#### Seasonal settings:

```bash
season="JJAS"    [** DJF, MAM, JJA, SON, JJAS**]
```

## Output

- **Processed NetCDF files** in `output_data/`
- **Bias plots for selected variables**
- **Time-series plots** stored in `plot_dir`
- **HTML report** generated as `plots_overview.html`

## License

**Copyright (C) 2025 CCCR, IITM. All rights reserved.** This software is intended for research purposes within IITM and affiliated institutions.

## Author

**CCCR, IITM**

## Contact

For questions or collaborations, contact: 📧 [**pritam.mahapatra@tropmet.res.in**](mailto\:pritam.mahapatra@tropmet.res.in)

