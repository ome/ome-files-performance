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

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import java.util.List;
import java.util.ArrayList;

import loci.formats.ome.OMEXMLMetadata;
import loci.formats.ome.OMEXMLMetadataImpl;
import loci.formats.out.OMETiffWriter;
import loci.formats.out.TiffWriter;
import loci.formats.FormatWriter;
import loci.formats.ImageReader;

public final class TilingPerformance {

  public static void main(String[] args) {
    if (args.length != 6) {
      System.out.println("Usage: TilingPerformance iterations tileSize autoTile inputfile outputfile resultfile\n");
      System.exit(1);
    }

    Result result = null;

    try {
      int iterations = Integer.parseInt(args[0]);
      int tileSize = Integer.parseInt(args[1]);
      boolean autoTiling = Boolean.parseBoolean(args[2]);
      Path infile = Paths.get(args[3]);
      Path outfile = Paths.get(args[4]);
      Path resultfile = Paths.get(args[5]);

      result = new Result(resultfile);

      for(int i = 0; i < iterations; i++) {
        System.out.print("pass " + i + ": init...");
        System.out.flush();
        OMEXMLMetadata meta = new OMEXMLMetadataImpl();
        List<List<byte[]>> pixels = new ArrayList<List<byte[]>>();
        ImageReader reader = new ImageReader();
        reader.setMetadataStore(meta);
        reader.setId(infile.toString());
        int width = reader.getSizeX();
        int height = reader.getSizeY();
        
        FormatWriter writer = new OMETiffWriter();
        writer.setMetadataRetrieve(meta);
        writer.setWriteSequentially(true);
        writer.setInterleaved(true);
        ((OMETiffWriter)writer).setBigTiff(true);
        int tileSizeX = width;
        int tileSizeY = height;
        if (tileSize > 0) {
          tileSizeX = writer.setTileSizeX(tileSize);
          tileSizeY = writer.setTileSizeY(tileSize);         
        }
        int nXTiles = width / tileSizeX;
        int nYTiles = height / tileSizeY;
        if (nXTiles * tileSizeX != width) nXTiles++;
        if (nYTiles * tileSizeY != height) nYTiles++;
        int tilesPerImage = nXTiles * nYTiles;
        
        System.out.println("done");
        System.out.flush();

        {
          for (int series = 0; series < reader.getSeriesCount(); ++series) {
            System.out.print("pass " + i + ": convert series " + series + ": ");
            System.out.flush();
            reader.setSeries(series);

            List<byte[]> planes = new ArrayList<byte[]>();
            pixels.add(planes);

            for (int plane = 0; plane < reader.getImageCount(); ++plane) {
              if (autoTiling) {
                byte[] data = reader.openBytes(plane);
                planes.add(data);
              }
              else {
                for (int y=0; y<nYTiles; y++) {
                  for (int x=0; x<nXTiles; x++) {
                    int tileX = x * tileSizeX;
                    int tileY = y * tileSizeY;
                    int effTileSizeX = (tileX + tileSizeX) < width ? tileSizeX : width - tileX;
                    int effTileSizeY = (tileY + tileSizeY) < height ? tileSizeY : height - tileY;

                    byte[] data = reader.openBytes(plane, tileX, tileY, effTileSizeX, effTileSizeY);
                    planes.add(data);
                  }
                }
              }
              System.out.print(".");
              System.out.flush();
            }
            System.out.println("done");
            System.out.flush();
          }
          reader.close();
        }

        Files.deleteIfExists(outfile);

        Timepoint write_start = new Timepoint();
        Timepoint write_init = null;
        Timepoint close_start = null;

        {
          System.out.print("pass " + i + ": write init...");
          System.out.flush();

          writer.setId(outfile.toString());

          System.out.println("done");
          System.out.flush();

          write_init = new Timepoint();

          for (int series = 0; series < pixels.size(); ++series) {
            System.out.print("pass " + i + ": write series " + series + ": ");
            System.out.flush();
            writer.setInterleaved(true);
            writer.setSeries(series);

            List<byte[]> planes = pixels.get(series);
            int dataIndex = 0;
            int imageCount = planes.size();
            if (!autoTiling) {
              imageCount = imageCount / tilesPerImage;
            }

            for (int plane = 0; plane < imageCount; ++plane) {
              if (autoTiling) {
                byte[] data = planes.get(dataIndex);
                ((TiffWriter) writer).saveBytes(plane, data);
                dataIndex++;
              }
              else {
                for (int y=0; y<nYTiles; y++) {
                  for (int x=0; x<nXTiles; x++) {
                    int tileX = x * tileSizeX;
                    int tileY = y * tileSizeY;
                    int effTileSizeX = (tileX + tileSizeX) < width ? tileSizeX : width - tileX;
                    int effTileSizeY = (tileY + tileSizeY) < height ? tileSizeY : height - tileY;
                    byte[] data = planes.get(dataIndex);

                    writer.saveBytes(plane, data, tileX, tileY, effTileSizeX, effTileSizeY);
                    dataIndex++;
                  }
                }
              }
              System.out.print(".");
              System.out.flush();
            }
            System.out.println("done");
            System.out.flush();
          }
          close_start = new Timepoint();
          writer.close();
        }

        Timepoint write_end = new Timepoint();

        result.add("tiling.write", infile, write_start, write_end);
        result.add("tiling.write.init", infile, write_start, write_init);
        result.add("tiling.write.pixels", infile, write_init, close_start);
        result.add("tiling.write.close", infile, close_start, write_end);
        
        {
          Timepoint read_start = new Timepoint();
          Timepoint read_init = null;

          System.out.print("pass " + i + ": read init...");
          System.out.flush();
          
          reader = new ImageReader();
          reader.setMetadataStore(meta);
          reader.setId(outfile.toString());

          System.out.println("done");
          System.out.flush();

          read_init = new Timepoint();

          for (int series = 0; series < reader.getSeriesCount(); ++series) {
            System.out.print("pass " + i + ": read series " + series + ": ");
            System.out.flush();
            reader.setSeries(series);

            List<byte[]> planes = new ArrayList<byte[]>();
            pixels.add(planes);

            for (int plane = 0; plane < reader.getImageCount(); ++plane) {
              if (autoTiling) {
                byte[] data = reader.openBytes(plane);
                planes.add(data);
              }
              else {
                for (int y=0; y<nYTiles; y++) {
                  for (int x=0; x<nXTiles; x++) {
                    int tileX = x * tileSizeX;
                    int tileY = y * tileSizeY;
                    int effTileSizeX = (tileX + tileSizeX) < width ? tileSizeX : width - tileX;
                    int effTileSizeY = (tileY + tileSizeY) < height ? tileSizeY : height - tileY;

                    byte[] data = reader.openBytes(plane, tileX, tileY, effTileSizeX, effTileSizeY);
                    planes.add(data);
                  }
                }
              }
              System.out.print(".");
              System.out.flush();
            }
            System.out.println("done");
            System.out.flush();
          }
          reader.close();
          
          Timepoint read_end = new Timepoint();

          result.add("tiling.read", infile, read_start, read_end);
          result.add("tiling.read.ini", infile, read_start, read_init);
          result.add("tiling.read.pixels", infile, read_init, read_end);
        }
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
