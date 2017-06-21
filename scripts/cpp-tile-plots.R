library(dplyr)
library(ggplot2)
library(scales)


read.tile.timings <- function() {
    df <- data.frame()
    for(test in c("tile-small", "tile-big", "strip")) {
        for(pixeltype in c("uint8", "int16", "uint32", "float")) {
            filename <- paste(paste("tile-test", test, pixeltype, sep="-"), ".tsv", sep="")
            df.test <- read.table(paste("results", filename, sep="/"),
                                  header=TRUE, sep="\t", stringsAsFactors=FALSE)
            df.test$test <- test
            df <- rbind(df, df.test)
        }
    }

    details <- do.call(rbind, strsplit(df$test.file, "-"))
    df$xsize <- as.numeric(details[,1])
    df$ysize <- as.numeric(details[,2])
    df$type <- details[,3]
    df$tilexsize <- as.numeric(details[,4])
    df$tileysize <- as.numeric(details[,5])
    df$pixeltype <- details [,6]

    df$ImageSize <- factor(df$xsize)
    df$TileSize <- factor(df$tileysize)
    df$Test <- factor(df$test, levels = c("tile-small", "tile-big", "strip"))
    df$Type <- factor(df$type)
    df$PixelType <- factor(df$pixeltype, levels = c("uint8", "int16", "uint32", "float"))

    df
}

read.tile.sizes <- function() {
    df <- data.frame()
    for(test in c("tile-small", "tile-big", "strip")) {
        for(pixeltype in c("uint8", "int16", "uint32", "float")) {
            filename <- paste(paste("tile-test", test, pixeltype, "sizes", sep="-"), ".tsv", sep="")
            df.test <- read.table(paste("results", filename, sep="/"),
                                  header=TRUE, sep="\t", stringsAsFactors=FALSE)
            df.test$test <- test
            df <- rbind(df, df.test)
        }
    }

    details <- do.call(rbind, strsplit(df$test.file, "-"))
    df$xsize <- as.numeric(details[,1])
    df$ysize <- as.numeric(details[,2])
    df$type <- details[,3]
    df$tilexsize <- as.numeric(details[,4])
    df$tileysize <- as.numeric(details[,5])
    df$pixeltype <- details [,6]

    df$ImageSize <- factor(df$xsize)
    df$TileSize <- factor(df$tileysize)
    df$Test <- factor(df$test, levels = c("tile-small", "tile-big", "strip"))
    df$Type <- factor(df$type)
    df$PixelType <- factor(df$pixeltype, levels = c("uint8", "int16", "uint32", "float"))

    df
}

tilecount <- function(imagesize, tilesize) {
    ntiles = ceiling(imagesize / tilesize)
    ntiles^2
}

stripcount <- function(imagesize, stripsize) {
    ceiling(imagesize / stripsize)
}

perf.data <- function() {
    df <- read.tile.timings()
head(df)
    sdf <- group_by(df, ImageSize, TileSize, Test, Type, PixelType) %>%
        summarise(proc.real.mean = mean(proc.real), proc.real.sd=sd(proc.real), proc.real.median = median(proc.real))
    sdf$TileSize <- as.numeric(as.character(sdf$TileSize))
    sdf
}

size.data <- function() {
    df <- read.tile.sizes()
head(df)
    sdf <- group_by(df, ImageSize, TileSize, Test, Type, PixelType) %>%
        summarise(filesize.mean = mean(filesize), filesize.sd=sd(filesize), filesize.median = median(filesize))
    sdf$TileSize <- as.numeric(as.character(sdf$TileSize))
    sdf
}

figure.tilewriting <- function() {
    summary <- perf.data()
    tiles <- summary %>%
        filter(Type == "tile", PixelType != "float") %>%
        droplevels()

    p <- ggplot(tiles, aes(y = proc.real.mean, x=TileSize)) +
        labs(title="Tile writing performance") +
        scale_colour_brewer("Pixel type", palette = "Dark2") +
        scale_fill_brewer("Pixel type", palette = "Dark2") +
        geom_ribbon(aes(ymin=proc.real.mean-proc.real.sd, ymax=proc.real.mean+proc.real.sd, fill=PixelType), alpha=0.1) +
        geom_line(aes(colour=PixelType), size=0.25) +
        facet_wrap(~Test, scale="free_y", ncol=1) +
        ylab("Execution time (ms)") +
        xlab("Tile size (pixels)") +
        annotation_logticks(sides="l", size=0.2) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', n=2, function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme_bw() +
        theme(plot.title = element_text(hjust = 0.5))

    ggsave(filename="analysis/tile-test-write-performance.pdf",
           plot=p, width=6, height=4)
}

