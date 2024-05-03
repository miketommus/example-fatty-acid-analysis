______ ___ _____           _     
|  ___/ _ \_   _|         | |    
| |_ / /_\ \| | ___   ___ | |___ 
|  _||  _  || |/ _ \ / _ \| / __|
| |  | | | || | (_) | (_) | \__ \
\_|  \_| |_/\_/\___/ \___/|_|___/

# built with FATools v0.1 (beta)
#==============================================================================

# TITLE:
#   Example Fatty Acid GC/MS Data Post-Processing

# AUTHOR:
#   miketommus

# DESCRIPTION: This script contains an example analysis that shows how the use
#   the FATools R Package [https://www.github.com/miketommus/FATools] to post-
#   process raw data that results from the chromatographic analysis of fatty
#   acid methyl esters (FAME).

#==============================================================================
# LOAD REQUIRED PACKAGES
#==============================================================================
library(FATools)    # post-processing of GCMS data
library(readxl)     # reading in excel files
library(dplyr)      # data manipulation
library(magrittr)   # pipe operator

#==============================================================================
# SET VARIABLES FOR ANALYSIS
#==============================================================================

# Concentrations of external standards (ng/uL)
ext_std_concs = c(15, 50, 100, 250)

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

#==============================================================================
# DATA IMPORT
#==============================================================================

# Read in GC/MS peak area data
file <-"path/to/your/file.csv"
data <- read.csv(file)

# Filter data to just compound data
compound_data <- data[FATools::find_fa_name(colnames(data))]

# Standardize fatty acid names in column names
colnames(compound_data) %<>% convert_fa_name()

# Remove fatty acids without positive IDs
compound_data %<>% select(any_of(test_rf_map$fa))

# Source response factor mapping for instrument
source("test_rf_map.R")
test_rf_map$fa %<>% convert_fa_name()
test_rf_map$ref_fa %<>% convert_fa_name()

# Source proportion information for external standards
source("test_ext_stds_props.R")
test_nucheck_566c$fa %<>% convert_fa_name()
test_nucheck_566c$prop %<>% as.numeric()

#==============================================================================
# POST-PROCESSING
#==============================================================================

# Calculate GC/MS response factors
response_factors <- calc_gc_response_factor(
  data = compound_data[1:4,],
  ext_std_concs = ext_std_concs,
  ext_std_contents = test_nucheck_566c
)

# *** Above is not setting the col names of the response factor data frame correctly.
colnames(response_factors) <- c("fa", "rf")
response_factors$rf %<>% as.numeric()

# Convert Areas to Conc
concentrations <- convert_area_to_conc(
  data = compound_data,
  rf_table = response_factors,
  rf_map = test_rf_map
)
concentrations <- cbind(data[1:4], concentrations)


# Convert Conc to Prop
proportions <- convert_result_to_prop(
  data = compound_data[-grep("19:0", colnames(compound_data))],
  na.rm = TRUE
)
proportions <- cbind(data[1:4], proportions)