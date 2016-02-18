####################### Libraries and auxiliary code ###########################
library(plyr)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(reshape2)
library(lazyeval)

source("read_files.R")
source("utils.R")
source("figures_total.R")
source("format.R")
figures_path = "../reports/estimating-total/figures/"
################################################################################

## Digest size
filenames = Sys.glob("../results/total_digest1.*.csv")
plt = plot_digest(filenames, c(0.05, 0.95))
ggsave(file=paste0(figures_path, "digest1.png"), plt,  width=25, 
  height=11.5, units='cm', dpi=150)
ggsave(file=paste0(figures_path, "total_digest.eps"), plt,  width=25, 
  height=11.5, units='cm')
filenames = Sys.glob("../results/total_digest2.*.csv")
plt = plot_digest(filenames, c(0.05, 0.74))
ggsave(file=paste0(figures_path, "digest2.png"), plt,  width=25, 
  height=11.5, units='cm', dpi=150)
filenames <- Sys.glob('../results/total_digest3.*.csv')
plt = plot_bias(filenames)
ggsave(file=paste0(figures_path, 'bias.png'), plt,  width=12, height=12, 
       units='cm', dpi=100)
ggsave(file=paste0(figures_path, 'total_bias.eps'), plt,  width=12, height=12, 
       units='cm')
ggsave(file=paste0(figures_path, 'bias2.png'), plt + facet_grid(~SketchType),  
       width=25, height=12, units='cm', dpi=150)
################################################################################

## Pseudo-random functions
filenames <- Sys.glob('../results/total_xi1.*.csv')
plt = plot_xifunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'xi1.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
filenames <- Sys.glob('../results/total_hash1.*.csv')
plt = plot_hashfunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'hash1.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
filenames <- Sys.glob('../results/total_xi2.*.csv')
plt = plot_xifunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'xi2.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
filenames <- Sys.glob('../results/total_hash2.*.csv')
plt = plot_hashfunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'hash2.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
filenames <- Sys.glob('../results/total_xi3.*.csv')
plt = plot_xifunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'xi3.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
ggsave(file=paste0(figures_path, 'total_xi.eps'), plt,  width=15, height=10, 
       units='cm')
