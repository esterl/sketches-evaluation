####################### Libraries and auxiliary code ###########################
library(plyr)
library(ggplot2)
library(ggthemes)
library(dplyr)
library(reshape2)
library(lazyeval)

source("read_files.R")
source("utils.R")
source("figures_cost.R")
source("format.R")
figures_path = "../reports/cost/figures/"
################################################################################

### Memory and overhead
filenames.sk = Sys.glob("../results/ratio_memory-equinix1.*.csv")
filenames.sampling = Sys.glob("../results/sampling_memory_equinix1.*.csv")
plt = plot_memory(filenames.sk, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "memory1.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
ggsave(file=paste0(figures_path, "cost_memory.svg"), plt,  width=12, 
  height=12, units='cm')
plt = plot_memory(filenames.sk, filenames.sampling, 0.90)
ggsave(file=paste0(figures_path, "memory2.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_overhead(filenames.sk, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "overhead1.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
ggsave(file=paste0(figures_path, "cost_overhead.svg"), plt,  width=12, 
  height=12, units='cm')
plt = plot_overhead(filenames.sk, filenames.sampling, 0.90)
ggsave(file=paste0(figures_path, "overhead2.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
filenames.sk = Sys.glob("../results/ratio_memory-sagunt1.*.csv")
filenames.sampling = Sys.glob("../results/sampling_memory_sagunt1.*.csv")
plt = plot_memory(filenames.sk, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "memory3.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_memory(filenames.sk, filenames.sampling, 0.90)
ggsave(file=paste0(figures_path, "memory4.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_overhead(filenames.sk, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "overhead3.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_overhead(filenames.sk, filenames.sampling, 0.90)
ggsave(file=paste0(figures_path, "overhead4.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
filenames.sk = Sys.glob("../results/ratio_memory-sagunt1.*.csv")
filenames.sampling = Sys.glob("../results/sampling_memory_sagunt1.*.csv")
plt = plot_memory(filenames.sk, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "memory5.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_memory(filenames.sk, filenames.sampling, 0.90)
ggsave(file=paste0(figures_path, "memory6.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_overhead(filenames.sk, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "overhead5.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
plt = plot_overhead(filenames.sk, filenames.sampling, 0.90)
ggsave(file=paste0(figures_path, "overhead6.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)


### Overhead with time
filenames = c(Sys.glob("../results/ratio_equinix2.*.csv"), 
              Sys.glob("../results/ratio_sagunt2.*.csv"), 
              Sys.glob("../results/ratio_proxy2.*.csv"))
filenames.sampling = c(Sys.glob("../results/sampling_adapted_equinix.*.csv"), 
                        Sys.glob("../results/sampling_adapted_sagunt.*.csv"), 
                        Sys.glob("../results/sampling_adapted_proxy.*.csv"))
plt = plot_adapted_overhead(filenames, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "overhead_time.png"), plt,  width=25, 
  height=12, units='cm', dpi=150)
plt = plot_interval(filenames, filenames.sampling, 0.99)
ggsave(file=paste0(figures_path, "ratio_time.eps"), plt,  width=25, 
  height=12, units='cm')

### CPU
filename = Sys.glob("../results/test_timing.csv")
plt = plot_CPU1(filename)
ggsave(file=paste0(figures_path, "CPU1.png"), plt,  width=15, 
  height=15, units='cm', dpi=100)
ggsave(file=paste0(figures_path, "cpu_parts.eps"), plt,  width=15, 
  height=15, units='cm')
filename = Sys.glob("../results/test_timing2.csv")
plt = plot_CPU2(filename)
ggsave(file=paste0(figures_path, "CPU2.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
ggsave(file=paste0(figures_path, "cpu_size.eps"), plt,  width=12, 
  height=12, units='cm')
filename.xi = Sys.glob("../results/test_time_xi.csv")
filename.hash = Sys.glob("../results/test_time_hash.csv")
plt = plot_CPU3(filename.hash, filename.xi)
ggsave(file=paste0(figures_path, "CPU3.png"), plt,  width=12, 
  height=12, units='cm', dpi=100)
ggsave(file=paste0(figures_path, "cpu_pseudorandom.eps"), plt,  width=12, 
  height=12, units='cm')
