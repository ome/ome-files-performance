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

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import java.util.List;
import java.util.ArrayList;

import loci.formats.ome.OMEXMLMetadata;
import loci.formats.ome.OMEXMLMetadataImpl;
import loci.formats.out.OMETiffWriter;
import loci.formats.out.TiffWriter;
import loci.formats.tiff.IFD;
import ome.xml.model.primitives.PositiveInteger;
import loci.formats.FormatWriter;
import loci.formats.ImageReader;
import loci.formats.MetadataTools;
import loci.formats.meta.IMetadata;

public final class TilingPerformance {

  public static void main(String[] args) {
    if (args.length != 12) {
      System.out.println("Usage: TilingPerformance iterations tileSizeXStart tileSizeYStart tileSizeXEnd tileSizeYEnd tileSizeOperator tileSizeIncrement series autoTile inputfile outputfile resultfile\n");
      System.exit(1);
    }

    Result result = null;

    try {
      int iterations = Integer.parseInt(args[0]);
      int tileSizeXStart = Integer.parseInt(args[1]);
      int tileSizeYStart = Integer.parseInt(args[2]);
      int tileSizeXEnd = Integer.parseInt(args[3]);
      int tileSizeYEnd = Integer.parseInt(args[4]);
      String tileSizeOperator = args[5];
      int tileSizeIncrement = Integer.parseInt(args[6]);
      int series = Integer.parseInt(args[7]);
      boolean autoTiling = Boolean.parseBoolean(args[8]);
      Path infile = Paths.get(args[9]);
      String outfileBase = args[10];
      Path resultfile = Paths.get(args[11]);

      
      result = new Result(resultfile);

      for(int i = 0; i < iterations; i++) {
        int tileSizeX = tileSizeXStart;
        int tileSizeY = tileSizeYStart;
        while (tileSizeX >= tileSizeXEnd) {
          tileSizeY = tileSizeYStart;
          while (tileSizeY >= tileSizeYEnd) {
            System.out.println("New tileX " + tileSizeX + " " + tileSizeY + " " + autoTiling);
            result.addCustomParam("test.tileSizeX", tileSizeX);
            result.addCustomParam("test.tileSizeY", tileSizeY);
            Path outfile = Paths.get(outfileBase+"-"+tileSizeX+"-"+tileSizeY+".ome.tiff");
            System.out.print("pass " + i + ": init...");
            System.out.flush();
            IMetadata meta = MetadataTools.createOMEXMLMetadata();
            List<List<byte[]>> planes = new ArrayList<List<byte[]>>();
            ImageReader reader = new ImageReader();
            reader.setMetadataStore(meta);
            reader.setId(infile.toString());
            reader.setSeries(series);
            int width = reader.getSizeX();
            int height = reader.getSizeY();
            
            FormatWriter writer = new OMETiffWriter();
            IMetadata writerMeta = MetadataTools.createOMEXMLMetadata();
            writerMeta.setImageID("Image:0", 0);
            writerMeta.setPixelsID("Pixels:0", 0);
            writerMeta.setPixelsSizeX(new PositiveInteger(width), 0);
            writerMeta.setPixelsSizeY(new PositiveInteger(height), 0);
            writerMeta.setPixelsSizeZ(meta.getPixelsSizeZ(series), 0);
            writerMeta.setPixelsSizeC(meta.getPixelsSizeC(series), 0);
            writerMeta.setPixelsSizeT(meta.getPixelsSizeT(series), 0);
            writerMeta.setPixelsBigEndian(meta.getPixelsBigEndian(series), 0);
            writerMeta.setPixelsDimensionOrder(meta.getPixelsDimensionOrder(series), 0);
            for (int channel=0; channel<meta.getChannelCount(series); channel++) {
              writerMeta.setChannelID("Channel:0:" + channel, 0, channel);
              writerMeta.setChannelSamplesPerPixel(meta.getChannelSamplesPerPixel(series, channel), 0, channel);
            }
            writerMeta.setPixelsType(meta.getPixelsType(series), 0);
            writer.setMetadataRetrieve(writerMeta);
            writer.setWriteSequentially(true);
            writer.setInterleaved(true);
            ((OMETiffWriter)writer).setBigTiff(true);
            if (tileSizeX > 0) {
              tileSizeX = writer.setTileSizeX(tileSizeX);       
            }
            else {
              tileSizeX = width;
            }
            if (tileSizeY > 0) {
              tileSizeY = writer.setTileSizeY(tileSizeY);         
            }
            else {
              tileSizeY = height;
            }
            int nXTiles = width / tileSizeX;
            int nYTiles = height / tileSizeY;
            if (nXTiles * tileSizeX != width) nXTiles++;
            if (nYTiles * tileSizeY != height) nYTiles++;
            int tilesPerImage = nXTiles * nYTiles;
            
            System.out.println("done");
            System.out.flush();
    
            {
              System.out.print("pass " + i + ": convert series " + series + ": ");
              System.out.flush();
              reader.setSeries(series);
  
              List<byte[]> tiles = new ArrayList<byte[]>();
              planes.add(tiles);
  
              for (int plane = 0; plane < reader.getImageCount(); ++plane) {
                if (autoTiling) {
                  byte[] data = reader.openBytes(plane);
                  tiles.add(data);
                }
                else {
                  for (int y=0; y<nYTiles; y++) {
                    for (int x=0; x<nXTiles; x++) {
                      int tileX = x * tileSizeX;
                      int tileY = y * tileSizeY;
                      int effTileSizeX = (tileX + tileSizeX) < width ? tileSizeX : width - tileX;
                      int effTileSizeY = (tileY + tileSizeY) < height ? tileSizeY : height - tileY;
  
                      byte[] data = reader.openBytes(plane, tileX, tileY, effTileSizeX, effTileSizeY);
                      tiles.add(data);
                    }
                  }
                }
                System.out.print(".");
                System.out.flush();
              }
              System.out.println("done");
              System.out.flush();

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
    
              for (int seriesNum = 0; seriesNum < planes.size(); ++seriesNum) {
                System.out.print("pass " + i + ": write series " + seriesNum + ": ");
                System.out.flush();
                writer.setInterleaved(true);
                writer.setSeries(seriesNum);
    
                List<byte[]> tiles = planes.get(seriesNum);
                int dataIndex = 0;
                int imageCount = tiles.size();
                if (!autoTiling) {
                  imageCount = imageCount / tilesPerImage;
                }
    
                for (int plane = 0; plane < imageCount; ++plane) {
                  if (autoTiling) {
                    byte[] data = tiles.get(dataIndex);
                    ((TiffWriter) writer).saveBytes(plane, data);
                    dataIndex++;
                  }
                  else {
                    IFD ifd = new IFD();
                    ifd.put(new Integer(IFD.TILE_WIDTH), new Long(tileSizeX));
                    ifd.put(new Integer(IFD.TILE_LENGTH), new Long(tileSizeY));
                    for (int y=0; y<nYTiles; y++) {
                      for (int x=0; x<nXTiles; x++) {
                        int tileX = x * tileSizeX;
                        int tileY = y * tileSizeY;
                        int effTileSizeX = (tileX + tileSizeX) < width ? tileSizeX : width - tileX;
                        int effTileSizeY = (tileY + tileSizeY) < height ? tileSizeY : height - tileY;
                        byte[] data = tiles.get(dataIndex);
    
                        ((TiffWriter) writer).saveBytes(plane, data, ifd, tileX, tileY, effTileSizeX, effTileSizeY);
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
            
            File file =new File(outfile.toString());
            double bytes = file.length();
            double kilobytes = (bytes / 1024);
            double megabytes = (kilobytes / 1024);
            result.add("tiling.write.filesize", infile, megabytes);
            
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
    
              for (int seriesNum = 0; seriesNum < reader.getSeriesCount(); ++seriesNum) {
                System.out.print("pass " + i + ": read series " + seriesNum + ": ");
                System.out.flush();
                reader.setSeries(seriesNum);
    
                List<byte[]> tiles = new ArrayList<byte[]>();
                planes.add(tiles);
    
                for (int plane = 0; plane < reader.getImageCount(); ++plane) {
                  if (autoTiling) {
                    byte[] data = reader.openBytes(plane);
                    tiles.add(data);
                  }
                  else {
                    for (int y=0; y<nYTiles; y++) {
                      for (int x=0; x<nXTiles; x++) {
                        int tileX = x * tileSizeX;
                        int tileY = y * tileSizeY;
                        int effTileSizeX = (tileX + tileSizeX) < width ? tileSizeX : width - tileX;
                        int effTileSizeY = (tileY + tileSizeY) < height ? tileSizeY : height - tileY;
    
                        byte[] data = reader.openBytes(plane, tileX, tileY, effTileSizeX, effTileSizeY);
                        tiles.add(data);
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
              file.delete();
              Timepoint read_end = new Timepoint();
    
              result.add("tiling.read", infile, read_start, read_end);
              result.add("tiling.read.ini", infile, read_start, read_init);
              result.add("tiling.read.pixels", infile, read_init, read_end);
            }
            if (tileSizeOperator.equals("-")) {
              tileSizeY = tileSizeY - tileSizeIncrement;
            }
            else {
              tileSizeY = tileSizeY / tileSizeIncrement;
            }
          }
          if (tileSizeOperator.equals("-")) {
            tileSizeX = tileSizeX - tileSizeIncrement;
          }
          else {
            tileSizeX = tileSizeX / tileSizeIncrement;
          }
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
