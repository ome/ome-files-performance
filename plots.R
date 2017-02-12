library(dplyr)
library(ggplot2)

realtime.compare <- function(dataname, testname, platform) {
    df.lin.cpp <- read.table(paste(dataname, testname, platform, "cpp.tsv", sep="-"),
                                 header=TRUE, sep="\t", stringsAsFactors=FALSE)
    df.lin.jace <- read.table(paste(dataname, testname, platform, "jace.tsv", sep="-"),
                                 header=TRUE, sep="\t", stringsAsFactors=FALSE)
    df.lin.java <- read.table(paste(dataname, testname, platform, "java.tsv", sep="-"),
                                 header=TRUE, sep="\t", stringsAsFactors=FALSE)
    names(df.lin.java)[names(df.lin.java) == 'real'] <- 'proc.real'

    df <- bind_rows(df.lin.cpp, df.lin.jace, df.lin.java)

    df$Implementation <- factor(df$test.lang)
    df$Test <- factor(df$test.name)
    df$Filename <- factor(df$test.file)

    df$int <- interaction(df$Implementation, df$Test)



    filename <- paste(dataname, testname, "realtime.pdf", sep="-")
    cat("Creating ", filename, "\n")
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) + ylab("Execution time (ms)") + labs(title=paste(dataname, testname, platform)) + theme(axis.text.x=element_text(angle = 45, hjust = 1.0, vjust = 1.0)) + geom_boxplot()
    ggsave(filename=filename,
            plot=p, width=6, height=6)
}

realtime.compare("bbbc", "metadata", "linux")
realtime.compare("mitocheck", "metadata", "linux")
realtime.compare("tubhiswt", "metadata", "linux")

realtime.compare("bbbc", "pixeldata", "linux")
realtime.compare("mitocheck", "pixeldata", "linux")
realtime.compare("tubhiswt", "pixeldata", "linux")
