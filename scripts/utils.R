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