filenames <- Sys.glob('../results/total_hash3.*.csv')
plt = plot_hashfunc(filenames, c(0.001, 0.999))
ggsave(file=paste0(figures_path, 'hash3.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
ggsave(file=paste0(figures_path, 'total_hash.eps'), plt,  width=15, height=10, 
       units='cm', dpi=150)
################################################################################

## Packets
filenames <- Sys.glob('../results/total_packets1.*.csv')
plt = plot_packets(filenames, 0.99)
ggsave(file=paste0(figures_path, 'packets1.png'), plt,  width=25, height=10, 
       units='cm', dpi=150)
ggsave(file=paste0(figures_path, 'total_packets.eps'), plt,  width=25, 
        height=10, units='cm')
plt = plot_packets(filenames, 0.95)
ggsave(file=paste0(figures_path, 'packets2.png'), plt,  width=25, height=10, 
       units='cm', dpi=150)
plt = plot_packets(filenames, 0.90)
ggsave(file=paste0(figures_path, 'packets3.png'), plt,  width=25, height=10, 
       units='cm', dpi=150)
plt = plot_packets_together(filenames, 0.99)
ggsave(file=paste0(figures_path, 'packets-all1.png'), plt,  width=12, height=12, 
       units='cm', dpi=100)
filenames <- Sys.glob('../results/total_packets2.*.csv')
plt = plot_packets(filenames, 0.99)
ggsave(file=paste0(figures_path, 'packets4.png'), plt,  width=25, height=10, 
       units='cm', dpi=150)
plt = plot_packets(filenames, 0.95)
ggsave(file=paste0(figures_path, 'packets5.png'), plt,  width=25, height=10, 
       units='cm', dpi=150)
plt = plot_packets(filenames, 0.90)
ggsave(file=paste0(figures_path, 'packets6.png'), plt,  width=25, height=10, 
       units='cm', dpi=150)
plt = plot_packets_together(filenames, 0.99)
ggsave(file=paste0(figures_path, 'packets-all2.png'), plt,  width=12, height=12, 
       units='cm', dpi=100)
################################################################################

## Columns
filenames <- Sys.glob('../results/total_columns1.*.csv')
plt = plot_columns(filenames, 0.99)
ggsave(file=paste0(figures_path, 'columns1.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
ggsave(file=paste0(figures_path, 'total_columns.eps'), plt,  width=25, 
        height=11.5, units='cm')
plt = plot_columns(filenames, 0.95)
ggsave(file=paste0(figures_path, 'columns2.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
plt = plot_columns(filenames, 0.90)
ggsave(file=paste0(figures_path, 'columns3.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
plt = plot_columns_together(filenames, 0.99)
ggsave(file=paste0(figures_path, 'columns-all1.png'), plt,  width=12, height=12, 
       units='cm', dpi=100)
filenames <- Sys.glob('../results/total_columns2.*.csv')
plt = plot_columns(filenames, 0.99)
ggsave(file=paste0(figures_path, 'columns4.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
plt = plot_columns(filenames, 0.95)
ggsave(file=paste0(figures_path, 'columns5.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
plt = plot_columns(filenames, 0.90)
ggsave(file=paste0(figures_path, 'columns6.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
plt = plot_columns_together(filenames, 0.99)
ggsave(file=paste0(figures_path, 'columns-all2.png'), plt,  width=12, height=12, 
       units='cm', dpi=100)
filenames <- Sys.glob('../results/total_columns3.*.csv')
plt = plot_columns(filenames, 0.99)
ggsave(file=paste0(figures_path, 'columns7.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
filenames <- Sys.glob('../results/total_columns4.*.csv')
plt = plot_columns(filenames, 0.99)
ggsave(file=paste0(figures_path, 'columns8.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
################################################################################

## Rows
# 1. Average function
filenames <- Sys.glob('../results/total_average1.*.csv')
plt = plot_avgFunc(filenames)
ggsave(file=paste0(figures_path, 'average1.png'), plt,  width=25, height=11.5, 
       units='cm', dpi=150)
filenames <- Sys.glob('../results/total_average3.*.csv')
plt = plot_avgFunc(filenames)
ggsave(file=paste0(figures_path, 'average2.png'), plt,  width=25, height=11.5, 
       units='cm', dpi=150)
ggsave(file=paste0(figures_path, 'total_average.eps'), plt, width=25, height=11.5, 
       units='cm')
# 2. Rows
filenames <- Sys.glob('../results/total_rows2.*.csv')
plt = plot_rows(filenames, 0.99)
ggsave(file=paste0(figures_path, 'rows1.png'), plt,  width=25, height=11.5, 
       units='cm', dpi=150)
ggsave(file=paste0(figures_path, 'total_rows.eps'), plt, width=25, height=11.5, 
       units='cm')
plt = plot_rows_together(filenames, 0.99)
ggsave(file=paste0(figures_path, 'rows-all1.png'), plt,  width=12, height=12, 
       units='cm', dpi=100)
# 3. Aspect ratio
filenames <- Sys.glob('../results/total_aspect*.csv')
plt = plot_aspectRatio(filenames, 0.66)
ggsave(file=paste0(figures_path, 'aspect1.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
plt = plot_aspectRatio(filenames, 0.90)
ggsave(file=paste0(figures_path, 'aspect2.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
plt = plot_aspectRatio(filenames, 0.99)
ggsave(file=paste0(figures_path, 'aspect3.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
ggsave(file=paste0(figures_path, 'total_aspect.eps'), plt,  width=15, height=10, 
       units='cm')
filenames <- Sys.glob('../results/total_aspect1.*.csv')
plt = plot_aspectRatio_pmf(filenames)
ggsave(file=paste0(figures_path, 'aspect4.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
filenames <- Sys.glob('../results/total_aspect2.*.csv')
plt = plot_aspectRatio_pmf(filenames)
ggsave(file=paste0(figures_path, 'aspect5.png'), plt,  width=25, height=12, 
       units='cm', dpi=150)
# 4. Regression
filenames <- Sys.glob('../results/total_regression*.csv')
print_regression(filenames)
plt = plot_regression_coefficients(filenames)
ggsave(file=paste0(figures_path, 'coefficients.png'), plt,  width=12, height=12, 
       units='cm', dpi=100)

