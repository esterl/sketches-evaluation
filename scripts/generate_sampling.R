####################### Libraries and auxiliary code ###########################
library(plyr)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(reshape2)
library(lazyeval)
library(gridExtra)

source("read_files.R")
source("utils.R")
source("figures_sampling.R")
source("format.R")
figures_path = "../reports/sampling/figures/"
################################################################################

### 1. Estimating total
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
plt = arrangeGrob(plt1 + theme(legend.position="none"), 
                  plt2 + theme(legend.position="none"), 
                  plt3 + theme(legend.position="none"), nrow=1)
legend = g_legend(plt1 + theme(legend.title=element_blank(), 
                                legend.position="bottom"))
plt_all = grid.arrange(plt, mylegend, nrow=2, heights=c(10,1))
ggsave(file=paste0(figures_path, "sampling1.eps"), plt_all,  width=25, 
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
plt = arrangeGrob(plt1 + theme(legend.position="none"), 
                  plt3 + theme(legend.position="none"), 
                  plt4 + theme(legend.position="none"), nrow=1)
legend = g_legend(plt1 + theme(legend.title=element_blank(), 
                                legend.position="bottom"))
plt_all = grid.arrange(plt, mylegend, nrow=2, heights=c(10,1))
ggsave(file=paste0(figures_path, "sampling2.eps"), plt_all,  width=25, 
  height=12, units='cm')

