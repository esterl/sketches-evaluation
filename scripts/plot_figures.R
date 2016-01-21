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


