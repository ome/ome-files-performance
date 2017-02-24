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

import java.io.BufferedWriter;
import java.io.Writer;
import java.io.OutputStreamWriter;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import java.util.List;
import java.util.ArrayList;

import loci.common.DataTools;
import loci.common.services.ServiceException;
import loci.common.services.ServiceFactory;

import loci.formats.meta.MetadataStore;
import loci.formats.meta.MetadataRetrieve;
import loci.formats.ome.OMEXMLMetadata;
import loci.formats.ome.OMEXMLMetadataImpl;
import loci.formats.services.OMEXMLService;
import loci.formats.services.OMEXMLServiceImpl;
import loci.formats.in.MinimalTiffReader;
import loci.formats.out.TiffWriter;
import loci.formats.FormatReader;
import loci.formats.FormatWriter;

import loci.formats.tiff.IFD;
import loci.formats.tiff.TiffParser;

public final class PixelsPerformance {

  public static void main(String[] args) {
    if (args.length < 4)
      {
        System.out.println("Usage: MetadataPerformance iterations inputfile outputfile resultfile\n");
        System.exit(1);
      }

    Result result = null;

    try {
      int iterations = Integer.parseInt(args[0]);
      List<Path> infiles = new ArrayList<Path>();
      for(int i = 1; i < args.length-2; i++)
        {
          infiles.add(Paths.get(args[i]));
        }
      Path outfile = Paths.get(args[args.length-2]);
      Path resultfile = Paths.get(args[args.length-1]);

      ServiceFactory factory = new ServiceFactory();
      OMEXMLService service = factory.getInstance(OMEXMLService.class);

      result = new Result(resultfile);

      for(int i = 0; i < iterations; i++) {
        List<Timepoint> read_start = new ArrayList<Timepoint>();
        List<Timepoint> read_init = new ArrayList<Timepoint>();
        List<Timepoint> read_end = new ArrayList<Timepoint>();
        List<Timepoint> write_start = new ArrayList<Timepoint>();
        List<Timepoint> write_init = new ArrayList<Timepoint>();
        List<Timepoint> write_close_start = new ArrayList<Timepoint>();
        List<Timepoint> write_end = new ArrayList<Timepoint>();

        for(int j = 0; j < infiles.size(); ++j) {
          Path infile = infiles.get(j);

          OMEXMLMetadata meta = new OMEXMLMetadataImpl();
          List<List<byte[]>> pixels = new ArrayList();

          read_start.add(new Timepoint());
          {
            System.out.print("pass " + i + ": read init...");
            System.out.flush();
            FormatReader reader = new MinimalTiffReader();
            reader.setMetadataStore(meta);
            reader.setId(infile.toString());
            System.out.println("done");
            System.out.flush();

            read_init.add(new Timepoint());

            for (int series = 0; series <reader.getSeriesCount(); ++series) {
              System.out.print("pass " + i + ": read series " + series + ": ");
              System.out.flush();
              reader.setSeries(series);

              List<byte[]> planes = new ArrayList();
              pixels.add(planes);

              for (int plane = 0; plane < reader.getImageCount(); ++plane) {
                byte[] data = reader.openBytes(plane);
                planes.add(data);
                System.out.print(".");
                System.out.flush();
              }
              System.out.println("done");
              System.out.flush();
            }
            reader.close();
          }

          read_end.add(new Timepoint());

          Files.deleteIfExists(outfile);

          write_start.add(new Timepoint());

          {
            System.out.print("pass " + i + ": write init...");
            System.out.flush();
            FormatWriter writer = new TiffWriter();
            writer.setMetadataRetrieve(meta);
            writer.setWriteSequentially(true);
            writer.setInterleaved(true);
            ((TiffWriter)writer).setBigTiff(true);
            writer.setId(outfile.toString());
            System.out.println("done");
            System.out.flush();

            write_init.add(new Timepoint());

            for (int series = 0; series < pixels.size(); ++series)
              {
                System.out.print("pass " + i + ": write series " + series + ": ");
                System.out.flush();
                writer.setInterleaved(true);
                writer.setSeries(series);

                List<byte[]> planes = pixels.get(series);

                for (int plane = 0; plane < planes.size(); ++plane)
                  {
                    int sizeX = meta.getPixelsSizeX(series).getValue().intValue();
                    IFD ifd = new IFD();
                    int rows = 65536 / sizeX;
                    if (rows < 1) {
                      rows = 1;
                    }
                    ifd.put(IFD.ROWS_PER_STRIP, rows);
                    byte[] data = planes.get(plane);
                    ((TiffWriter)writer).saveBytes(plane, data, ifd);
                    System.out.print(".");
                    System.out.flush();
                  }
                System.out.println("done");
                System.out.flush();
              }
            write_close_start.add(new Timepoint());
            writer.close();
          }

          write_end.add(new Timepoint());
        }

        result.add("pixeldata.read", infiles.get(0), read_start, read_end);
        result.add("pixeldata.read.init", infiles.get(0), read_start, read_init);
        result.add("pixeldata.read.pixels", infiles.get(0), read_init, read_end);
        result.add("pixeldata.write", infiles.get(0), write_start, write_end);
        result.add("pixeldata.write.init", infiles.get(0), write_start, write_init);
        result.add("pixeldata.write.pixels", infiles.get(0), write_init, write_close_start);
        result.add("pixeldata.write.close", infiles.get(0), write_close_start, write_end);
      }

      result.close();
      System.exit(0);
    }
    catch(Exception e) {
      if (result != null) {
        result.close();
      }
      System.err.println("Error: caught exception: " + e);
      e.printStackTrace();
      System.exit(1);
    }
  }
}