figure.stripwriting <- function() {
    summary <- perf.data()
    strips <- summary %>%
        filter(Type == "strip", PixelType != "float") %>%
        droplevels()

    p <- ggplot(strips, aes(y = proc.real.mean, x=TileSize)) +
        labs(title="Strip writing performance") +
        scale_colour_brewer("Pixel type", palette = "Dark2") +
        scale_fill_brewer("Pixel type", palette = "Dark2") +
        geom_ribbon(aes(ymin=proc.real.mean-proc.real.sd, ymax=proc.real.mean+proc.real.sd, fill=PixelType), alpha=0.1) +
        geom_line(aes(colour=PixelType), size=0.25) +
        facet_wrap(~Test, scale="free_y", ncol=1) +
        ylab("Execution time (ms)") +
        xlab("Strip size (pixels)") +
        annotation_logticks(sides="l", size=0.2) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', n=2, function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme_bw() +
        theme(plot.title = element_text(hjust = 0.5))

    ggsave(filename="analysis/strip-test-write-performance.pdf",
           plot=p, width=6, height=4)
}

figure.tilesizes <- function() {
    summary <- size.data()
    tiles <- summary %>%
        filter(Type == "tile", PixelType != "float") %>%
        droplevels()

    p <- ggplot(tiles, aes(y = filesize.mean / (1024 * 1024), x=TileSize)) +
        labs(title="Tiled file size") +
        scale_colour_brewer("Pixel type", palette = "Dark2") +
        scale_fill_brewer("Pixel type", palette = "Dark2") +
        geom_line(aes(colour=PixelType), size=0.25) +
        facet_wrap(~Test, scale="free_y", ncol=1) +
        ylab("File size (MiB)") +
        xlab("Tile size (pixels)") +
        annotation_logticks(sides="l", size=0.2) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', n=2, function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme_bw() +
        theme(plot.title = element_text(hjust = 0.5))

    ggsave(filename="analysis/tile-test-write-size.pdf",
           plot=p, width=6, height=4)
}

figure.stripsizes <- function() {
    summary <- size.data()
    strips <- summary %>%
        filter(Type == "strip", PixelType != "float") %>%
        droplevels()

    p <- ggplot(strips, aes(y = filesize.mean / (1024 * 1024), x=TileSize)) +
        labs(title="Stripped file size") +
        scale_colour_brewer("Pixel type", palette = "Dark2") +
        scale_fill_brewer("Pixel type", palette = "Dark2") +
        geom_line(aes(colour=PixelType), size=0.25) +
        facet_wrap(~Test, scale="free_y", ncol=1) +
        ylab("File size (MiB)") +
        xlab("Strip size (pixels)") +
        annotation_logticks(sides="l", size=0.2) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', n=2, function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme_bw() +
        theme(plot.title = element_text(hjust = 0.5))

    ggsave(filename="analysis/strip-test-write-size.pdf",
           plot=p, width=6, height=4)
}

figure.tilecount <- function() {
    summary <- perf.data()
    tiles <- filter(summary, Type == "tile")
    tiles$tilecount <- tilecount(as.numeric(as.character(tiles$ImageSize)), as.numeric(as.character(tiles$TileSize)))

    p <- ggplot(tiles, aes(y = tilecount, x=TileSize)) +
        labs(title="Tile count") +
        geom_line(size=0.25) +
        facet_wrap(~Test, scale="free_y", ncol=1) +
        ylab("Tile count") +
        xlab("Tile size") +
        annotation_logticks(sides="l", size=0.2) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', n=2, function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme_bw() +
        theme(plot.title = element_text(hjust = 0.5))

    ggsave(filename="analysis/tile-test-count.pdf",
           plot=p, width=6, height=4)
}

figure.stripcount <- function() {
    summary <- perf.data()
    strips <- filter(summary, Type == "strip")
    strips$stripcount <- stripcount(as.numeric(as.character(strips$ImageSize)), as.numeric(as.character(strips$TileSize)))

    p <- ggplot(strips, aes(y = stripcount, x=TileSize)) +
        labs(title="Strip count") +
        geom_line(size=0.25) +
        facet_wrap(~Test, scale="free_y", ncol=1) +
        ylab("Strip count") +
        xlab("Strip size") +
        annotation_logticks(sides="l", size=0.2) +
        scale_y_continuous(trans = 'log10',
                           breaks = trans_breaks('log10', n=2, function(x) 10^x),
                           labels = trans_format('log10', math_format(10^.x))) +
        theme_bw() +
        theme(plot.title = element_text(hjust = 0.5))

    ggsave(filename="analysis/strip-test-count.pdf",
           plot=p, width=6, height=4)
}

figure.stripwriting()
figure.tilewriting()
figure.tilesizes()
figure.stripsizes()
figure.stripcount()
figure.tilecount()
