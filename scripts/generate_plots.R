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

# Sampling
## Total number of packets
figures_path = "../reports/sampling/figures/"
### PMF
filenames <- Sys.glob('../results/sampling_total1.*.csv')
plt1 = plot_sampling_pmf(filenames, 100, 0.1, c(0.01, 0.99))
ggsave(file=paste0(figures_path, "sampling_total1.png"), plt1,  width=12, 
  height=12, units='cm', dpi=72)
### Packets
plt2 = plot_sampling_packets(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_total2.png"), plt2,  width=12, 
  height=12, units='cm', dpi=72)
### Probability
filenames <- Sys.glob('../results/sampling_total2.*.csv')
plt3 = plot_sampling_probability(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_total3.png"), plt3,  width=12, 
  height=12, units='cm', dpi=72)
filenames <- Sys.glob('../results/sampling_total3.*.csv')
plt4 = plot_sampling_probability(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_total4.png"), plt4,  width=12, 
  height=12, units='cm', dpi=72)
plt = arrangeGrob(plt1, plt2, plt3, nrow=1)
ggsave(file=paste0(figures_path, "sampling1.eps"), plt,  width=25, 
  height=12, units='cm')

## Ratio of packets
### PMF
filenames <- Sys.glob('../results/sampling_ratio1.*.csv')
plt1 = plot_sampling_pmf_ratio(filenames, 100, 0.1, c(0.01, 0.99))
ggsave(file=paste0(figures_path, "sampling_ratio1.png"), plt1,  width=12, 
  height=12, units='cm', dpi=72)
plt2 = plot_sampling_pmf_ratio(filenames, 1000, 0.1, c(0.01, 0.99), F)
ggsave(file=paste0(figures_path, "sampling_ratio2.png"), plt2,  width=12, 
  height=12, units='cm', dpi=72)
### Packets
plt3 = plot_sampling_ratio_packets(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_ratio3.png"), plt3,  width=12, 
  height=12, units='cm', dpi=72)
### Sampling probability
filenames <- Sys.glob('../results/sampling_ratio2.*.csv')
plt4 = plot_sampling_ratio_probability(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_ratio4.png"), plt4,  width=12, 
  height=12, units='cm', dpi=72)
filenames <- Sys.glob('../results/sampling_ratio3.*.csv')
plt5 = plot_sampling_ratio_probability(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_ratio5.png"), plt5,  width=12, 
  height=12, units='cm', dpi=72)
filenames <- Sys.glob('../results/sampling_ratio4.*.csv')
plt6 = plot_sampling_ratio_probability(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_ratio6.png"), plt6,  width=12, 
  height=12, units='cm', dpi=72)
filenames <- Sys.glob('../results/sampling_ratio5.*.csv')
plt7 = plot_sampling_ratio_probability(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_ratio7.png"), plt7,  width=12, 
  height=12, units='cm', dpi=72)
### Drop probability
filenames <- Sys.glob('../results/sampling_ratio6.*.csv')
plt8 = plot_sampling_drop_probability(filenames, 0.99)
ggsave(file=paste0(figures_path, "sampling_ratio8.png"), plt8,  width=12, 
  height=12, units='cm', dpi=72)
plt = arrangeGrob(plt1, plt3, plt4, nrow=1)
ggsave(file=paste0(figures_path, "sampling2.eps"), plt,  width=25, 
  height=12, units='cm')
################################################################################

# Sketches

## Estimating total
figures_path = "../reports/estimating-total/figures/"

### Digest size figures
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

### Pseudo-random function figures
filenames <- Sys.glob('../results/basic_random1.*.csv')
plt = plot_xifunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'xi1.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
plt = plot_hashfunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'hash1.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
filenames <- Sys.glob('../results/basic_random2.*.csv')
plt = plot_xifunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'xi2.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
plt = plot_hashfunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'hash2.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
filenames <- Sys.glob('../results/basic_random3.*.csv')
plt = plot_xifunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'xi3.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
plt = plot_hashfunc(filenames, c(0.01, 0.99))
ggsave(file=paste0(figures_path, 'hash3.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
filenames <- Sys.glob('../results/basic_random4.*.csv')
plt = plot_xifunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'xi4.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
plt = plot_hashfunc(filenames, c(0.01, 0.99))
ggsave(file=paste0(figures_path, 'hash4.png'), plt,  width=25, height=12, 
       units='cm', dpi=72)
  
