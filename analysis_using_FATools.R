# ______ ___ _____           _
# |  ___/ _ \_   _|         | |
# | |_ / /_\ \| | ___   ___ | |___
# |  _||  _  || |/ _ \ / _ \| / __|
# | |  | | | || | (_) | (_) | \__ \
# \_|  \_| |_/\_/\___/ \___/|_|___/

# built with FATools v0.1.0-alpha
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
library(tidyr)      # data manipulation
library(magrittr)   # pipe operator
library(ggplot2)    # data visualization

#==============================================================================
# SET VARIABLES FOR ANALYSIS
#==============================================================================
# Data files to read in
gcms_data <- "data/example_gcms_results.xlsx"
sample_list <- "data/example_sample_list.xlsx"
compound_table <- "data/example_compound_table.csv"
grav_data <- "data/example_gravimetry.xlsx"

# Concentrations of external standards (ng/uL)
ext_std_concs <- c(15, 50, 100, 250)

# Volume of lipid extract (mL)
extract_vol <- 1.5

# Proportion of lipid extract derivatized (mL)
prop_deriv <- (1 / 1.5)

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================
# Reads in data differently depending on file extension
read_in_file <- function(file_path) {
  if (grepl(".xlsx", file_path)) {
    readxl::read_xlsx(file_path, na = c("NA", "", "N/A", "---"))

  } else if (grepl(".csv", file_path)) {
    read.csv(file_path, na.strings = c("NA", "", "N/A", "---"))

  } else {
    stop("File type not supported.")
  }
}

# ggplot theme that plots x axis labels vertically
x90 <- theme(
  axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
  legend.position = "right"
)

#==============================================================================
# DATA IMPORT
#==============================================================================
# Read in data
data <- read_in_file(gcms_data)
compounds <- read_in_file(compound_table)
samples <- read_in_file(sample_list)
gravimetry <- read_in_file(grav_data)
rm(gcms_data, sample_list, compound_table, grav_data)

#==============================================================================
# DATA WRANGLE
#==============================================================================
# Extract response factor mapping from compound table
rf_map <- data.frame(
  fa = compounds$Name,
  ref_fa = compounds$rf_map
)

rf_map$fa %<>% convert_fa_name(notation = "w")
rf_map$ref_fa %<>% convert_fa_name(notation = "w")

# Extract external standard proportions from compound table
ext_std_contents <- data.frame(
  fa = compounds$Name,
  prop = compounds$ext_std_prop
) %>% filter(
  !is.na(prop)
)

ext_std_contents$fa %<>% convert_fa_name(notation  = "w")

# pull out extracted tissue mass
tiss_mass <- data.frame(
  id = gravimetry$sample_ID,
  mass = gravimetry$tiss_dry_mass
)

# Filter data to just compound data
just_data <- data[FATools::find_fa_name(colnames(data))]

# Standardize fatty acid names in column names
colnames(just_data) %<>% convert_fa_name(notation = "w")

# Remove fatty acids without positive IDs
just_data %<>% select(any_of(rf_map$fa))

#==============================================================================
# POST-PROCESSING
#==============================================================================
# Calculate GC/MS response factors
response_factors <- calc_gc_response_factor(
  data = just_data[1:4,],
  ext_std_concs = ext_std_concs,
  ext_std_contents = ext_std_contents
)

# Convert Areas to Conc (ng/uL)
concentrations <- convert_area_to_conc(
  data = just_data,
  rf_table = response_factors,
  rf_map = rf_map
)

# Bind sample info from data with new data frames
concentrations <- cbind(data[1:4], concentrations)

# Bind tissue mass to concentration data & adjust for extracted tissue mass
concentrations <- left_join(
  concentrations,
  tiss_mass,
  join_by(`Sample ID` == id)
) %>% filter(
  !is.na(mass)
)

tissue_concentrations <- adjust_conc_for_tissue_mass(
  concentrations[find_fa_name(colnames(concentrations))],
  concentrations$mass,
  extract_vol = extract_vol,
  prop_deriv = prop_deriv
)

# Convert Conc to Prop (mass %)
proportions <- convert_result_to_prop(
  data = tissue_concentrations[-grep("19:0", colnames(tissue_concentrations))],
  na.rm = TRUE
)

# Bind sample info from data with new data frames
tissue_concentrations <- cbind(concentrations[1:4], tissue_concentrations)
proportions <- cbind(concentrations[1:4], proportions)

# Clean up environment
rm(
  concentrations, just_data, response_factors, ext_std_contents,
  rf_map, tiss_mass, ext_std_concs, extract_vol, prop_deriv
)

#==============================================================================
# QUALITY ASSURANCE/CONTROL
#==============================================================================
# Add some data quality assurance/control here

#==============================================================================
# DATA VISUALIZATION
#==============================================================================
# Bind treatment & tissue types to data
proportions <- left_join(
  proportions,
  samples %>% select(sample_ID, tissue_type, treatment),
  join_by(`Sample ID` == sample_ID)
)

tissue_concentrations <- left_join(
  tissue_concentrations,
  samples %>% select(sample_ID, tissue_type, treatment),
  join_by(`Sample ID` == sample_ID)
)

# Make data long
long_prop <- proportions %>% pivot_longer(
  cols = find_fa_name(colnames(.)),
  names_to = "fa",
  values_to = "props",
)

long_tiss_conc <- tissue_concentrations %>% pivot_longer(
  cols = find_fa_name(colnames(.)),
  names_to = "fa",
  values_to = "tiss_concs"
) %>% filter(fa != "19:0")

# Make FA names a factor so they plot in order of GC retention time
fa_order <- unique(long_prop$fa)
long_prop$fa %<>% factor(levels = fa_order)
long_tiss_conc$fa %<>% factor(levels = fa_order)

# plot data
long_prop %>% ggplot(aes(fa, props, fill = treatment)) +
  geom_boxplot() +
  facet_wrap(vars(tissue_type), ncol = 1) +
  x90 +
  labs(y = "Proportion (% of Total FA)", x = "FA")

long_tiss_conc %>% ggplot(aes(fa, tiss_concs, fill = treatment)) +
  geom_boxplot() +
  facet_wrap(vars(tissue_type), ncol = 1) +
  x90 +
  labs(y = "Concentration mg FA / g DW", x = "FA")

#==============================================================================
# DATA EXPORT
#==============================================================================
# Export the data
# write.csv(tissue_concentrations, file = "/path/to/your/final/conc_data.csv")
# write.csv(proportions, file = "/path/to/your/final/prop_data.csv")
