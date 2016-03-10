require(tidyr)

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
  nbins = ceiling(min(c(50, range / stepVal$FAGMS)))
  byVal = lapply(stepVal, function(x){ceiling(range/nbins/x)*x})
  breaks = lapply(names(stepVal), function(type) { 
    if(any(df$SketchType==type)){
      c(min(xlim-stepVal[[type]]/2, min(df$Error[df$SketchType==type]) - 3*stepVal[[type]]/2), 
        seq(from=min(df$Error[df$SketchType==type]) - stepVal[[type]]/2,
          to=max(df$Error[df$SketchType==type]) - stepVal[[type]]/2 + byVal[[type]],
          by=byVal[[type]]),
        max(xlim+stepVal[[type]]/2, max(df$Error[df$SketchType==type]) + stepVal[[type]]/2 + byVal[[type]]))
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


# Theoretic bounds
get_chebyshev_bounds <- function(packets, columns, rows=1, percentile=0.99){
  df.fastcount = data.frame(SketchType="FastCount", SketchedPackets=packets,
                    SketchColumns = columns, SketchRows = rows,
                    SE = sqrt(2 * (packets^2 - packets)/(columns-1)/rows))
  df.agms = data.frame(SketchType="AGMS",  SketchedPackets=packets,
                    SketchColumns = columns, SketchRows = rows,
                    SE = sqrt(2 * (packets^2 - packets)/columns/rows))
  df.fagms = data.frame(SketchType="FAGMS",  SketchedPackets=packets,
                    SketchColumns = columns, SketchRows = rows,
                    SE = sqrt(2 * (packets^2 - packets)/columns/rows))
  df = bind_rows(df.fastcount, df.agms, df.fagms)
  df$Percentile = sqrt(1/(1-percentile))*df$SE
  df$Method = "Chebyshev's bounds"
  return(df)
}

# Percentiles Goldberg
get_goldberg_bounds <- function(packets, columns, percentile){
  df = data.frame(SketchType="FAGMS", SketchedPackets=packets, 
        SketchColumns=columns, SketchRows=1, SE=NA, 
        Percentile=sqrt(24/columns*log(2/(1-percentile)))*packets,
        Method="Goldberg's bounds")
  return(df)
}

# Percentiles from PMF
get_percentiles_pmf <- function(df.t, percentile, ...){
  df = df.t %>% group_by_(...) %>% 
    summarize(
      SE = sqrt(sum(Error^2*Probability) - weighted.mean(Error, Probability)^2),
      Percentile = get_error_percentile(Error, Probability, percentile))
  df$Method = "Estimation"
  return(df)
}

# Like quantile, but giving the probability of each value
get_error_percentile <- function(error, probability, percentile){
    support = abs(error)[order(abs(error))]
    pmf = probability[order(abs(error))]
    cmf = cumsum(pmf)
    idx = cmf > percentile
    return(support[idx][1])
}

test_percentiles <- function(df, variable, percentiles){
  cut_points = list()
  for (type in levels(df$SketchType)){
    # Break consistently based on possible error values:
    tmp = df[df$SketchType==type,]
    error = sort(unique(tmp$Error[tmp$SketchRows==1]))
    ecdf.vals = ecdf(tmp$Error)(error)
    idx.perc = sapply(percentiles, function(x) max(which(ecdf.vals <= x)) )
    bins = c(-Inf, (error[idx.perc] + error[idx.perc+1])/2, Inf)
    cut_points[[type]] = bins
    tmp$Bin = cut(tmp$Error, bins)
    contingency = tmp %>% group_by_("SketchType", variable, "Bin") %>% 
                    summarize(counts = n())
    contingency = spread(contingency, Bin, counts, fill=0)
    print.data.frame(contingency)
    print(chisq.test(contingency[,-c(1,2)]))
  }
  return(cut_points)
}

compute_times <- function(df){
    df$DigestHash = NA
    df$DigestXi = NA
    # AGMS sketch
    index = df$sketchType == "AGMS"
    df$DigestHash[index] = 0
    df$DigestXi[index] = df$SketchUpdate[index]
    # FastCount sketch
    index = df$sketchType == "FastCount"
    df$DigestHash[index] = df$SketchUpdate[index]
    df$DigestXi[index] = 0
    # FAGMS sketch, uses AGMS as base
    index = df$sketchType == "FAGMS"
    index.aux = df$sketchType == "AGMS"
    cross.index = match(df$generator[index] , df$generator[index.aux])
    df$DigestXi[index] = df$SketchUpdate[index.aux][cross.index] / 
                            df$sketchColumns[index.aux][cross.index]
    df$DigestHash[index] = df$SketchUpdate[index] - df$DigestXi[index]
    return(df)
}

print_regression <-function(filenames){
  df <- ldply(filenames, read_base)
  percentiles = get_experimental_percentiles(df, "SketchType", "SketchedPackets", 
                  "SketchColumns", "SketchRows", percentile=0.99)
  # 4.1 Regression of SE
  lm.AGMS = lm(data=percentiles, 
                SE~I(SketchedPackets/sqrt(SketchRows*SketchColumns))-1, 
                #SE~I(sqrt(SketchedPackets^2 - SketchedPackets)/(SketchRows*SketchColumns))-1, 
                subset=percentiles$SketchType=="AGMS")
  print(summary(lm.AGMS))
  lm.FAGMS = lm(data=percentiles, 
                SE~I(SketchedPackets/sqrt(SketchRows*SketchColumns))-1, 
                subset=percentiles$SketchType=="FAGMS")
  print(summary(lm.FAGMS))
  lm.FastCount = lm(data=percentiles, 
                SE~I(SketchedPackets/sqrt(SketchRows*SketchColumns))-1, 
                subset=percentiles$SketchType=="FastCount")
  print(summary(lm.FastCount))
  lm.FastCount = lm(data=percentiles, 
                SE~I(SketchedPackets/sqrt(SketchRows*(SketchColumns-1)))-1, 
                subset=percentiles$SketchType=="FastCount")
  print(summary(lm.FastCount))
}

print_regression_ratio <-function(filenames){
  df <- ldply(filenames, read_ratio)
  percentiles = get_experimental_percentiles(df, "SketchType", "InputPackets", 
                  "SketchColumns", "SketchRows", "DropProbability", 
                  percentile=0.99)
  # 4.1 Regression of SE
  lm.AGMS = lm(data=percentiles, 
    SE~I(DropProbability*
            sqrt((1-DropProbability)/(SketchRows*SketchColumns)))-1, 
    subset=percentiles$SketchType=="AGMS")
  print(summary(lm.AGMS))
  lm.FAGMS = lm(data=percentiles, 
    SE~I(DropProbability*
            sqrt((1-DropProbability)/(SketchRows*SketchColumns)))-1, 
    subset=percentiles$SketchType=="FAGMS")
  print(summary(lm.FAGMS))
  lm.FastCount = lm(data=percentiles, 
    SE~I(DropProbability*
            sqrt((1-DropProbability)/(SketchRows*SketchColumns)))-1, 
    subset=percentiles$SketchType=="FastCount")
  print(summary(lm.FastCount))
  lm.FastCount = lm(data=percentiles, 
    SE~I(DropProbability*
            sqrt((1-DropProbability)/(SketchRows*(SketchColumns-1))))-1, 
    subset=percentiles$SketchType=="FastCount")
  print(summary(lm.FastCount))
}

#extract legend
#https://github.com/hadley/ggplot2/wiki/Share-a-legend-between-two-ggplot2-graphs
g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}
  
