library(dplyr)
library(ggplot2)
library(scales)

dataset.name <- function(filename) {
    t <- "Unknown"
    if(filename=="NIRHTa-001.ome.tiff" || filename=="BBBC") {
        t <- "Plate"
    }
    if(filename=="00001_01.ome.tiff" || filename=="MitoCheck") {
        t <- "ROI"
    }
    if(filename=="tubhiswt_C0_TP0.ome.tif" || filename=="tubhiswt") {
        t <- "5D"
    }
    t
}

language.name <- function(language) {
    if(language=="JACE") {
        language <- "JNI"
    }
    language
}

read.dataset <- function(datanames, testname, separate,
                         includejace) {
    df <- data.frame()
    for(dataname in datanames) {
        for(platform in c("linux", "win")) {
            if(separate == TRUE) {
                df.cpp <- data.frame()
                for(filename in paste(paste(dataname, testname, platform, "cpp", seq(1,20,1), sep="-"), "tsv", sep=".")) {
                    df.cpp.tmp <- read.table(paste("results", filename, sep="/"),
                                             header=TRUE, sep="\t", stringsAsFactors=FALSE)
                    df.cpp <- bind_rows(df.cpp, df.cpp.tmp)
                }
            } else {
                filename <- paste(dataname, testname, platform, "cpp.tsv", sep="-")
                df.cpp <- read.table(paste("results", filename, sep="/"),
                                     header=TRUE, sep="\t", stringsAsFactors=FALSE)
            }
            df.jace <- data.frame()
            if (includejace == TRUE && platform == "linux") {
                if(separate == TRUE) {
                    for(filename in paste(paste(dataname, testname, platform, "jace", seq(1,20,1), sep="-"), "tsv", sep=".")) {
                        filename <- paste("results", filename, sep="/")
                        if(file.exists(filename)) {
                            df.jace.tmp <- read.table(filename,
                                                      header=TRUE, sep="\t", stringsAsFactors=FALSE)
                            df.jace <- bind_rows(df.jace, df.jace.tmp)
                        }
                    }
                } else {
                    filename <- paste(dataname, testname, platform, "jace.tsv", sep="-")
                    df.jace <- read.table(paste("results", filename, sep="/"),
                                          header=TRUE, sep="\t", stringsAsFactors=FALSE)
                }
            }
            if(separate == TRUE) {
                df.java <- data.frame()
                for(filename in paste(paste(dataname, testname, platform, "java", seq(1,20,1), sep="-"), "tsv", sep=".")) {
                    df.java.tmp <- read.table(paste("results", filename, sep="/"),
                                             header=TRUE, sep="\t", stringsAsFactors=FALSE)
                    df.java <- bind_rows(df.java, df.java.tmp)
                }
            } else {
                filename <- paste(dataname, testname, platform, "java.tsv", sep="-")
                df.java <- read.table(paste("results", filename, sep="/"),
                                      header=TRUE, sep="\t", stringsAsFactors=FALSE)
            }
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
    df$test.lang <- sapply(df$test.lang, language.name)

    df$Language <- factor(df$test.lang, levels = c("C++", "JNI", "Java"))
    df$Platform <- factor(df$plat)
    df$Test <- factor(df$test.name, levels = c("pixeldata", "metadata"))
    df$Filename <- factor(df$test.file)
    df$Dataset <- factor(df$dataset, levels = c("5D", "Plate", "ROI"))

    df$Implementation <- interaction(df$Language, df$Platform, sep="/", lex.order=TRUE)

    df
}

plot.dataset <- function(df, testname, includejace) {
    filename <- paste(testname, "analysis/realtime.pdf", sep="-")
    if (includejace == TRUE) {
        filename <- paste(testname, "analysis/realtime-withjace.pdf", sep="-")
    }
    cat("Creating ", filename, "\n")
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) + ylab("Execution time (ms)") + labs(title=paste(testname)) + theme(axis.text.x=element_text(angle = 45, hjust = 1.0, vjust = 1.0)) + geom_boxplot(lwd=0.25, fatten = 2, outlier.size=0.5) + facet_wrap(~ Dataset, ncol= 1, scales = "free_y")
    ggsave(filename=filename,
           plot=p, width=6, height=8)
}

realtime.compare <- function(datanames, testname, separate, includejace) {
    df <- read.dataset(datanames, testname, separate, includejace)
    plot.dataset(df, testname, includejace)
}

figure.boxdefaults <- function(df, title, logscale) {
    p <- ggplot(aes(y = proc.real, x = Test, colour=Implementation), data = df) +
      ylab("Execution time (ms)") + labs(title=title) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme(panel.grid.minor.y = element_blank()) +
        scale_colour_brewer(palette = "Dark2") +
        geom_boxplot(lwd=0.25, fatten = 2, outlier.size=0.5) +
        facet_grid(Category ~ Dataset, scales="free_y")
}

figure.bardefaults <- function(df, title, free, invert) {
    summary <- data.frame()
    summary <- group_by(df, Implementation, Test, Dataset, Category) %>%
        summarise(proc.real = mean(proc.real))

    scales <- "fixed"
    if(free)
        scales <- "free_y"
    a <- aes(y = proc.real, x = Test, fill=Implementation)
    if(invert)
        a <- aes(y = proc.real, x = Implementation, fill=Test)
    p <- ggplot(a, data = summary) +
        labs(title=title) +
        theme(panel.grid.minor.y = element_blank()) +
        scale_fill_brewer(palette = "Dark2") +
        geom_bar(stat = "identity", position="dodge") +
        facet_grid(Category ~ Dataset, scales=scales)
}

figure.rawdata <- function(separate) {
    # metadata read/write
    dfmeta <- read.dataset(c("tubhiswt", "bbbc", "mitocheck"), "metadata", separate, TRUE)
    dfmeta$cat <- "metadata"
    # pixel read/write
    dfpix <- read.dataset(c("tubhiswt", "bbbc", "mitocheck"), "pixeldata", separate, TRUE)
    dfpix <- subset(dfpix, test.name == 'read.pixels' | test.name == 'write.pixels')
    dfpix$test.name <- gsub(".pixels", "", dfpix$test.name)
    dfpix$Test <- factor(dfpix$test.name)
    dfpix$cat <- "pixeldata"
    # aggregate read/write
    dfagg <- read.dataset(c("tubhiswt", "bbbc", "mitocheck"), "pixeldata", separate, TRUE)
    dfagg <- subset(dfagg, test.name == 'read' | test.name == 'write')
    dfagg$Test <- factor(dfagg$test.name)
    dfagg$cat <- "aggregate"

    df <- bind_rows(dfmeta, dfpix, dfagg)

    df$Language <- factor(df$test.lang, levels = c("C++", "JNI", "Java"))
    df$Platform <- factor(df$plat)
    df$Test <- factor(df$test.name)
    df$Filename <- factor(df$test.file)
    df$Dataset <- factor(df$dataset, levels = c("5D", "Plate", "ROI"))
    df$Category <- factor(df$cat, levels = c("pixeldata", "metadata", "aggregate"))

    df$Implementation <- interaction(df$Language, df$Platform, sep="/", lex.order=TRUE)

    df
}

figure.data <- function(normalise, separate) {
    df <- figure.rawdata(separate)

#    sdf <- group_by(sdf, Implementation, Test, Filename, Dataset, Category) %>%
#        mutate_each(funs(./mean(.[Implementation == "Java/Linux"])), +proc.real)
                                        #    tapply(sdf$proc.real, interaction(sdf$Implementation, sdf$Test, sdf$Filename, sdf$Dataset, sdf$Category), mean)

    if (normalise == TRUE) {
        # Normalise per-platform
        ndf <- data.frame()
        for(platform in levels(df$Platform)) {
            sdf <-  subset(df, Platform == platform)
            ana <- group_by(filter(sdf, Language == "Java"), Implementation, Test, Dataset, Category) %>%
                summarise(proc.real.mean = mean(proc.real), proc.real.sd=sd(proc.real))

            sdf.norm <- left_join(sdf, ana, by = c("Test", "Dataset", "Category")) %>%
                mutate(proc.real =  proc.real.mean / proc.real)
            sdf.norm$Implementation <- sdf.norm$Implementation.x

#    select(sdf.norm, Filesname=) [,c("Test", "Dataset", "Category", "Implementation", "proc.real", "proc.real.mean")]
            ndf <- rbind(ndf, sdf.norm)
        }

        ndf <-  subset(ndf, Language != "Java")

        ndf$Language <- factor(ndf$test.lang, levels = levels(df$Language))
        ndf$Platform <- factor(ndf$plat)
        ndf$Test <- factor(ndf$test.name)
        ndf$Filename <- factor(ndf$test.file)
        ndf$Dataset <- factor(ndf$dataset, levels = levels(df$Dataset))
        ndf$Category <- factor(ndf$cat, levels = levels(df$Category))

        ndf$Implementation <- interaction(ndf$Language, ndf$Platform, sep="/", lex.order=TRUE)

        df <- ndf
    }

    df
}

plot.figure2 <- function() {
    df <- figure.data(TRUE, TRUE)

    df <- subset(df, Category != 'aggregate')

    filename <- "analysis/files-fig2.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.bardefaults(df, "Figure 2: Relative performance", FALSE, TRUE) +
        theme(axis.title.x=element_blank(), axis.text.x  = element_text(angle=30, hjust=1)) +
        ylab("Relative performance") +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x)),
                           limits=c(0.01,100))

    ggsave(filename=filename,
           plot=p, width=6, height=4)
}

