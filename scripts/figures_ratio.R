plot_digest <- function(filenames, limits){
  df <- ldply(filenames, read_ratio)
  xlim = quantile(df$Error, limits)
  drop = mean(df$DropProbability)
  plt = ggplot(data=df, aes(x=Error, color=DigestSize, linetype=DigestSize)) +
    geom_freqpoly(aes(y=..density..*..width..), binwidth=drop*0.01) +
    facet_grid(~SketchType) + 
    ylab("Probability") + xlab("Error") +
    scale_color_manual(values=custom.colors(nlevels(df$DigestSize))) +
    scale_linetype_manual(values=custom.linetype(nlevels(df$DigestSize))) +
    coord_cartesian(xlim = xlim) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_xifunc <- function(filenames){
  df <- ldply(filenames, read_ratio)
  # Keep only AGMS and FAGMS
  df = df[df$SketchType!="FastCount",]
  legend = expression(paste( xi, " function"))
  num = nlevels(df$XiFunction)
  plt = ggplot(data=df, aes(x=Error, color=XiFunction, linetype=XiFunction)) +
    geom_freqpoly(aes(y=..density..*..width..)) +
    facet_grid(~SketchType) + 
    ylab("Probability") + xlab("Error") +
    scale_color_manual(name=legend, values=custom.colors(num)) +
    scale_linetype_manual(name=legend, values=custom.linetype(num)) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)                      
}

plot_hashfunc <- function(filenames){
  df <- ldply(filenames, read_ratio)
  # Keep only FAGMS and FastCount
  df = df[df$SketchType!="AGMS",]
  legend = "Hash function"
  num = nlevels(df$HashFunction)
  plt = ggplot(data=df, aes(x=Error, color=HashFunction, linetype=HashFunction)) +
    geom_freqpoly(aes(y=..density..*..width..)) +
    facet_grid(~SketchType) + 
    ylab("Probability") + xlab("Error") +
    scale_color_manual(name=legend, values=custom.colors(num)) +
    scale_linetype_manual(name=legend, values=custom.linetype(num)) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)                      
}

