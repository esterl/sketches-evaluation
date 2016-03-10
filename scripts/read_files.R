#' Reads a CSV as formatted by the basic_estimation.py file
#'
#' Returns a dataframe with all the information of the CVS file
#' @param filename Name of the CVS file
#' @return A dataframe
read_base <- function(filename){
  tmp <- read.csv(filename, na.strings=c("NA","None"))
  names(tmp)[1] <- "SketchedPackets"
  tmp$filename <- filename
  tmp$pcap = "CAIDA"
  tmp$pcap[grepl("sagunt", tmp$filename)] = "qMp"
  tmp$pcap[grepl("proxy", tmp$filename)] = "Proxy"
  tmp$Error <- tmp$EstimatedPackets - tmp$SketchedPackets
  tmp$Method = "Experimental"
  sizes = sort(unique(tmp$DigestSize))
  tmp$DigestF <- factor(tmp$DigestSize, levels=c("Estimation", sizes))
  tmp$AspectRatio <- tmp$SketchColumns/tmp$SketchRows
  tmp$SketchSize <- tmp$SketchColumns * tmp$SketchRows
  return(tmp)
}

#' Reads all the available CVS files with the PMF of the sketches
#'
#' Returns a dataframe with the PMF of the sketches of the given characteristics
#' @param type Type of the sketch
#' @param packets Number of packets
#' @param columns Sketch columns
#' @param rows Sketch rows
#' @return A dataframe with all the PMFs that fit the requirements
read_pmf <- function(type="*", packets="*", columns="*", rows="*", 
                     averageFunction="*", breaks=NA){
  filenames = Sys.glob(paste0(paste('../results/PMF', type, packets, columns, rows, 
                             averageFunction, sep = '_' ), ".csv"))
  df = ldply(filenames, read.csv)
  df$Error = df$EstimatedPackets - df$SketchedPackets
  df$Method = "Estimation"
  if (all(is.na(breaks))) return(df)
  df = df %>% group_by(SketchType) %>% 
    mutate(Bin = findInterval(Error, breaks[[as.character(SketchType)[1]]]))
  result.df = df %>% group_by(Bin, SketchType, SketchColumns, SketchRows, 
                           SketchedPackets, AverageFunction) %>% 
    summarize(Error=mean(Error), Probability=sum(Probability))
  subset(result.df, select=-Bin)
}

#' Reads a list of CSV files as formatted by the sampling.py script
#'
#' Returns a dataframe with all the information of the CVS files
#' @param filename Names of the CVS files
#' @return A dataframe

read_sampling <- function(filename){
  df <- read.csv(filename)
  df$filename = filename
  df$pcap = "CAIDA"
  df$pcap[grepl("sagunt", df$filename)] = "qMp"
  df$pcap[grepl("proxy", df$filename)] = "Proxy"
  if ("ProcessedPackets" %in% names(df)){
    df$Error = df$EstimatedPackets - df$ProcessedPackets
    df$RelativeError = df$Error/df$ProcessedPackets
    df$Method = "Experimental"
    df$Method = as.factor(df$Method)
    levels(df$Method)[2] = "Binomial distribution"
  } else {
    df$DropReal = (df$InputPackets - df$OutputPackets)/pmax(1, df$InputPackets)
    df$EstimatedProbability = df$EstimatedDifference/pmax(1,df$EstimatedInput)
    df$Error = df$EstimatedProbability - df$DropReal
    df$Method = "Experimental"
    df$Method = as.factor(df$Method)
    if ("TimeInterval" %in% names(df)){
      df$Buffer = pmax(df$InputPackets, df$OutputPackets) * df$SamplingProbability
      df$Overhead = df$Buffer*df$DigestSize/df$TimeInterval
      df$Memory = df$Buffer*df$DigestSize/8
    }
    # TODO name!
    levels(df$Method)[2] = "Theoric"
    df$Method = relevel(df$Method, ref="Theoric")
  }
  return(df)
}

read_ratio <- function(filename){
  df <- read.csv(filename)
  df$DigestSize = ordered(df$DigestSize)
  df$filename <- filename
  df$pcap = "CAIDA"
  df$pcap[grepl("sagunt", df$filename)] = "qMp"
  df$pcap[grepl("proxy", df$filename)] = "Proxy"
  df$DropEstimation = df$EstimatedDifference2 / pmax(df$EstimatedInput2, 1)
  df$DropEstimation2 = df$EstimatedDifference2 / pmax(df$InputPackets, 1)
  df$DroppedPackets = df$InputPackets - df$OutputPackets
  df$DropReal = df$DroppedPackets / pmax(df$InputPackets, 1)
  df$Error = df$DropEstimation - df$DropReal
  df$Error2 = df$DropEstimation2 - df$DropReal
  df$SketchSize = df$SketchRows*df$SketchColumns
  return(df)
}