plot.suppfigure1 <- function() {
    df <- figure.data(TRUE, TRUE)

    df <- subset(df, Category != 'aggregate')
    filename <- "analysis/files-suppfig1.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.bardefaults(df, "Supplementary Figure 1: Relative performance", FALSE, FALSE) +
        theme(axis.title.x=element_blank()) +
        ylab("Relative performance") +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x)),
                           limits=c(0.01,100))

    ggsave(filename=filename,
           plot=p, width=6, height=4)

}

plot.suppfigure2 <- function() {
    df <- figure.data(FALSE, TRUE)
    df <- subset(df, Category != 'aggregate')

    filename <- "analysis/files-suppfig2.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.bardefaults(df, "Supplementary Figure 2: Execution time", TRUE, FALSE) +
    ylab("Execution time (ms)") +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x)))
    ggsave(filename=filename,
           plot=p, width=6, height=4)
}

plot.suppfigure3 <- function() {
    df <- figure.data(TRUE, FALSE)
    df <- subset(df, Category != 'aggregate')

    filename <- "analysis/files-suppfig3.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.bardefaults(df, "Supplementary Figure 3: Relative performance (repeated)", FALSE, FALSE) +
        ylab("Relative performance") +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x)),
                           limits=c(0.01,100))

    ggsave(filename=filename,
           plot=p, width=6, height=4)
}

