plot_memory <- function(filenames.sk, filenames.sampling, percentile) {
  df <- ldply(filenames.sk, read_ratio)
  df = df[df$DigestSize==32,]
  percentiles.drop = get_experimental_percentiles(df, "Bytes", "SketchType", 
                      percentile=percentile)
  percentiles.drop$Method = "Dropped"
  percentiles.prop = get_experimental_percentiles(df, "Bytes", "SketchType", 
                      percentile=percentile, var="Error2")
  percentiles.prop$Method = "Proportion"
  df.sampling <- ldply(filenames.sampling, read_sampling)
  df.sampling = df.sampling %>% group_by(SamplingProbability) %>%
                      mutate(Bytes=mean(Memory))
  df.sampling$Size = df.sampling$SamplingProbability
  percentiles.samp <- get_experimental_percentiles(df.sampling, "Bytes",
                        percentile=percentile)
  percentiles.samp$Method = "Sampling"
  percentiles.samp$SketchType = "Sampling"
  percentiles = bind_rows(percentiles.drop, percentiles.prop, percentiles.samp)
  plt = ggplot(percentiles, aes(x=Bytes/1024, y=Percentile)) + 
      geom_line(aes(linetype=SketchType, color=Method)) + 
      geom_point(aes(color=Method)) +
      scale_x_log10() + #scale_y_log10() +
      coord_cartesian(xlim=range(percentiles.drop$Bytes/1024), ylim=c(0, 0.15)) +
      ylab(paste0("Error's ", percentile*100, "% percentile")) + 
      xlab('Memory consumption (KB)') + 
      scale_colour_manual(values=custom.colors(3)) +
      scale_linetype_discrete(name='Sketch type', breaks=levels(df$SketchType)) +
      paper_theme +
      theme(legend.box.just="left") +
      theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_overhead <- function(filenames.sk, filenames.sampling, percentile) {
  df <- ldply(filenames.sk, read_ratio)
  df = df[df$DigestSize==32,]
  df = df %>% group_by(SketchSize, SketchType) %>% 
        mutate(Overhead = mean(OptimizedBits / TimeInterval))
  df.sampling = ldply(filenames.sampling, read_sampling)
  df.sampling = df.sampling %>% group_by(SamplingProbability) %>%
                        mutate(Bytes=mean(Memory), Overhead=mean(Overhead))
  percentiles.drop = get_experimental_percentiles(df, "Overhead", "SketchType", 
                      percentile=percentile)
  percentiles.drop$Method = "Dropped"
  percentiles.prop = get_experimental_percentiles(df, "Overhead", "SketchType", 
                      percentile=percentile, var="Error2")
  percentiles.prop$Method = "Proportion"
  percentiles.samp <- get_experimental_percentiles(df.sampling, "Overhead",
                      percentile=percentile)
  percentiles.samp$Method = "Sampling"
  percentiles.samp$SketchType = "Sampling"
  percentiles = bind_rows(percentiles.drop, percentiles.prop, percentiles.samp)
  plt = ggplot(percentiles, aes(x=Overhead/1e6, y=Percentile)) + 
      geom_line(aes(linetype=SketchType, color=Method)) + 
      geom_point(aes(color=Method)) +
      scale_x_log10() + #scale_y_log10() +
      coord_cartesian(xlim=range(percentiles.drop$Overhead)/1e6, 
                      ylim=c(0, 0.15)) +
      ylab(paste0("Error's ", percentile*100, "% percentile")) + 
      xlab('Network Overhead (Mbps)') + 
      scale_colour_manual(values=custom.colors(3)) +
      scale_linetype_discrete(name='Sketch type', breaks=levels(df$SketchType)) +
      paper_theme +
      theme(legend.box.just="left") +
      theme(legend.justification=c(1,1), legend.position=c(1,1))
  return(plt)
}

plot_adapted_overhead <- function(filenames.sk, filenames.sampling, percentile) {
  df = ldply(filenames.sk, read_ratio)
  df = df[df$DigestSize==32,]
  df.sampling = ldply(filenames.sampling, read_sampling)
  percentiles.sk = get_experimental_percentiles(df, "pcap", "SketchType", 
                                        "TimeInterval", percentile=percentile)
  percentiles.samp = get_experimental_percentiles(df.sampling, "pcap", 
                      "TimeInterval", percentile=percentile)
  percentiles.samp$SketchType = "Sampling"
  percentiles = bind_rows(percentiles.sk, percentiles.samp)
    # Log-log scale
  plt = ggplot(percentiles, aes(x=TimeInterval, y=Percentile)) + 
      geom_line(aes(color=SketchType, linetype=SketchType)) + 
      scale_x_log10() + scale_y_log10() +
      ylab(paste0("Error's ", percentile*100, "% percentile")) +
      xlab('Time interval (s)') + 
      scale_colour_manual(name='Summary function', values=custom.colors(4)) +
      scale_linetype_manual(name='Summary function', values=custom.linetype(4)) +
      paper_theme +
      theme(legend.box.just="left") +
      theme(legend.justification=c(0,1), legend.position=c(0,1)) +
      facet_grid(~pcap, scales='free_x')
    return(plt)
}

plot_interval <- function(filenames.sk, filenames.sampling, percentile) {
  df = ldply(filenames.sk, read_ratio)
  df = df[df$DigestSize==32,]
  packets <- df %>% group_by(TimeInterval, pcap) %>% 
                summarize( numPackets = mean(InputPackets),
                            Percentile = quantile(abs(Error), percentile),
                            bits = mean(OptimizedBits), 
                            SamplingProbability = min(1,bits/32/numPackets))
  packets$numPackets = round_any(packets$numPackets, 10^(floor(log10(packets$numPackets)-1)))
  packets = packets[!grepl("18", as.character(packets$numPackets)),]
  df.sampling = ldply(filenames.sampling, read_sampling)
  percentiles.sk = get_experimental_percentiles(df, "pcap", "SketchType", 
                                        "TimeInterval", percentile=percentile)
  percentiles.samp = get_experimental_percentiles(df.sampling, "pcap", 
                      "TimeInterval", percentile=percentile)
  percentiles.samp$SketchType = "Sampling"
  percentiles = bind_rows(percentiles.sk, percentiles.samp)
  # Log-log scale
  plt = ggplot(percentiles, aes(x=TimeInterval, y=Percentile)) + 
      geom_line(aes(color=SketchType, linetype=SketchType)) + 
      scale_x_log10() + #scale_y_log10() +
      coord_cartesian(ylim=c(0,0.12)) +
      ylab(paste0("Error's ", percentile*100, "% percentile")) +
      xlab('Time interval (s)') + 
      scale_colour_manual(values=custom.colors(4)) +
      scale_linetype_manual(values=custom.linetype(4)) +
      paper_theme +
      theme(legend.title=element_blank(), legend.position="bottom") +
      facet_grid(~pcap, scales='free_x') +
      geom_text(aes(y = Percentile + 0.001, label=numPackets), data=packets)
    return(plt)
}

plot_CPU1 <- function(filename) {
  df = read.csv(filename)
  df$PacketHash = df$timeHash - df$startTime
  df$SketchUpdate = df$timeUpdate - df$timeHash
  df.avg = df %>% group_by(sketchType, generator, hashFunction, sketchColumns) %>%
              summarise(PacketHash = mean(PacketHash), 
                          SketchUpdate = mean(SketchUpdate))
  df.avg = compute_times(df.avg)
  df.avg$TotalTime = df.avg$PacketHash + df.avg$SketchUpdate
  df.avg$sketchType = ifelse(df.avg$sketchType=="FAGMS", 
                              paste0("FAGMS (", df.avg$hashFunction, ")"), 
                              as.character(df.avg$sketchType))
  df.melted <- melt(df.avg, c("sketchType", "generator", "hashFunction"), 
                      c("PacketHash", "DigestHash", "DigestXi"), 
                      value.name="Duration",
                      variable.name = "Operation")
  df.melted$widthPlot = 0.9
  df.melted$widthPlot[df.melted$sketchType=="FastCount"] = 0.9*3/5
  labels = c(PacketHash="Packet's hash", DigestHash="Digest's hash", 
              DigestXi=expression(paste("Digest's ", xi)))
  plt = ggplot(df.melted, aes(x = generator, y = Duration*1e6)) + 
      ylab(expression(paste("Duration (", mu, "s)"))) + 
      xlab("Random generator") +
      geom_bar(stat = 'identity', position = 'stack', 
          aes(width=widthPlot, fill=Operation)) + 
      geom_text(aes(label=round(TotalTime*1e6), y=pmin(TotalTime*1e6+2, 95)), 
          data = df.avg)+
      facet_grid(~ sketchType, scales="free_x") +
      scale_fill_manual(values=custom.colors(length(labels), T), labels = labels) +
      paper_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      coord_cartesian(ylim=c(0, 100)) +
      theme(legend.justification=c(1,1), legend.position=c(1,1)) 
  return(plt)
}

log10_minor_break = function (...){
  function(x) {
    minx         = floor(min(log10(x), na.rm=T))-1;
    maxx         = ceiling(max(log10(x), na.rm=T))+1;
    n_major      = maxx-minx+1;
    major_breaks = seq(minx, maxx, by=1)
    minor_breaks = 
      rep(log10(seq(1, 9, by=1)), times = n_major)+
      rep(major_breaks, each = 9)
    return(10^(minor_breaks))
  }
}

plot_CPU2 <- function(filename){
    df = read.csv(filename)
    df$PacketHash = df$timeHash - df$startTime
    df$SketchUpdate = df$timeUpdate - df$timeHash
    df.avg = df %>% group_by(sketchType, sketchColumns, sketchRows) %>%
                summarise(PacketHash = mean(PacketHash), 
                            SketchUpdate = mean(SketchUpdate),
                            timeDifference = mean(timeDifference))
    df.avg$SketchSize = df.avg$sketchColumns * df.avg$sketchRows
    plt = ggplot(df.avg, aes(x=SketchSize, y=SketchUpdate*1000, colour=sketchType)) + 
            geom_line() + 
            ylab("Duration (ms)") + xlab("Sketch size") +
            paper_theme + 
            scale_y_log10(minor_breaks=log10_minor_break(), 
                    breaks=c(0.001, 0.01, 0.1,1)) + 
            scale_x_log10() +
            scale_color_manual(name="Sketch type", 
                values=custom.colors(nlevels(df.avg$sketchType)))
    return(plt)
}

plot_CPU3 <- function(file.hash, file.xi) {
    df.hash = read.csv(file.hash)
    df.xi = read.csv(file.xi)
    df = rbind(df.hash, df.xi)
    summary.df = df %>% group_by(Type, KeySize) %>% 
                    summarize(Time = mean(Time))
    levels(summary.df$Type) = toupper(levels(summary.df$Type))
    levels(summary.df$Type)[levels(summary.df$Type)=="TAB"] = "Tabulated"
    guide = guide_legend(ncol=2)
    plt = ggplot(summary.df, aes(x=KeySize, y=Time*1e6, color=Type, linetype=Type)) + 
        geom_line() + 
        ylab(expression(paste("Time (", mu, "s)"))) + xlab('Digest size') +
        scale_x_log10(breaks=sort(unique(summary.df$KeySize))) + 
        #scale_y_log10() +
        scale_y_continuous(minor_breaks=seq(0, 10, 0.25), breaks=0:10) +
        scale_colour_manual(values=custom.colors(nlevels(summary.df$Type))) +
        paper_theme +
        coord_cartesian(ylim=c(-0.5,10)) +
        theme(legend.title=element_blank()) +
        guides(color=guide, linetype=guide)
    return(plt)
}

