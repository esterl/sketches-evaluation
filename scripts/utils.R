#' Computes the PMF of estimating a proportion using non fixed-size sample
#'
#' Returns a data.frame with the PMF of estimating the porportion of dropped 
#' packets using sampling.
#' @param packets The total number of packets
#' @param sampling_probability The probability of sampling a packet
#' @param drop_probability The probability of dropping a packet
#' @return A data.frame with the PMF
get_subsampling_pmf <- function(packets, sampling_probability, drop_probability) {
  # Matrix with the probability of seeing j drops given i sampled)
  d_probability = sapply(0:packets, dbinom, 0:packets, drop_probability)
  # Row with the probability of sampling s
  s_probability = dbinom(0:packets, packets, sampling_probability)
  # Transform to matrix
  s_probability = matrix(rep(s_probability, each=packets+1), ncol=packets+1, byrow=T)
  t_probability = d_probability * s_probability
  support = (1/0:packets) %*% t(0:packets)
  support[1,1] = 0
  support[support>1] = 0
  # Get unique support:
  support_char = unique(as.character(support))
  probability = sapply(support_char, function(x) sum(t_probability[as.character(support)==x]))
  # Keep only those that are not 0
  df = data.frame(EstimatedProbability=as.numeric(support_char[probability!=0]), 
                  Probability=probability[probability!=0])
  return(df)
}

#' Computes the experimental bounds of the absolute error
#'
#' Returns a data.frame with the requested percentile, grouping the samples by
#' the given variables. 
#' @param df data.frame with the experiment samples
#' @param ... variables for which to group the results
#' @param percentile The percentile we are looking for
#' @param var The variable for which we are looking the percentile
#' @return A data.frame with the requested percentile and standard error
get_experimental_percentiles <- function(df, ..., percentile=0.99, var="Error"){
  var1 = as.name(var)
  percentiles.exp <- df %>% group_by_(...) %>% 
    summarize_(
      SE = interp(~sd(var), var=var1),
      Percentile = interp(~quantile(abs(var), percentile), var=var1)
    )
  percentiles.exp$Method = 'Experimental'
  return(percentiles.exp)
}

#' Computes the theoric bounds of the absolute error when using a binomial
#'
#' Returns a data.frame with the requested percentile using a binomial variable
#' to estimate those values. The binomial variable is characterized using the
#' values from the data.frame.
#' @param df data.frame with the experiment samples
#' @param percentile The percentile we are looking for
#' @return A data.frame with the requested percentile and standard error
get_binomial_percentiles <- function(df, percentile=0.99){
  packets = sort(unique(df$ProcessedPackets))
  probability = sort(unique(df$SamplingProbability))
  p = (1 - percentile)/2
  q = 1 - p
  error = pmax(abs(qbinom(q, packets, probability)/probability - packets), 
                  abs(qbinom(p, packets, probability)/probability - packets))
  percentiles = data.frame(SamplingProbability = probability, 
                            ProcessedPackets = packets,
                            Percentile = error,
                            Method = "Binomial distribution")
  percentiles = bind_rows(df, percentiles)
  percentiles$Method = factor(percentiles$Method)
  return(percentiles)
}

#' Find the histogram breaks for a dataframe with an Error column
#'
#' Returns a list with the proposed breaks, one for each sketch type, and with 
#' at most 50 bins. The number of breaks will be almos the same for each sketch
#' type, but they will have a size proportional to the distance between 
#' predictions of each sketch.
#' @param df The dataframe
#' @param xlim The range for which we need to adjust the breaks
#' @return A list with the given breaks
get_breaks <- function(df, xlim){
  columns = mean(df$SketchColumns)
  range = diff(xlim)
  # Difference between two errors depending on the sketch type
  stepVal = list()
  stepVal["AGMS"] = 4/columns
  stepVal["FAGMS"] = 2
  stepVal["FastCount"] = 2 * columns / (columns-1)
  nbins = ceiling(min(c(50, range / stepVal$FastCount)))
  byVal = lapply(stepVal, function(x){ceiling(range/nbins/x)*x})
  breaks = lapply(names(stepVal), function(type) { 
    if(any(df$SketchType==type)){
      seq(from=min(df$Error[df$SketchType==type]) - stepVal[[type]]/2,
          to=max(df$Error[df$SketchType==type]) - stepVal[[type]]/2 + byVal[[type]],
          by=byVal[[type]])
    } else { numeric(0)}
    })
  names(breaks) = names(byVal)
  return(breaks)
}

#' Computes the histogram of a dataframe for the given breaks
#'
#' For a given dataframe and a list of error breaks for each sketch type, this 
#' function computes to which break belongs each row and later aggregates the 
#' information to estimate probability of error for each bin.
#' @param df The dataframe
#' @param breaks The break points of each bin
#' @return A dataframe that represents the histogram of the error
get_probability <- function(df, breaks, ...){
  df = df %>% group_by(SketchType) %>% 
    mutate(Bin=findInterval(Error, breaks[[as.character(SketchType)[1]]]))
  df = df %>% group_by(SketchType, Bin) %>%
    mutate(MidPoint = mean(breaks[[SketchType[1]]][Bin[1]:(Bin[1]+1)]))
  result = df %>% group_by_("Bin", ...) %>% 
    summarize(Counts = n(), Error=mean(MidPoint))
  result = result %>% group_by_(...) %>% mutate(Total = sum(Counts))
  result$Probability = result$Counts/result$Total
  subset(result, select=-Bin)
}

