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
    annotate("text", x=650, y=10^mean(log10(df1$y)), label="~2") +
    annotate("text", x=6500, y=10^mean(log10(df2$y)), label="~1")
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
    percentiles$Method = ordered(percentiles$Method,  levels=c("Estimation", 
                                    "Chebyshev's bounds", "Experimental"))
  } else {
    percentiles.sg = get_goldberg_bounds(packets, columns, percentile)
    percentiles = bind_rows(percentiles.exp, percentiles.chev, percentiles.sg, 
                        percentiles.t)
    percentiles$Method = ordered(percentiles$Method,  levels=c("Estimation", 
                                    "Chebyshev's bounds", "Goldberg's bounds", 
                                    "Experimental"))
  }
  num = nlevels(percentiles$Method)
  plt = ggplot(percentiles, aes(x=SketchedPackets, y=Percentile, 
                                color=Method, linetype=Method)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Number of Sketched packets') + 
    scale_colour_manual(values=custom.colors(num, T, ref=T)) +
    scale_linetype_manual(values=custom.linetype(num)) +
    paper_theme +
    theme(legend.title=element_blank(), legend.position="bottom") +
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
  print(summary(df))
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
      levels=c("Estimation", "Chebyshev's bounds", "Experimental"))
  } else {
    percentiles.sg = get_goldberg_bounds(packets, columns, percentile)
    percentiles = bind_rows(percentiles.exp, percentiles.chev, percentiles.sg, 
                        percentiles.t)
    percentiles$Method = ordered(percentiles$Method, 
      levels=c("Estimation", "Chebyshev's bounds", 
                "Goldberg's bounds", "Experimental"))
  }
  num = nlevels(percentiles$Method)
  plt = ggplot(percentiles, aes(x=SketchColumns, y=Percentile, 
                                color=Method, linetype=Method)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sketch Columns') + 
    scale_colour_manual(values=custom.colors(num, T, T)) +
    scale_linetype_manual(values=custom.linetype(num)) +
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

plot_avgFunc <- function(filenames) {
  df <- ldply(filenames, read_base)
  print(summary(df))
  plt = ggplot(data=df, aes(x=Error, colour=AverageFunction, 
                            linetype=AverageFunction)) +
    geom_freqpoly(aes(y=..density..*..width..)) +
    ylab('Probability') + xlab('Error') + 
    scale_colour_manual(values=custom.colors(3)) +
    scale_linetype_manual(values=custom.linetype(3)) +
    paper_theme + 
    theme(legend.title=element_blank(), legend.position="bottom") + 
    facet_grid(~SketchType)
  tmp.stats <- df %>% group_by(AverageFunction, SketchType) %>% 
                  summarise(mean=mean(Error), sd=sd(Error))
  print(tmp.stats)
  return(plt)
}


plot_aspectRatio <- function(filenames, percentile) {
  df <- ldply(filenames, read_base)
  df$AspectRatio = df$SketchColumns / df$SketchRows
  df$SketchSize = df$SketchColumns * df$SketchRows
  percentiles.exp <- get_experimental_percentiles(df, "AspectRatio", 
                          "SketchType", "SketchedPackets", 
                          percentile=percentile)
  percentiles.exp$Label = factor(paste(percentiles.exp$SketchedPackets, 
                                          "packets"), 
                                  levels = c("100 packets", "10000 packets"))
  # Log-log scale
  guide <- guide_legend("Sketch type")
  plt = ggplot(percentiles.exp, aes(x=AspectRatio, y=Percentile/SketchedPackets, 
                                    color=SketchType, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + #scale_y_log10() + 
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Aspect ratio (columns/rows)') + 
    scale_colour_manual(values=custom.colors(3)) + 
    guides(colour=guide, linetype=guide) +
    facet_grid(~Label) + 
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_aspectRatio_pmf <- function(filenames) {
  df <- ldply(filenames, read_base)
  cut_points = test_percentiles(df, "AspectRatio", c(0.05, 0.25, 0.75, 0.95))
  cuts = data.frame(SketchType = rep(c("AGMS", "FAGMS", "FastCount"), 
                        sapply(cut_points, length)),
                    Point = unlist(cut_points))
  df = df[df$SketchColumns %in% c(8,32,128,1024),]
  df$SketchColumns = ordered(df$SketchColumns)
  guide <- guide_legend("Sketch columns")
#  plt = ggplot(df, aes(x=Error, fill=SketchColumns)) +
#    geom_histogram(position="dodge", bins=15) + 
#    facet_grid(~SketchType) +
#    ylab("Count") + xlab("Error") +
#    scale_fill_manual(values=heat.colors(4)) + 
#    guides(fill=guide) + 
#    paper_theme +
#    theme(legend.position="bottom")
  plt = ggplot(data=df, aes(x=Error, color=SketchColumns, linetype=SketchColumns)) + 
    geom_freqpoly(bins=100, aes(y=..density..*..width..)) + 
    facet_grid(~SketchType) +
    ylab("Probability") + xlab("Error") +
    scale_colour_manual(values=custom.colors(4)) + 
    guides(colour=guide, linetype=guide) + 
    paper_theme +
    #geom_vline(aes(xintercept=Point), data=cuts, color="lightgrey") +
    theme(legend.position="bottom")
  return(plt)
}


plot_rows <- function(filenames, percentile) {
  df <- ldply(filenames, read_base)
  print(summary(df))
  packets = sort(unique(df$SketchedPackets))
  columns = sort(unique(df$SketchColumns))
  rows = sort(unique(df$SketchRows))
  percentiles.exp =   get_experimental_percentiles(df, "SketchRows", 
                        "SketchType", percentile=percentile)
  percentiles.chev = get_chebyshev_bounds(packets, columns, rows, percentile)
  df.t <- read_pmf(packets=packets, columns=columns,
                    averageFunction=df$AverageFunction[1])
  percentiles.t = get_percentiles_pmf(df.t, percentile, "SketchRows", 
                      "SketchType")
  percentiles = bind_rows(percentiles.exp, percentiles.chev, percentiles.t)
  percentiles$Method = ordered(percentiles$Method, 
    levels=c("Estimation", "Chebyshev's bounds", "Experimental"))
  num = nlevels(percentiles$Method)
  plt = ggplot(percentiles, aes(x=SketchRows, y=Percentile, 
                                color=Method, linetype=Method)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sketch Rows') + 
    scale_colour_manual(values=custom.colors(num, T, T)) +
    scale_linetype_manual(values=custom.linetype(num)) +
    paper_theme +
    theme(legend.title=element_blank(), legend.position="bottom") +
    facet_grid(~SketchType)
  return(plt)
}

plot_rows_together <- function(filenames, percentile) {
  df <- ldply(filenames, read_base)
  percentiles =   get_experimental_percentiles(df, "SketchRows", 
                        "SketchType", percentile=percentile)
  plt = ggplot(percentiles, aes(x=SketchRows, y=Percentile, 
                                color=SketchType, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sketch Rows') + 
    scale_colour_manual(values=custom.colors(3)) +
    scale_linetype_manual(values=custom.linetype(3)) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_regression_coefficients <-function(filenames){
  df <- ldply(filenames, read_base)
  percentiles = get_experimental_percentiles(df, "SketchType", "SketchedPackets", 
                  "SketchColumns", "SketchRows", percentile=0.99)
  values = (66:99)/100
  coefficients = data.frame(SketchType=factor(levels=levels(df$SketchType)), 
                            Percentile=numeric(),
                            Coefficient=numeric(), 
                            R.squared=numeric())
  for (value in values){
    aux = get_experimental_percentiles(df, "SketchType", "SketchedPackets", 
                  "SketchColumns", "SketchRows", percentile=value)
    for (type in levels(aux$SketchType)){
      if(type=="FastCount"){
        coefficient = lm(data=aux, 
          Percentile~I(SketchedPackets/sqrt(SketchRows*(SketchColumns-1)))-1, 
          subset=percentiles$SketchType==type)$coefficients
      } else {
        regression = lm(data=aux, 
          Percentile~I(SketchedPackets/sqrt(SketchRows*SketchColumns))-1, 
          subset=percentiles$SketchType==type)
      }
      n = nrow(coefficients)+1
      coefficients[n, 1] = type
      coefficients[n, 2] = value
      coefficients[n, 3] = regression$coefficients
      coefficients[n, 4] = summary(regression)$r.squared
    }
  }
  ## Regression as Gaussian:
  for (type in levels(aux$SketchType)) {
    lm.coefs = lm(data=coefficients, Coefficient~I(qnorm(1-(1-Percentile)/2))-1, 
                  subset=coefficients$SketchType==type)
    print(summary(lm.coefs))
  }
  plt = ggplot(coefficients, aes(x=Percentile, y=Coefficient, 
                                color=SketchType, linetype=SketchType)) + 
    geom_line() +
    scale_colour_manual(values=custom.colors(3)) +
    scale_linetype_manual(values=custom.linetype(3)) +
    paper_theme +
    theme(legend.justification=c(0,1), legend.position=c(0,1))
  return(plt)
}
