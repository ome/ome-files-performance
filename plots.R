library(dplyr)
library(ggplot2)
library(scales)

##########
# From https://groups.google.com/d/msg/ggplot2/a_xhMoQyxZ4/OQHLPGsRtAQJ (with some modification)
fancy_scientific <- function(l) {
     # turn in to character string in scientific notation
     print(l)
     l <- format(l, scientific = TRUE)
     print(l)
     # Use verbatim zero value
     l <- gsub("0e\\+00", "0", l)
     # quote the part before the exponent to keep all the digits
     l <- gsub("^(.*)e", "'\\1'e", l)
     print(l)
     # turn the 'e+' into plotmath format
     l <- gsub("e\\+?", "%*%10^", l)
     print(l)
     # return this as an expression
     parse(text=l)
}
##########

dataset.name <- function(filename) {
    t <- "Unknown"
    if(filename=="NIRHTa-001.ome.tiff") {
        t <- "BBBC"
    }
    if(filename=="00001_01.ome.tiff") {
        t <- "MitoCheck"
    }
    if(filename=="tubhiswt_C0_TP0.ome.tif") {
        t <- "tubhiswt"
    }
    t
}

read.dataset <- function(datanames, testname, includejace) {
    df <- data.frame()
    for(dataname in datanames) {
        for(platform in c("linux", "win")) {
            df.cpp <- read.table(paste(dataname, testname, platform, "cpp.tsv", sep="-"),
                                 header=TRUE, sep="\t", stringsAsFactors=FALSE)
            df.jace <- data.frame()
            if (includejace == TRUE && platform == "linux") {
                df.jace <- read.table(paste(dataname, testname, platform, "jace.tsv", sep="-"),
                                      header=TRUE, sep="\t", stringsAsFactors=FALSE)
            }
            df.java <- read.table(paste(dataname, testname, platform, "java.tsv", sep="-"),
                                  header=TRUE, sep="\t", stringsAsFactors=FALSE)
            names(df.java)[names(df.java) == 'real'] <- 'proc.real'

            platdf <- bind_rows(df.cpp, df.jace, df.java)
            platdf$plat <- platform
            if(platform == "linux") {
                platdf$plat <- "Linux"
            } else if (platform == "win") {
                platdf$plat <- "Windows"
            }
            df <- bind_rows(df, platdf)
        }
    }

    df$test.name <- gsub(paste(testname, ".", sep=""), "", df$test.name)
    df$dataset <- sapply(df$test.file, dataset.name)

    df$Language <- factor(df$test.lang)
    df$Platform <- factor(df$plat)
    df$Test <- factor(df$test.name)
    df$Filename <- factor(df$test.file)
    df$Dataset <- factor(df$dataset)

    df$Implementation <- interaction(df$Language, df$Platform, sep="/", lex.order=TRUE)

    df
}

plot.dataset <- function(df, testname, includejace) {
    filename <- paste(testname, "realtime.pdf", sep="-")
    if (includejace == TRUE) {
        filename <- paste(testname, "realtime-withjace.pdf", sep="-")
    }
    cat("Creating ", filename, "\n")
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) + ylab("Execution time (ms)") + labs(title=paste(testname)) + theme(axis.text.x=element_text(angle = 45, hjust = 1.0, vjust = 1.0)) + geom_boxplot(lwd=0.25, fatten = 2, outlier.size=0.5) + facet_wrap(~ Dataset, ncol= 1, scales = "free_y")
    ggsave(filename=filename,
           plot=p, width=6, height=8)
}

realtime.compare <- function(datanames, testname, includejace) {
    df <- read.dataset(datanames, testname, includejace)
    plot.dataset(df, testname, includejace)
}

figure.boxdefaults <- function(df, title) {
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) +
      ylab("Execution time (ms)") + labs(title=title) +
      scale_y_continuous(trans = 'log10',
                         breaks = trans_breaks('log10', function(x) 10^x),
                         labels = trans_format('log10', math_format(10^.x))) +
      theme(panel.grid.minor.y = element_blank()) +
      scale_colour_brewer(palette = "Set1") +
      geom_boxplot(lwd=0.25, fatten = 2, outlier.size=0.5) +
      facet_wrap(~ Dataset)
}

figure.bardefaults <- function(df, title) {
    p <- ggplot(aes(y = proc.real, x = Test, fill=Implementation), data = df) +
        ylab("Execution time (ms)") + labs(title=title) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme(panel.grid.minor.y = element_blank()) +
        scale_fill_manual(values=c("red", "darkred", "green", "blue", "darkblue")) +
        geom_bar(stat = "summary", fun.y = "mean", position="dodge") +
        facet_grid(Category ~ Dataset, scales="free")
}

figure.data() <- function() {
    # metadata read/write
    dfmeta <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "metadata", TRUE)
    dfmeta$cat <- "metadata"
    # pixel read/write
    dfpix <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)
    dfpix <- subset(dfpix, test.name == 'read.pixels' | test.name == 'write.pixels')
    dfpix$test.name <- gsub(".pixels", "", dfpix$test.name)
    dfpix$Test <- factor(dfpix$test.name)
    dfpix$cat <- "pixeldata"

    # Only plot aggregate read/write
    dfagg <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)
    dfagg <- subset(dfagg, test.name == 'read' | test.name == 'write')
    dfagg$Test <- factor(dfagg$test.name)

    df <- bind_rows(dfmeta, dfpix, dfagg)
}

plot.figure1 <- function() {

    df$Language <- factor(df$test.lang)
    df$Platform <- factor(df$plat)
    df$Test <- factor(df$test.name)
    df$Filename <- factor(df$test.file)
    df$Dataset <- factor(df$dataset)
    df$Category <- factor(df$cat)

    filename <- "cpp-fig1.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.bardefaults(df, "Figure 1: Performance")
    ggsave(filename=filename,
           plot=p, width=6, height=6)
}

plot.suppfigure1 <- function() {
    df <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "metadata", TRUE)

    filename <- "cpp-suppfig1.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.boxdefaults(df, "Figure 1: Metadata performance")
    ggsave(filename=filename,
           plot=p, width=6, height=3)
}
plot.suppfigure2 <- function() {
    df <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)
    # Only plot pixel read/write
    df <- subset(df, test.name == 'read.pixels' | test.name == 'write.pixels')
    df$test.name <- gsub(".pixels", "", df$test.name)
    df$Test <- factor(df$test.name)

    filename <- "cpp-suppfig2.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.boxdefaults(df, "Figure 2: Pixel data performance")
    ggsave(filename=filename,
           plot=p, width=6, height=3)
}

plot.suppfigure3 <- function() {
    df <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)
    # Only plot aggregate read/write
    df <- subset(df, test.name == 'read' | test.name == 'write')
    df$Test <- factor(df$test.name)

    filename <- "cpp-suppfig3.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.boxdefaults(df, "Figure 3: Reader and writer aggregate performance")
    ggsave(filename=filename,
           plot=p, width=6, height=3)
}


#realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "metadata", FALSE)
#realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "metadata", TRUE)
#realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", FALSE)
#realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)

plot.figure1()
plot.suppfigure1()
plot.suppfigure2()
plot.suppfigure3()
