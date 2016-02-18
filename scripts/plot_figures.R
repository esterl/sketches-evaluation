################################# Sampling #####################################
#' Creates a plot with the PMF of the error for sampling for the given parameters
#'
#' Creates a plot with the PMF of the error by reading the experimental results
#' from the given filenames and filtering only those with the given number of 
#' packets and sampling probability. The results are compared with a binomial 
#' distribution with the parameters given.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param packets Number of processed packets
#' @param probability Sampling probability
#' @param limits The percentiles of the samples that should be shown in the 
#'               figure. Use them to adapt the X axis.
#' @return A ggplot with the PMF of the error
plot_sampling_pmf <- function(filenames, packets, probability, limits){
    df = read_sampling(filenames)
    df = df[df$ProcessedPackets==packets & df$SamplingProbability==probability,]
    pmf <- dbinom(0:packets, packets, probability)
    df.t <- data.frame(ProcessedPackets = packets, 
                EstimatedPackets = (0:packets)/probability, freq=pmf)
    df.t$Error = df.t$EstimatedPackets -df.t$ProcessedPackets
    df.t$Method='Binomial distribution'
    
    xlim = quantile(df$Error, limits)
    stepVal = 1/probability
    freqpoly = geom_freqpoly(aes(y=..density..*..width..), binwidth=stepVal, 
        origin = range(df$Error)[1] - 1/probability/2)
    plt = ggplot(data=df, aes(x=Error, colour=Method, linetype=Method)) + 
        geom_line(aes(x=Error, y=freq), data=df.t) +
        coord_cartesian(xlim = xlim) +
        freqpoly + 
        ylab('Probability') + xlab('Error') + 
        scale_colour_manual(values=custom.colors(2, reference=T)) +
        scale_linetype_manual(values=custom.linetype(2)) +
        paper_theme +
        theme(legend.justification=c(1,1), legend.position=c(1,1))
    return(plt)
}

#' Creates a plot that shows the relation between the error and packets
#' 
#' Creates a plot with the given percentile of the error and the number of 
#' processed packets. The results are compared with the equivalent results of 
#' a binomial distribution.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param percentile The percentile of the error
#' @return A ggplot with the percentile vs number of packets
plot_sampling_packets <- function(filenames, percentile){
  df = read_sampling(filenames)
  percentiles = get_experimental_percentiles(df, "ProcessedPackets", 
                  "SamplingProbability", percentile=percentile)
  percentiles = get_binomial_percentiles(percentiles, percentile=percentile)
  plt = ggplot(percentiles, aes(x=ProcessedPackets, y=Percentile, 
                                color=Method, linetype=Method)) + 
    geom_line() + #scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Packets') + 
    scale_colour_manual(values=custom.colors(2, reference=T)) +
    scale_linetype_manual(values=custom.linetype(2)) +
    paper_theme +
    theme(legend.justification=c(1,0), legend.position=c(1,0))
  return(plt)
}

