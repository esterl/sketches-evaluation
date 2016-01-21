paper_theme = theme_grey() %+replace%
                # Legend
                theme(legend.key=element_rect(colour=NA, fill=NA), 
                        legend.justification=c(0,1), legend.position=c(0,1),
                        legend.background = element_rect(color='grey80', fill='white'), 
                        legend.text.align=0) %+replace%
                # Axis
                theme( axis.ticks = element_line(colour = 'grey80')) %+replace%
                # Background
                theme(panel.background = element_rect(fill = "white", colour = NA), 
                        panel.border = element_rect(fill = NA, colour = "grey50"), 
                        panel.grid.major = element_line(colour = "grey90", size = 0.2), 
                        panel.grid.minor = element_line(colour = "grey98", size = 0.5), 
                        strip.background = element_rect(fill = "grey80", colour = "grey50", size = 0.2))

colors <- c(    white =         "#FFFFFF",
                grey1 =         "#F5F5F5",
                grey2 =         "#E0E0E0",
                grey3 =         "#9e9e9e",
                grey4 =         "#616161",
                grey5 =         "#212121",
                black =         "#000000",
                lightGold =     "#ffe57f",
                lightGold2 =    "#FFC400",
                gold =          "#ffc200",
                darkGold =      "#ffab00",
                lightGreen =    "#a5d6a7",
                lightGreen2 =   "#66BB6A",
                green =         "#4caf50",
                darkGreen =     "#1b5e20",
                lightOrange =   "#FFB74D",
                lightOrange2 =  "#FFA726",
                orange =        "#ff7d00",
                darkOrange =    "#ff6d00",
                lightBlue =     "#9fa8da",
                lightBlue2 =    "#5C6BC0",
                blue =          "#3f51b5",
                darkBlue =      "#1a237e",
                lightPurple =   "#e1bee7",
                lightPurple2 =  "#AB47BC",
                purple =        "#9c27b0",
                darkPurple =    "#6a1b9a",
                lightBrown =    "#bcaaa4",
                lightBrown2 =   "#8D6E63",
                brown =         "#795548",
                darkBrown =     "#3e2723",
                lightRed =      "#ef9a9a",
                lightRed2 =      "#EF5350",
                red =           "#f44336",
                darkRed =       "#b71c1c")

custom.colors <- function(n, light=F, reference=F) {
    if (light) {
        palette <- unname(colors[c( "lightBlue2", "lightRed2", "lightGreen2", 
                                    "lightGold2", "lightPurple2", 
                                    "lightOrange2", "lightBrown2")])
    } else {
        palette <- unname(colors[c( "darkBlue", "darkRed", "darkGreen", 
                                    "darkGold", "darkPurple", "darkOrange", 
                                    "darkBrown")])
    }

    if (n > length(palette))
        warning('palette has duplicated colours')
    if (reference) {
      c("#000000", rep(palette, length.out=n-1))
    } else {
      rep(palette, length.out=n)
    }
}

custom.linetype <- function(n) {
  types <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")
  if (n > length(types))
    warning('duplicated linetypes')
  rep(types, length.out=n)
}

