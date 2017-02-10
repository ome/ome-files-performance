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
import java.nio.file.Path;
import java.nio.file.Paths;

import loci.common.DataTools;
import loci.common.services.ServiceException;
import loci.common.services.ServiceFactory;

import loci.formats.meta.MetadataStore;
import loci.formats.meta.MetadataRetrieve;
import loci.formats.ome.OMEXMLMetadata;
import loci.formats.ome.OMEXMLMetadataImpl;
import loci.formats.services.OMEXMLService;
import loci.formats.services.OMEXMLServiceImpl;

import loci.formats.tiff.TiffParser;

public final class MetadataPerformance {

  public static void main(String[] args) {
    if (args.length != 4)
      {
        System.out.println("Usage: MetadataPerformance iterations inputfile outputfile resultfile\n");
        System.exit(1);
      }

    Result result = null;

    try {
      int iterations = Integer.parseInt(args[0]);
      Path infile = Paths.get(args[1]);
      Path outfile = Paths.get(args[2]);
      Path resultfile = Paths.get(args[3]);

      ServiceFactory factory = new ServiceFactory();
      OMEXMLService service = factory.getInstance(OMEXMLService.class);

      result = new Result(resultfile);

      for(int i = 0; i < iterations; i++) {
        OMEXMLMetadata meta = new OMEXMLMetadataImpl();

        Timepoint read_start = new Timepoint();

        System.out.print("pass " + i + ": read init...");
        String omexml;
        if(infile.toString().endsWith(".tiff") ||
           infile.toString().endsWith(".tif")) { // OME-TIFF file
          omexml = new TiffParser(infile.toString()).getComment();
        } else { // XML file
          omexml = DataTools.readFile(infile.toString());// read infile
        }
        meta = service.createOMEXMLMetadata(omexml);
        System.out.println("done");

        Timepoint read_end = new Timepoint();

        result.add("metadata.read", infile, read_start, read_end);

        Timepoint write_start = new Timepoint();

        {
          System.out.print("pass " + i + ": write init...");
          String xml = service.getOMEXML(meta);
          service.validateOMEXML(xml);

          Writer out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outfile.toString()), "UTF-8"));
          out.flush();
          try {
            out.write(xml);
          } finally {
            out.close();
          }

          System.out.println("done\n");
        }

        Timepoint write_end = new Timepoint();

        result.add("metadata.write", infile, write_start, write_end);
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
