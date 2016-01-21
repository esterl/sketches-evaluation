#' Reads a CSV as formatted by the basic_estimation.py file
#'
#' Returns a dataframe with all the information of the CVS file
#' @param filename Name of the CVS file
#' @return A dataframe
read_base <- function(filename){
  tmp <- read.csv(filename, na.strings=c("NA","None"))
  names(tmp)[1] <- "SketchedPackets"
  tmp$filename <- filename
  tmp$Error <- tmp$EstimatedPackets - tmp$SketchedPackets
  sizes = sort(unique(tmp$DigestSize))
  tmp$DigestF <- factor(tmp$DigestSize, levels=c("Estimation", sizes))
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
  if (all(is.na(breaks))) return(df)
  df = df %>% group_by(SketchType) %>% 
    mutate(Bin = findInterval(Error, breaks[[as.character(SketchType)[1]]]))
  result.df = df %>% group_by(Bin, SketchType, SketchColumns, SketchRows, 
                           SketchedPackets, AverageFunction) %>% 
    summarize(Error=mean(Error), Probability=sum(Probability))
  subset(result.df, select=-Bin)
}

