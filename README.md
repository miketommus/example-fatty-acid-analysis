# **Example Fatty Acid Analyses Using R**

There are two fatty acid analyses scripts contained herein. **Both of these scripts are used for demonstration purposes only.**

1. "analysis_original.qmd" is a Quarto markdown script that demonstrates how to post-process GC/MS data of fatty acid methyl esters and begins plotting the data. This script is soon to be deprecated and will be replaced by the script described below.

2. The other, "analysis_using_FATools.R", is an R script that demonstrates how to use the [FATools R package](https://www.github.com/miketommus/FATools) (currently in beta) to post-process GC/MS data of fatty acid methyl esters. The FATools package is currently under development and is subject to change. Thus, you shouldn't use it in any production code yet.

The data in the /data directory comes from a real analysis of fatty acid methyl esters (FAME) with the exception of two dummy fatty acids (FA) added for testing purposes (18:1w9t & 20:1w5).