plot_packets <- function(filenames, percentile) {
  df <- ldply(filenames, read_ratio)
  percentiles.ratio = get_experimental_percentiles(df, "InputPackets", 
                          "SketchType", percentile=percentile)
  percentiles.ratio$Method = "Proportion"
  percentiles.drop = get_experimental_percentiles(df, var="Error2",
                          "InputPackets", "SketchType", percentile=percentile)
  percentiles.drop$Method = "Dropped"
  percentiles = bind_rows(percentiles.ratio , percentiles.drop)
  plt = ggplot(percentiles, aes(x=InputPackets, y=Percentile, 
                                color=Method, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + #scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Number of incoming packets') + 
    scale_colour_manual(values=custom.colors(2)) +
    scale_linetype_manual(name = "Sketch type", values=custom.linetype(3)) +
    paper_theme +
    theme(legend.justification=c(1,0), legend.position=c(1,0), 
          legend.direction="horizontal", legend.box.just="right")
  return(plt)
}

plot_ratio <- function(filenames, percentile) {
  df <- ldply(filenames, read_ratio)
  percentiles.ratio = get_experimental_percentiles(df, "DropProbability", 
                          "SketchType", percentile=percentile)
  percentiles.ratio$Method = "Proportion"
  percentiles.drop = get_experimental_percentiles(df, var="Error2",
                          "DropProbability", "SketchType", 
                          percentile=percentile)
  percentiles.drop$Method = "Dropped"
  percentiles = bind_rows(percentiles.ratio , percentiles.drop)
  plt = ggplot(percentiles, aes(x=DropProbability, y=Percentile, 
                                linetype=SketchType, color=Method)) + 
    geom_line() + 
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Number of incoming packets') + 
    scale_linetype_manual(values=custom.linetype(nlevels(percentiles$SketchType))) +
    scale_colour_manual(values=custom.colors(nlevels(percentiles$SketchType))) +
    paper_theme +
    theme(legend.justification=c(0,1), legend.position=c(0,1), 
          legend.direction="horizontal", legend.box.just="left")
  return(plt)
}

plot_columns <- function(filenames, percentile) {
  df <- ldply(filenames, read_ratio)
  percentiles = get_experimental_percentiles(df, "SketchColumns", 
                          "SketchType", percentile=percentile)
  # Tendency:
  tmp = data.frame(logColumns=log(percentiles$SketchColumns), 
                    logSE=log(percentiles$SE),
                    SketchType=percentiles$SketchType)
  print(summary(lm(logSE~logColumns+SketchType, data=tmp)))
  # Plot
  plt = ggplot(percentiles, aes(x=SketchColumns, y=Percentile, 
                                color=SketchType, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sketch columns') + 
    scale_colour_manual(name="Sketch type", values=custom.colors(3)) +
    scale_linetype_manual(name = "Sketch type", values=custom.linetype(3)) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_avgFunc <- function(filenames) {
  df <- ldply(filenames, read_ratio)
  print(summary(df))
  plt = ggplot(data=df, aes(x=Error, colour=AverageFunction, 
                            linetype=AverageFunction)) +
    geom_freqpoly(aes(y=..density..*..width..)) +
    ylab('Probability') + xlab('Error') + 
    scale_colour_manual(name='Average function', values=custom.colors(3)) +
    scale_linetype_manual(name='Average function', values=custom.linetype(3)) +
    paper_theme + 
    theme(legend.justification=c(1,1), legend.position=c(1,1)) + 
    facet_grid(~SketchType)
  tmp.stats <- df %>% group_by(AverageFunction, SketchType) %>% 
                  summarise(mean=mean(Error), sd=sd(Error))
  print(tmp.stats)
  return(plt)
}


plot_aspectRatio <- function(filenames) {
  df <- ldply(filenames, read_ratio)
  df$AspectRatio = df$SketchColumns / df$SketchRows
  df$SketchSize = df$SketchColumns * df$SketchRows
  percentiles <- get_experimental_percentiles(df, "AspectRatio", 
                          "SketchType", "InputPackets")
  percentiles$Label = factor(paste(percentiles$InputPackets, 
                                          "packets"), 
                                  levels = c("100 packets", "10000 packets"))
  # Log-log scale
  guide <- guide_legend("Sketch type")
  plt = ggplot(percentiles, aes(x=AspectRatio, y=Percentile, 
                                    color=SketchType, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + #scale_y_log10() + 
    ylab('99% percentile') + 
    xlab('Aspect ratio (columns/rows)') + 
    scale_colour_manual(values=custom.colors(3)) + 
    guides(colour=guide, linetype=guide) +
    facet_grid(~Label) + 
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_rows <- function(filenames, percentile) {
  df <- ldply(filenames, read_ratio)
  percentiles = get_experimental_percentiles(df, "SketchRows", 
                          "SketchType", percentile=percentile)
  # Tendency:
  tmp = data.frame(logRows=log(percentiles$SketchRows), 
                    logSE=log(percentiles$SE),
                    SketchType=percentiles$SketchType)
  print(summary(lm(logSE~logRows+SketchType, data=tmp)))
  # Plot
  plt = ggplot(percentiles, aes(x=SketchRows, y=Percentile, 
                                color=SketchType, linetype=SketchType)) + 
    geom_line() + scale_x_log10() + scale_y_log10() +
    ylab(paste0("Error's ", percentile*100, "% percentile")) + 
    xlab('Sketch rows') + 
    scale_colour_manual(name="Sketch type", values=custom.colors(3)) +
    scale_linetype_manual(name = "Sketch type", values=custom.linetype(3)) +
    paper_theme +
    theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_interval <- function(filenames, percentile) {
  df = ldply(filenames, read_ratio)
  df$pcap = NA
  df$pcap[grepl("sagunt", df$filename)] = "qMp"
  df$pcap[grepl("equinix", df$filename)] = "CAIDA"
  df$pcap[grepl("proxy", df$filename)] = "Proxy"
  
  percentiles = get_experimental_percentiles(df, "pcap", "SketchType", 
                                        "TimeInterval", percentile=percentile)
  packets <- df %>% group_by(TimeInterval, pcap) %>% 
                summarize( numPackets = mean(InputPackets),
                            Percentile = quantile(abs(Error), percentile),
                            bits = mean(OptimizedBits), 
                            SamplingProbability = min(1,bits/32/numPackets))
  packets$numPackets = round_any(packets$numPackets, 10^(floor(log10(packets$numPackets)-1)))
    # Log-log scale
  plt = ggplot(percentiles, aes(x=TimeInterval, y=Percentile)) + 
      geom_line(aes(color=SketchType, linetype=SketchType)) + 
      scale_x_log10() + #scale_y_log10() +
      ylab('Error 99 percentile') + xlab('Time interval (s)') + 
      scale_colour_manual(name='Sketch type', values=custom.colors(3)) +
      scale_linetype_manual(name='Sketch type', values=custom.linetype(3)) +
      paper_theme +
      theme(legend.box.just="left") +
      theme(legend.justification=c(1,1), legend.position=c(1,1)) +
      facet_grid(~pcap, scales='free_x') + 
      geom_text(aes(y = Percentile + 0.001, label=numPackets), data=packets)
    return(plt)
}

