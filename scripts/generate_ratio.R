####################### Libraries and auxiliary code ###########################
library(plyr)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(reshape2)
library(lazyeval)

source("read_files.R")
source("utils.R")
source("figures_ratio.R")
source("format.R")
figures_path = "../reports/estimating-ratio/figures/"
################################################################################

## Digest size
filenames = Sys.glob("../results/ratio_digest1.*.csv")
plt = plot_digest(filenames, c(0.05, 0.95))
ggsave(file=paste0(figures_path, "digest1.png"), plt,  width=25, 
  height=11.5, units='cm', dpi=150)
filenames = Sys.glob("../results/ratio_digest2.*.csv")
plt = plot_digest(filenames, c(0.05, 0.95))
ggsave(file=paste0(figures_path, "digest2.png"), plt,  width=25, 
  height=11.5, units='cm', dpi=150)

## Pseudo-random functions
filenames = Sys.glob("../results/ratio_random1.*.csv")
plt = plot_xifunc(filenames)
ggsave(file=paste0(figures_path, "xi1.png"), plt,  width=15, 
  height=10, units='cm', dpi=150)
plt = plot_hashfunc(filenames)
ggsave(file=paste0(figures_path, "hash1.png"), plt,  width=15, 
  height=10, units='cm', dpi=150)

## Drop probability
filenames = Sys.glob("../results/ratio_drop1.*.csv")
plt = plot_ratio(filenames, 0.99)
ggsave(file=paste0(figures_path, "drop1.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
ggsave(file=paste0(figures_path, "ratio_drop.eps"), plt,  width=12, 
  height=12, units='cm')
plt = plot_ratio(filenames, 0.95)
ggsave(file=paste0(figures_path, "drop2.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_ratio(filenames, 0.9)
ggsave(file=paste0(figures_path, "drop3.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)

## Packets
filenames = Sys.glob("../results/ratio_packets1.*.csv")
plt = plot_packets(filenames, 0.99)
ggsave(file=paste0(figures_path, "packets1.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
ggsave(file=paste0(figures_path, "ratio_packets.eps"), plt,  width=12, 
  height=12, units='cm')
plt = plot_packets(filenames, 0.95)
ggsave(file=paste0(figures_path, "packets2.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_packets(filenames, 0.9)
ggsave(file=paste0(figures_path, "packets3.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
filenames = Sys.glob("../results/ratio_packets2.*.csv")
plt = plot_packets(filenames, 0.99)
ggsave(file=paste0(figures_path, "packets4.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_packets(filenames, 0.95)
ggsave(file=paste0(figures_path, "packets5.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_packets(filenames, 0.9)
ggsave(file=paste0(figures_path, "packets6.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)

## Columns
filenames = Sys.glob("../results/ratio_columns4.*.csv")
plt = plot_columns(filenames, 0.99)
ggsave(file=paste0(figures_path, "columns1.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
filenames = Sys.glob("../results/ratio_columns5.*.csv")
plt = plot_columns(filenames, 0.99)
ggsave(file=paste0(figures_path, "columns2.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
filenames = Sys.glob("../results/ratio_columns6.*.csv")
plt = plot_columns(filenames, 0.99)
ggsave(file=paste0(figures_path, "columns3.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)

## Rows
# Average function
filenames = Sys.glob("../results/ratio_average1.*.csv")
plt = plot_avgFunc(filenames)
ggsave(file=paste0(figures_path, "average1.png"), plt,  width=25, 
  height=12, units='cm', dpi=150)
filenames = Sys.glob("../results/ratio_rows2.*.csv")
plt = plot_rows(filenames, 0.99)
ggsave(file=paste0(figures_path, "rows1.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
filenames <- Sys.glob('../results/ratio_aspect*.csv')
plt = plot_aspectRatio(filenames, 0.60) + 
        theme(legend.justification=c(1,0), legend.position=c(1,0))
ggsave(file=paste0(figures_path, 'aspect1.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
plt = plot_aspectRatio(filenames, 0.90) + 
        theme(legend.justification=c(1,0), legend.position=c(1,0))
ggsave(file=paste0(figures_path, 'aspect2.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)
plt = plot_aspectRatio(filenames, 0.99)
ggsave(file=paste0(figures_path, 'aspect3.png'), plt,  width=15, height=10, 
       units='cm', dpi=150)

## Time
filenames = c(Sys.glob("../results/ratio_equinix1.*.csv"), 
              Sys.glob("../results/ratio_sagunt1.*.csv"), 
              Sys.glob("../results/ratio_proxy1.*.csv"))
plt = plot_interval(filenames, 0.99)
ggsave(file=paste0(figures_path, "interval1.png"), plt,  width=25, 
  height=12, units='cm', dpi=150)
filenames = c(Sys.glob("../results/ratio_equinix2.*.csv"), 
              Sys.glob("../results/ratio_sagunt2.*.csv"), 
              Sys.glob("../results/ratio_proxy2.*.csv"))
plt = plot_interval(filenames, 0.99)
ggsave(file=paste0(figures_path, "interval2.png"), plt,  width=25, 
  height=12, units='cm', dpi=150)
filenames = c(Sys.glob("../results/ratio_equinix3.*.csv"), 
              Sys.glob("../results/ratio_sagunt3.*.csv"), 
              Sys.glob("../results/ratio_proxy3.*.csv"))
plt = plot_interval(filenames, 0.99)
ggsave(file=paste0(figures_path, "interval3.png"), plt,  width=25, 
  height=12, units='cm', dpi=150)

## Regression
filenames = c(Sys.glob("../results/ratio_regression.5305974.*.csv"))
df = ldply(filenames, read_ratio, T, .progress="text")
