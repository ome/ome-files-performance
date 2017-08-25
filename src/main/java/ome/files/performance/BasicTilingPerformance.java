/*
 * #%L
 * Common package for I/O and related utilities
 * %%
 * Copyright (C) 2017 Open Microscopy Environment:
 *   - Board of Regents of the University of Wisconsin-Madison
 *   - Glencoe Software, Inc.
 *   - University of Dundee
 * %%
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * #L%
 */

package ome.files.performance;

import loci.common.RandomAccessOutputStream;
import loci.formats.FormatTools;
import loci.formats.codec.CodecOptions;
import loci.formats.codec.CompressionType;
import loci.formats.tiff.IFD;
import loci.formats.tiff.TiffSaver;
import ome.xml.model.enums.PixelType;
import ome.xml.model.enums.handlers.PixelTypeEnumHandler;

import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class BasicTilingPerformance {

    private long iteration;
    private PixelType pixeltype;
    private TileType tiletype;
    private long sizex;
    private long sizey;
    private long tilexsize;
    private long tileysize;
    private long tilexcount;
    private long tileycount;
    private String description;
    private Path output_file;

    private BasicTilingPerformance(PixelType pixeltype,
                                  TileType tiletype,
                                  long sizex,
                                  long sizey) {
        this.iteration = 0;
        this.pixeltype = pixeltype;
        this.tiletype = tiletype;
        this.sizex = sizex;
        this.sizey = sizey;
        this.tilexsize = 0;
        this.tileysize = 0;
        this.tilexcount = 0;
        this.tileycount = 0;
        description = null;
        output_file = null;
    }

    private static void run_tests(List<BasicTilingPerformance> tests,
                                  Result results,
                                  Result sizes)
            throws IOException, loci.formats.FormatException
    {
        for (BasicTilingPerformance t : tests)
        {

            System.out.println("TEST: [" + t.iteration + "] " + t.description);

            byte[][] buf = {
                    new byte[(int) (t.tilexsize * t.tileysize * FormatTools.getBytesPerPixel(t.pixeltype.toString()))],
                    new byte[(int) ((t.sizex % t.tilexsize) * t.tileysize * FormatTools.getBytesPerPixel(t.pixeltype.toString()))],
                    new byte[(int) (t.tilexsize * (t.sizey % t.tileysize) * FormatTools.getBytesPerPixel(t.pixeltype.toString()))],
                    new byte[(int) ((t.sizex % t.tilexsize) * (t.sizey % t.tileysize) * FormatTools.getBytesPerPixel(t.pixeltype.toString()))]
            };
            // Fill with random data, to avoid the filesystem not writing
            // (or compressing) empty data blocks as an optimisation.
            for (int i = 0; i < buf.length; i++) {
                for (int j = 0; j < buf[i].length; j++) {
                    buf[i][j] = (byte) (Math.random() * 255);
                }
            }

            try {
                Files.delete(t.output_file);
            }
            catch (NoSuchFileException e) {
            }

            TiffSaver tiff = new TiffSaver(t.output_file.toString());
            tiff.setWritingSequentially(true);
            tiff.setLittleEndian(true);
            tiff.setBigTiff(true);
            tiff.setCodecOptions(new CodecOptions());

            IFD ifd = new IFD();
            ifd.put(IFD.IMAGE_WIDTH, t.sizex);
            ifd.put(IFD.IMAGE_LENGTH, t.sizey);
            if(t.tiletype == TileType.TILE) {
                ifd.put(IFD.TILE_WIDTH, t.tilexsize);
                ifd.put(IFD.TILE_LENGTH, t.tileysize);
            } else {
                ifd.put(IFD.ROWS_PER_STRIP, t.tileysize);
            }

            ifd.put(IFD.LITTLE_ENDIAN, true);

            ifd.putIFDValue(IFD.PLANAR_CONFIGURATION, 1);
            int sampleFormat = 1;
            if (FormatTools.isSigned(FormatTools.pixelTypeFromString(t.pixeltype.toString()))) sampleFormat = 2;
            if (FormatTools.isFloatingPoint(FormatTools.pixelTypeFromString(t.pixeltype.toString()))) sampleFormat = 3;
            ifd.putIFDValue(IFD.SAMPLE_FORMAT, sampleFormat);

            ifd.put(IFD.IMAGE_DESCRIPTION, "OME Files performance test");

            ifd.put(IFD.COMPRESSION, CompressionType.UNCOMPRESSED.getCode());

            Timepoint write_start = new Timepoint();

            tiff.writeHeader();
            for (long tiley = 0; tiley < t.tileycount; ++tiley)
            {
                long y = tiley * t.tileysize;
                long sy = t.tileysize;
                if (y + t.tileysize > t.sizey) {
                    sy = t.sizey % t.tileysize;
                }

                for (long tilex = 0; tilex < t.tilexcount; ++tilex)
                {
                    long x = tilex * t.tilexsize;
                    long sx = t.tilexsize;
                    if (x + t.tilexsize > t.sizex) {
                        sx = t.sizex % t.tilexsize;
                    }

                    byte[] wbuf = buf[0];
                    if (sx != t.tilexsize && sy == t.tileysize) {
                        wbuf = buf[1];
                    }
                    else if (sx == t.tilexsize && sy != t.tileysize) {
                        wbuf = buf[2];
                    }
                    else if (sx != t.tilexsize && sy != t.tileysize) {
                        wbuf = buf[3];
                    }

                    RandomAccessOutputStream stream = tiff.getStream();
                    stream.seek(stream.length());

                    //System.out.println("TL: " + x + "," + y + "," + sx + "," + sy + " (" + t.tilexsize + "," + t.tileysize + ")  b="+wbuf);
                    tiff.writeImage(wbuf, ifd,0, FormatTools.pixelTypeFromString(t.pixeltype.toString()), (int) x, (int) y, (int) sx, (int) sy,
                            tilex >= t.tilexcount - 1);
                }
            }
            tiff.close();

            Timepoint write_end = new Timepoint();

            results.add("pixeldata.write", FileSystems.getDefault().getPath(t.description), write_start, write_end);
            sizes.addCustomParam("filesize", Files.size(t.output_file));
            sizes.add("pixeldata.write", FileSystems.getDefault().getPath(t.description), write_start, write_end);
        }

        // Intermediate cleanup
        for (BasicTilingPerformance t : tests) {
            try {
                Files.delete(t.output_file);
            }
            catch(NoSuchFileException e) {
            }
        }
    }

    public static void main(String[] args) {
        if (args.length != 11) {
            System.out.println("Usage: iterations sizex sizey tiletype tilesizestart tilesizeend tilesizestep pixeltype outputfileprefix resultfile sizefile");
            System.exit(1);
        }

        Result results = null;
        Result sizes = null;

        try {
            long iterations = Long.parseLong(args[0]);
            long sizex = Long.parseLong(args[1]);
            long sizey = Long.parseLong(args[2]);
            TileType tiletype = args[3].equals("tile") ? TileType.TILE : TileType.STRIP;
            long tilestart = Long.parseLong(args[4]);
            long tileend = Long.parseLong(args[5]);
            long tilestep = Long.parseLong(args[6]);
            String pixeltype = args[7];
            String outfileprefix = args[8];
            Path resultfile = FileSystems.getDefault().getPath(args[9]);
            Path sizefile = FileSystems.getDefault().getPath(args[10]);

            List<BasicTilingPerformance> tests = new ArrayList<>();
            for(long tilesize = tilestart; tilesize <= tileend; tilesize += tilestep) {
                BasicTilingPerformance t = new BasicTilingPerformance((PixelType) new PixelTypeEnumHandler().getEnumeration(pixeltype),
                        tiletype, sizex, sizey);

                if (t.tiletype == TileType.STRIP) {
                    t.tilexsize = sizex;
                    t.tilexcount = 1;
                } else {
                    t.tilexsize = tilesize;
                    t.tilexcount = t.sizex / tilesize;
                    if ((t.sizex % tilesize) != 0)
                        ++t.tilexcount;
                }
                t.tileysize = tilesize;
                t.tileycount = t.sizey / tilesize;
                if (t.sizey % tilesize != 0)
                    ++t.tileycount;

                StringBuilder desc = new StringBuilder();
                desc.append(t.sizex);
                desc.append('-');
                desc.append(t.sizey);
                desc.append('-');
                desc.append((t.tiletype == TileType.TILE ? "tile" : "strip"));
                desc.append('-');
                desc.append(t.tilexsize);
                desc.append('-');
                desc.append(t.tileysize);
                desc.append('-');
                desc.append(t.pixeltype);
                t.description = desc.toString();

                t.output_file = FileSystems.getDefault().getPath(outfileprefix + '-' + desc + ".tiff");

                tests.add(t);
            }

            results = new Result(resultfile);
            sizes = new Result(sizefile);
            sizes.addCustomParam("filesize", 0);

            for(int i = 0; i < iterations; ++i)
            {
                // Randomise test order.
                Collections.shuffle(tests);
                for (BasicTilingPerformance t : tests) {
                    t.iteration = i;
                }
                run_tests(tests, results, sizes);
            }

            results.close();
            sizes.close();
            System.exit(0);
        }
        catch(Exception e) {
            if (results != null) {
                results.close();
            }
            if (sizes != null) {
                sizes.close();
            }
            System.err.println("Error: caught exception: " + e);
            e.printStackTrace();
            System.exit(1);
        }
    }

    enum TileType
    {
        STRIP,
        TILE
    }
}
