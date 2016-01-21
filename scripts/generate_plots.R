####################### Libraries and auxiliary code ###########################
library(plyr)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(reshape2)
library(lazyeval)

source("read_files.R")
source("utils.R")
source("plot_figures.R")
source("format.R")

### Digest size figures
figures_path = "../reports/estimating-total/figures/"
filenames <- Sys.glob('../results/basic_digest1.*.csv')
plt = plot_digest(filenames, c(0.05, 0.95))
ggsave(file=paste0(figures_path, "digest1.png"), plt,  width=25, height=12, 
       units='cm', dpi=72)
filenames <- Sys.glob('../results/basic_digest2.*.csv')
plt = plot_digest(filenames, c(0.05, 0.74))
ggsave(file=paste0(figures_path, 'digest2.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
filenames <- Sys.glob('../results/basic_digest3.*.csv')
plt = plot_bias(filenames)
ggsave(file=paste0(figures_path, 'bias.png'), plt,  width=12, height=12, 
       units='cm', dpi=72)
ggsave(file=paste0(figures_path, 'bias2.png'), plt + facet_grid(~SketchType),  
       width=25, height=12, units='cm')


