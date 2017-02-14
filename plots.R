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

plot.figure1 <- function() {
    df <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "metadata", TRUE)

    filename <- "cpp-fig1.pdf"
    cat("Creating ", filename, "\n")
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) +
      ylab("Execution time (ms)") + labs(title="Figure 1: Metadata performance") +
      scale_y_continuous(labels=fancy_scientific) +
      geom_boxplot(lwd=0.25, fatten = 2, outlier.size=0.5) +
      facet_wrap(~ Dataset, scales = "free_y")
    ggsave(filename=filename,
           plot=p, width=6, height=3)
}

plot.figure2 <- function() {
    df <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)
    df <- subset(df, test.name == 'read.pixels' | test.name == 'write.pixels')
    df$test.name <- gsub(".pixels", "", df$test.name)
    df$Test <- factor(df$test.name)

    filename <- "cpp-fig2.pdf"
    cat("Creating ", filename, "\n")
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) +
      ylab("Execution time (ms)") + labs(title="Figure 2: Pixel data performance") +
      scale_y_continuous(labels=fancy_scientific) +
      geom_boxplot(lwd=0.25, fatten = 2, outlier.size=0.5) +
      facet_wrap(~ Dataset, scales = "free_y")
    ggsave(filename=filename,
           plot=p, width=6, height=3)
}

plot.figure3 <- function() {
    df <- read.dataset(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)
    df <- subset(df, test.name == 'read' | test.name == 'write')
    df$Test <- factor(df$test.name)

    filename <- "cpp-fig3.pdf"
    cat("Creating ", filename, "\n")
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) +
      ylab("Execution time (ms)") + labs(title="Figure 3: Reader and writer aggregate performance") +
      scale_y_continuous(labels=fancy_scientific) +
      geom_boxplot(lwd=0.25, fatten = 2, outlier.size=0.5) +
      facet_wrap(~ Dataset, scales = "free_y")
    ggsave(filename=filename,
           plot=p, width=6, height=3)
}


realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "metadata", FALSE)
realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "metadata", TRUE)
realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", FALSE)
realtime.compare(c("bbbc", "mitocheck", "tubhiswt"), "pixeldata", TRUE)

plot.figure1()
plot.figure2()
plot.figure3()