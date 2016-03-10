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
    df = ldply(filenames, read_sampling)
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
  df = ldply(filenames, read_sampling)
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
  df = ldply(filenames, read_sampling)
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
  df = ldply(filenames, read_sampling)
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
  df = ldply(filenames, read_sampling)
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
  df = ldply(filenames, read_sampling)
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
  df = ldply(filenames, read_sampling)
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