#' Creates a plot that shows the relation between the error and sampling probability
#' 
#' Creates a plot with the given percentile of the error and the sampling 
#' probability. The results are compared with the equivalent results of a 
#' binomial distribution.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param percentile The percentile of the error
#' @return A ggplot with the percentile vs sampling probability
plot_sampling_probability <- function(filenames, percentile){
  df = read_sampling(filenames)
  percentiles = get_experimental_percentiles(df, "ProcessedPackets", 
                  "SamplingProbability", percentile=percentile)
  percentiles = get_binomial_percentiles(percentiles, percentile=percentile)
  plt = ggplot(percentiles, aes(x=SamplingProbability, y=Percentile, 
                                color=Method, linetype=Method)) + 
    geom_line() + #scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sampling probability') + 
    scale_colour_manual(values=custom.colors(2, reference=T)) +
    scale_linetype_manual(values=custom.linetype(2)) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

#' Creates a plot with the PMF of the error for sampling for the given parameters
#'
#' Creates a plot with the PMF of the error by reading the experimental results
#' from the given filenames and filtering only those with the given number of 
#' packets and sampling probability. The results are compared with the theoretic
#' probabilities.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param packets Number of processed packets
#' @param probability Sampling probability
#' @param limits The percentiles of the samples that should be shown in the 
#'               figure. Use them to adapt the X axis.
#' @return A ggplot with the PMF of the error
plot_sampling_pmf_ratio <- function(filenames, packets, probability, limits, 
                                    theoric=T){
  df = read_sampling(filenames)
  df = df[df$InputPackets==packets & df$SamplingProbability==probability,]
  xlim = quantile(df$Error, limits)
  hist = df %>% group_by(DropProbability, Method, Error) %>% 
          summarize(Counts = n()) %>% 
          mutate(Probability = Counts/sum(Counts))
  # df$DropProbability Should be unique
  drop_probability = mean(df$DropProbability)
  if(theoric) {
    df.t <- get_subsampling_pmf(packets, probability, drop_probability)
    df.t$Error = df.t$EstimatedProbability - drop_probability
    df.t$Method='Theoric'
    aux = bind_rows(hist, df.t)
    aux$Method = ordered(aux$Method, levels=c("Theoric", "Experimental"))
    plt = ggplot(data=aux, aes(x=Error, y=Probability, colour=Method, 
                                linetype=Method)) + 
        geom_line() + 
        coord_cartesian(xlim = xlim) +
        ylab('Probability') + xlab('Error') + 
        scale_colour_manual(values=custom.colors(2, reference=T)) +
        scale_linetype_manual(values=custom.linetype(2)) +
        paper_theme +
        theme(legend.justification=c(1,1), legend.position=c(1,1))
  } else {
    plt = ggplot(data=hist, aes(x=Error, y=Probability)) + 
        geom_line() + 
        coord_cartesian(xlim = xlim) +
        ylab('Probability') + xlab('Error') + 
        paper_theme
  }
  return(plt)
}

#' Creates a plot that shows the relation between the error and packets
#' 
#' Creates a plot with the given percentile of the error and the number of 
#' input packets.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param percentile The percentile of the error
#' @return A ggplot with the percentile vs number of packets
plot_sampling_ratio_packets <- function(filenames, percentile){
  df = read_sampling(filenames)
  df = df[df$DropProbability==df$DropReal,]
  percentiles = get_experimental_percentiles(df, "InputPackets", 
                  "SamplingProbability", percentile=percentile)
  print(summary(lm(log(percentiles$SE) ~ log(percentiles$InputPackets))))
  plt = ggplot(percentiles, aes(x=InputPackets, y=Percentile)) + 
    geom_line() + #scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Packets') + 
    paper_theme +
    theme(legend.justification=c(1,0), legend.position=c(1,0))
  return(plt)
}

#' Creates a plot that shows the relation between the error and sampling probability
#' 
#' Creates a plot with the given percentile of the error and the sampling 
#' probability.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param percentile The percentile of the error
#' @return A ggplot with the percentile vs sampling probability
plot_sampling_ratio_probability <- function(filenames, percentile){
  df = read_sampling(filenames)
  percentiles = get_experimental_percentiles(df, "InputPackets", 
                  "SamplingProbability", percentile=percentile)
  aux = data.frame(logSE = log(percentiles$SE), 
          logSamplingProbability = log(percentiles$SamplingProbability))
  aux = aux[!is.infinite(aux$logSE),]
  print(summary(lm(logSE~logSamplingProbability, data=aux)))
  plt = ggplot(percentiles, aes(x=SamplingProbability, y=Percentile)) + 
    geom_line() + #scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sampling probability') + 
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

#' Creates a plot that shows the relation between the error and sampling probability
#' 
#' Creates a plot with the given percentile of the error and the sampling 
#' probability.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param percentile The percentile of the error
#' @return A ggplot with the percentile vs sampling probability
plot_sampling_drop_probability <- function(filenames, percentile){
  df = read_sampling(filenames)
  percentiles = get_experimental_percentiles(df, "InputPackets", 
                  "SamplingProbability", "DropProbability",
                  percentile=percentile)
  print(summary(lm(log(percentiles$SE) ~ log(percentiles$DropProbability), 
                    na.action=na.omit)))
  plt = ggplot(percentiles, aes(x=DropProbability, y=Percentile)) + 
    geom_line() + #scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Dropping probability') + 
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}
################################# Sketching ####################################
#' Creates a plot with the PMF of the error based on the digest size
#'
#' Creates a plot with a facet grid per sketch type that shows the PMF of the 
#' error colored by digest size.
#' @param filenames List of the CSV files that will be use to create the figure
#' @param limits The percentiles of the samples that should be shown in the 
#'               figure. Use them to adapt the X axis.
#' @return A ggplot with the PMF of the error
plot_digest <- function(filenames, limits){
  df <- ldply(filenames, read_base)
  xlim = quantile(df$Error, limits)
  breaks = get_breaks(df, xlim)
  df.hist = get_probability(df, breaks, "SketchType", "DigestSize")
  df.hist$method = "Experimental"
  df.t <- read_pmf(packets=df$SketchedPackets[1], columns=df$SketchColumns[1], 
                   rows=df$SketchRows[1], averageFunction=df$AverageFunction[1],
                   breaks=breaks)
  df.t$DigestSize=NA
  df.t$method = "Estimation"
  df.all = bind_rows(df.hist, df.t)
  df.all$bits = ifelse(is.na(df.all$DigestSize), 
                       "", 
                       paste0(" (", df.all$DigestSize, " bits)"))
  bits = sort(unique(df.all$DigestSize))
  levels = c("Estimation", paste0("Experimental ", "(", bits, " bits)"))
  df.all$group = factor(paste0(df.all$method, df.all$bits), levels=levels, ordered=T)
  num = nlevels(df.all$group)
  df.all = df.all[order(df.all$Error),]
  plt = ggplot(data=df.all, aes(x=Error, y=Probability, colour=group, linetype=group)) +
    coord_cartesian(xlim = xlim) +
    geom_path() + facet_grid(~SketchType) + 
    ylab("Probability") + xlab("Error") +
    scale_color_manual(name="", values=custom.colors(num, reference = T)) +
    scale_linetype_manual(name="", values=custom.linetype(num)) +
    paper_theme +
    theme(legend.title=element_blank(), legend.position="bottom")
  return(plt)
}

#' Creates a plot with the bias of the error depending on the packets
#'
#' Creates a plot with a the bias of the estimation error depending on the 
#' number of packets being estimated and the digest size.
#' @param filenames List of the CSV files that will be use to create the figure
#' @return A ggplot with the bias vs packets
plot_bias <- function(filenames){
  df <- ldply(filenames, read_base)
  df$RelativeError = df$Error/df$SketchedPackets
  df.summary = df %>% group_by(SketchedPackets, DigestF, SketchType) %>% 
    summarize(bias=mean(Error))
  df.summary = df.summary[order(df.summary$SketchedPackets),]
  
  # LM line
  tmp = df.summary[df.summary$DigestF==32,]
  lm1 = lm(log10(abs(bias))~log10(SketchedPackets), data=tmp)
  num = nlevels(df$DigestF)
  
  # Annotations
  y1 = mean(df.summary$bias[df.summary$DigestF==8 & df.summary$SketchedPackets==100])
  y2 = mean(df.summary$bias[df.summary$DigestF==8 & df.summary$SketchedPackets==500])
  df1 = data.frame(x=c(100,500), y=c(y1,y2))
  df2 = data.frame(x=c(1000,5000), 
                   logy=predict(lm1, data.frame(SketchedPackets=c(1000,5000))))
  df2$y = 10^df2$logy
  plt = ggplot(data=df.summary, aes(x=SketchedPackets, y=abs(bias), 
                                    colour=DigestF, linetype=DigestF)) +
    stat_summary(geom="line", fun.y="mean") + 
    scale_x_log10() + scale_y_log10() +
    geom_abline(slope=lm1$coefficients[2], intercept=lm1$coefficients[1], 
                color=colors["grey5"], size=0.1) + 
    paper_theme +
    ylab('Error bias') + xlab('Number of packets') +
    scale_colour_manual(name='Digest size', values=custom.colors(num)) +
    scale_linetype_manual(name='Digest size', values=custom.linetype(num))
  plt = plt + 
    geom_step(aes(x=x, y=y), color="black", linetype="solid", data=df1) +
    geom_step(aes(x=x, y=y), color="black", linetype="solid", data=df2) +
    annotate("text", x=600, y=10^mean(log10(df1$y)), label="~2") +
    annotate("text", x=6000, y=10^mean(log10(df2$y)), label="~1")
  return(plt)
}

plot_xifunc <- function(filenames, limits){
  df <- ldply(filenames, read_base)
  # Keep only AGMS and FAGMS
  df = df[df$SketchType!="FastCount",]
  xlim = quantile(df$Error, limits)
  breaks = get_breaks(df,xlim)
  df.hist = get_probability(df, breaks, "SketchType", "Xi")
  df.hist$method = "Experimental"
  df.t <- read_pmf(packets=df$SketchedPackets[1], columns=df$SketchColumns[1], 
                   rows=df$SketchRows[1], averageFunction=df$AverageFunction[1],
                   breaks=breaks)
  df.t = df.t[df.t$SketchType!="FastCount",]
  df.t$Xi = factor(NA, levels=levels(df$Xi))
  df.t$method = "Estimation"
  df.all = bind_rows(df.hist, df.t)
  df.all$implementation = ifelse(is.na(df.all$Xi), 
                                 "", 
                                 paste0(" (", as.character(df.all$Xi), ")"))
  levels = c("Estimation", paste0("Experimental ", "(", levels(df$Xi), ")"))
  df.all$group = factor(paste0(df.all$method, df.all$implementation), levels=levels, ordered=T)
  num = nlevels(df.all$group)
  df.all = df.all[order(df.all$Error),]
  plt = ggplot(data=df.all, aes(x=Error, y=Probability, colour=group, linetype=group)) +
    coord_cartesian(xlim = xlim) +
    geom_path() + facet_grid(~SketchType) + 
    ylab("Probability") + xlab("Error") +
    scale_color_manual(name="", values=custom.colors(num, reference = T)) +
    scale_linetype_manual(name="", values=custom.linetype(num)) +
    paper_theme +
    theme(legend.title=element_blank(), legend.position="bottom")
  return(plt)                      
}

plot_hashfunc <- function(filenames,limits){
  df <- ldply(filenames, read_base)
  # Keep only FAGMS and FastCount
  df = df[df$SketchType!="AGMS",]
  xlim = quantile(df$Error, limits)
  breaks = get_breaks(df, xlim)
  df.hist = get_probability(df, breaks, "SketchType", "HashFunction")
  df.hist$method = "Experimental"
  df.t <- read_pmf(packets=df$SketchedPackets[1], columns=df$SketchColumns[1], 
                   rows=df$SketchRows[1], averageFunction=df$AverageFunction[1],
                   breaks=breaks)
  df.t = df.t[df.t$SketchType!="AGMS",]
  df.t$HashFunction = factor(NA, levels=levels(df$HashFunction))
  df.t$method = "Estimation"
  df.all = bind_rows(df.hist, df.t)
  df.all$implementation = ifelse(is.na(df.all$HashFunction), 
                                 "", 
                                 paste0(" (", as.character(df.all$HashFunction), ")"))
  levels = c("Estimation", paste0("Experimental ", "(", levels(df$HashFunction), ")"))
  df.all$group = factor(paste0(df.all$method, df.all$implementation), levels=levels, ordered=T)
  num = nlevels(df.all$group)
  df.all = df.all[order(df.all$Error),]
  plt = ggplot(data=df.all, aes(x=Error, y=Probability, colour=group, linetype=group)) +
    coord_cartesian(xlim = xlim) +
    geom_path() + facet_grid(~SketchType) + 
    ylab("Probability") + xlab("Error") +
    scale_color_manual(name="", values=custom.colors(num, reference = T)) +
    scale_linetype_manual(name="", values=custom.linetype(num)) +
    paper_theme +
    theme(legend.title=element_blank(), legend.position="bottom")
  return(plt)   
}

plot_packets <- function(filenames, percentile) {
  df <- ldply(filenames, read_base)
  packets = sort(unique(df$SketchedPackets))
  columns = sort(unique(df$SketchColumns))
  rows = sort(unique(df$SketchRows))
  percentiles.exp =   get_experimental_percentiles(df, "SketchedPackets", 
                        "SketchType", percentile=percentile)
  percentiles.chev = get_chebyshev_bounds(packets, columns, rows, percentile)
  df.t <- read_pmf(columns=columns, rows=rows, 
                    averageFunction=df$AverageFunction[1])
  percentiles.t = get_percentiles_pmf(df.t, percentile, "SketchedPackets", 
                      "SketchType")
  if ( any(rows != 1) ) {
    percentiles = bind_rows(percentiles.exp, percentiles.chev, percentiles.t)
  } else {
    percentiles.sg = get_goldberg_bounds(packets, columns, percentile)
    percentiles = bind_rows(percentiles.exp, percentiles.chev, percentiles.sg, 
                        percentiles.t)
  }
  percentiles$Method = as.factor(percentiles$Method)
  plt = ggplot(percentiles, aes(x=SketchedPackets, y=Percentile, 
                                color=Method, linetype=Method)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Number of Sketched packets') + 
    scale_colour_manual(values=custom.colors(nlevels(percentiles$Method))) +
    scale_linetype_manual(values=custom.linetype(nlevels(percentiles$Method))) +
    paper_theme +
    theme(legend.justification=c(1,0), legend.position=c(1,0)) +
    facet_grid(~SketchType)
  return(plt)
}

plot_packets_together <- function(filenames, percentile) {
  df <- ldply(filenames, read_base)
  percentiles =   get_experimental_percentiles(df, "SketchedPackets", 
                        "SketchType", percentile=percentile)
  plt = ggplot(percentiles, aes(x=SketchedPackets, y=Percentile, 
                                color=SketchType, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Number of Sketched packets') + 
    scale_colour_manual(values=custom.colors(nlevels(percentiles$SketchType))) +
    scale_linetype_manual(values=custom.linetype(nlevels(percentiles$SketchType))) +
    paper_theme +
    theme(legend.justification=c(1,0), legend.position=c(1,0))
  return(plt)
}

plot_columns <- function(filenames, percentile) {
  df <- ldply(filenames, read_base)
  packets = sort(unique(df$SketchedPackets))
  columns = sort(unique(df$SketchColumns))
  rows = sort(unique(df$SketchRows))
  percentiles.exp =   get_experimental_percentiles(df, "SketchColumns", 
                        "SketchType", percentile=percentile)
  percentiles.chev = get_chebyshev_bounds(packets, columns, rows, percentile)
  df.t <- read_pmf(packets=packets, rows=rows, 
                    averageFunction=df$AverageFunction[1])
  percentiles.t = get_percentiles_pmf(df.t, percentile, "SketchColumns", 
                      "SketchType")
  if ( any(rows != 1) ) {
    percentiles = bind_rows(percentiles.exp, percentiles.chev, percentiles.t)
    percentiles$Method = ordered(percentiles$Method, 
      levels=c("Estimation", "Experimental", "Chebyshev's bounds"))
  } else {
    percentiles.sg = get_goldberg_bounds(packets, columns, percentile)
    percentiles = bind_rows(percentiles.exp, percentiles.chev, percentiles.sg, 
                        percentiles.t)
    percentiles$Method = ordered(percentiles$Method, 
      levels=c("Estimation", "Experimental", "Chebyshev's bounds", 
                "Goldberg's bounds"))
  }
  percentiles$Method = as.factor(percentiles$Method)
  plt = ggplot(percentiles, aes(x=SketchColumns, y=Percentile, 
                                color=Method, linetype=Method)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sketch Columns') + 
    scale_colour_manual(values=custom.colors(nlevels(percentiles$Method))) +
    scale_linetype_manual(values=custom.linetype(nlevels(percentiles$Method))) +
    paper_theme +
    theme(legend.title=element_blank(), legend.position="bottom") +
    facet_grid(~SketchType)
  return(plt)
}

plot_columns_together <- function(filenames, percentile) {
  df <- ldply(filenames, read_base)
  percentiles =   get_experimental_percentiles(df, "SketchColumns", 
                        "SketchType", percentile=percentile)
  plt = ggplot(percentiles, aes(x=SketchColumns, y=Percentile, 
                                color=SketchType, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sketch Columns') + 
    scale_colour_manual(values=custom.colors(nlevels(percentiles$SketchType))) +
    scale_linetype_manual(values=custom.linetype(nlevels(percentiles$SketchType))) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

