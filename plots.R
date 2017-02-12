library(dplyr)
library(ggplot2)

realtime.compare <- function(dataname, testname, includejace) {
    df <- data.frame()
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

    df$Language <- factor(df$test.lang)
    df$Platform <- factor(df$plat)
    df$Test <- factor(df$test.name)
    df$Filename <- factor(df$test.file)

    df$Implementation <- interaction(df$Language, df$Platform, sep="/", lex.order=TRUE)

    filename <- paste(dataname, testname, "realtime.pdf", sep="-")
    if (includejace == TRUE) {
        filename <- paste(dataname, testname, "realtime-withjace.pdf", sep="-")
    }
    cat("Creating ", filename, "\n")
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) + ylab("Execution time (ms)") + labs(title=paste(dataname, testname)) + theme(axis.text.x=element_text(angle = 45, hjust = 1.0, vjust = 1.0)) + geom_boxplot()
    ggsave(filename=filename,
           plot=p, width=6, height=6)
}

realtime.compare("bbbc", "metadata", FALSE)
realtime.compare("mitocheck", "metadata", FALSE)
realtime.compare("tubhiswt", "metadata", FALSE)

realtime.compare("bbbc", "pixeldata", FALSE)
realtime.compare("mitocheck", "pixeldata", FALSE)
realtime.compare("tubhiswt", "pixeldata", FALSE)

realtime.compare("bbbc", "metadata", TRUE)
realtime.compare("mitocheck", "metadata", TRUE)
realtime.compare("tubhiswt", "metadata", TRUE)

realtime.compare("bbbc", "pixeldata", TRUE)
realtime.compare("mitocheck", "pixeldata", TRUE)
realtime.compare("tubhiswt", "pixeldata", TRUE)