plot.suppfigure4 <- function() {
    df <- figure.data(FALSE, FALSE)
    df <- subset(df, Category != 'aggregate')

    filename <- "analysis/files-suppfig4.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.bardefaults(df, "Supplementary Figure 4: Execution time (repeated)", TRUE, FALSE) +
    ylab("Execution time (ms)") +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x)))
    ggsave(filename=filename,
           plot=p, width=6, height=4)
}

plot.suppfigure5 <- function() {
    df <- figure.data(FALSE, TRUE)

    filename <- "analysis/files-suppfig5.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.boxdefaults(df, "Supplementary Figure 5: Execution time (detail)")

    ggsave(filename=filename,
           plot=p, width=6, height=6)
}

plot.suppfigure6 <- function() {
    df <- figure.data(FALSE, FALSE)

    filename <- "analysis/files-suppfig6.pdf"
    cat("Creating ", filename, "\n")
    p <- figure.boxdefaults(df, "Supplementary Figure 6: Execution time (detail, repeated)")

    ggsave(filename=filename,
           plot=p, width=6, height=6)
}

save.suppdata <- function(separate) {
    source.stats <- read.table("results/datasets.tsv",
                               header=TRUE, sep="\t")
    source.stats$XMLComplexity <- source.stats$Elements + source.stats$Attributes
    source.stats$Dataset <- sapply(source.stats$Dataset, dataset.name)

    df <- figure.rawdata(separate)

    sdf <- group_by(df, Implementation, Dataset, Category, Test) %>%
            summarise(proc.real.mean = mean(proc.real), proc.real.sd=sd(proc.real))

    msdf <- subset(sdf, Category == 'metadata')

    msdf <- left_join(msdf, source.stats, by = c("Dataset"))

    msdf$proc.real.sdratio <- msdf$proc.real.sd / msdf$proc.real.mean
    # Rate in kiloitems/s
    msdf$ItemRate <- (msdf$XMLComplexity / 1000) / ( msdf$proc.real.mean / 1000)
    msdf$ItemRateSD <- msdf$ItemRate * msdf$proc.real.sdratio
    # Rate in MiB/s
    msdf$DataRate <- (msdf$XMLSize / 1024) / ( msdf$proc.real.mean / 1000)
    msdf$DataRateSD <- msdf$DataRate * msdf$proc.real.sdratio
    if(separate==TRUE) {
        write.table(msdf, file="analysis/summary-metadata-separate.tsv", sep="\t", row.names=FALSE)
    } else {
        write.table(msdf, file="analysis/summary-metadata-repeated.tsv", sep="\t", row.names=FALSE)
    }

    psdf <- subset(sdf, Category == 'pixeldata')

    psdf <- left_join(psdf, source.stats, by = c("Dataset"))

    # Rate in MiB/s
    psdf$proc.real.sdratio <- psdf$proc.real.sd / psdf$proc.real.mean
    psdf$DataRate <- psdf$PixelSize / (psdf$proc.real.mean / 1000)
    psdf$DataRateSD <- psdf$DataRate * psdf$proc.real.sdratio
    if(separate==TRUE) {
        write.table(psdf, file="analysis/summary-pixeldata-separate.tsv", sep="\t", row.names=FALSE)
    } else {
        write.table(psdf, file="analysis/summary-pixeldata-repeated.tsv", sep="\t", row.names=FALSE)
    }
}

#realtime.compare(c("tubhiswt", "bbbc", "mitocheck"), "metadata", FALSE)
#realtime.compare(c("tubhiswt", "bbbc", "mitocheck"), "metadata", TRUE)
#realtime.compare(c("tubhiswt", "bbbc", "mitocheck"), "pixeldata", FALSE)
#realtime.compare(c("tubhiswt", "bbbc", "mitocheck"), "pixeldata", TRUE)

plot.figure2()
plot.suppfigure1()
plot.suppfigure2()
plot.suppfigure3()
plot.suppfigure4()
plot.suppfigure5()
plot.suppfigure6()

save.suppdata(TRUE)
save.suppdata(FALSE)
