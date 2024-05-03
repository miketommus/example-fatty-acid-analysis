# ______ ___ _____           _
# |  ___/ _ \_   _|         | |
# | |_ / /_\ \| | ___   ___ | |___
# |  _||  _  || |/ _ \ / _ \| / __|
# | |  | | | || | (_) | (_) | \__ \
# \_|  \_| |_/\_/\___/ \___/|_|___/

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
# File path to GCMS data
gcms_data <- "data/example_gcms_results.xlsx"

# Concentrations of external standards (ng/uL)
ext_std_concs <- c(15, 50, 100, 250)

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================
# Reads in data differently depending on file extension
read_in_file <- function(file_path) {
  if (grepl(".xlsx", file_path)) {
    readxl::read_xlsx(file_path)

  } else if (grepl(".csv", file_path)) {
    read.csv(file_path)

  } else {
    stop("File type not supported.")
  }
}

#==============================================================================
# DATA IMPORT
#==============================================================================
# Read in GC/MS peak area data
data <- read_in_file(gcms_data)

# Source response factor mapping for instrument
source("data/example_rf_map.R")
test_rf_map$fa %<>% convert_fa_name()
test_rf_map$ref_fa %<>% convert_fa_name()

# Source proportion information for external standards
source("data/example_ext_std_contents.R")
test_nucheck_566c$fa %<>% convert_fa_name()
test_nucheck_566c$prop %<>% as.numeric()

#==============================================================================
# DATA WRANGLE
#==============================================================================
# Filter data to just compound data
compound_data <- data[FATools::find_fa_name(colnames(data))]

# Standardize fatty acid names in column names
colnames(compound_data) %<>% convert_fa_name()

# Remove fatty acids without positive IDs
# compound_data %<>% select(any_of(test_rf_map$fa))

#==============================================================================
# POST-PROCESSING
#==============================================================================
# Calculate GC/MS response factors
response_factors <- calc_gc_response_factor(
  data = compound_data[1:4,],
  ext_std_concs = ext_std_concs,
  ext_std_contents = test_nucheck_566c
)

# Convert Areas to Conc (ng/uL)
concentrations <- convert_area_to_conc(
  data = compound_data,
  rf_table = response_factors,
  rf_map = test_rf_map
)

# Convert Conc to Prop (mass %)
proportions <- convert_result_to_prop(
  data = concentrations[-grep("19:0", colnames(concentrations))],
  na.rm = TRUE
)

# Bind sample info from data with new data frames
concentrations <- cbind(data[1:4], concentrations)
proportions <- cbind(data[1:4], proportions)

#==============================================================================
# DATA EXPORT
#==============================================================================
# Export the data
# write.csv(concentrations, file = "/path/to/your/final/prop_data.csv")
# write.csv(proportions, file = "/path/to/your/final/conc_data.csv")