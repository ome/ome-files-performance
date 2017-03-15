/*
 * #%L
 * OME Files performance tests
 * %%
 * Copyright © 2017 Open Microscopy Environment:
 *   - Massachusetts Institute of Technology
 *   - National Institutes of Health
 *   - University of Dundee
 *   - Board of Regents of the University of Wisconsin-Madison
 *   - Glencoe Software, Inc.
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
 *
 * The views and conclusions contained in the software and documentation are
 * those of the authors and should not be interpreted as representing official
 * policies, either expressed or implied, of any organization.
 * #L%
 */

#include "result.h"
#include "javaTools.h"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <vector>
#include <memory>

#include <boost/filesystem.hpp>

// for Bio-Formats C++ bindings
#include <jace/javacast.h>
#include <formats-api-5.3.4.h>
#include <formats-bsd-5.3.4.h>
#include <ome-common-5.3.1.h>

#include <jace/proxy/ome/xml/model/primitives/PositiveInteger.h>

using namespace jace::proxy;
using jace::java_cast;
using jace::JNIException;
using java::io::IOException;
using java::lang::Exception;
using java::lang::String;

using loci::formats::FormatException;
using loci::formats::FormatReader;
using loci::formats::FormatWriter;
using loci::formats::MetadataTools;
using loci::formats::in::OMETiffReader;
using loci::formats::out::OMETiffWriter;
using loci::formats::out::TiffWriter;
using loci::formats::meta::IMetadata;
using loci::formats::meta::MetadataRetrieve;
using loci::formats::meta::MetadataStore;
using loci::formats::services::OMEXMLService;
using loci::formats::services::OMEXMLServiceImpl;

using loci::formats::tiff::IFD;

int main(int argc, char *argv[])
{
  if (argc != 5)
    {
      std::cerr << "Usage: " << argv[0] << " iterations inputfile outputfile resultfile\n";
      std::exit(1);
    }

  try
    {
      int iterations = std::atoi(argv[1]);
      boost::filesystem::path infile(argv[2]);
      boost::filesystem::path outfile(argv[3]);
      boost::filesystem::path resultfile(argv[4]);

      JavaTools::createJVM(8192);
      std::unique_ptr<OMEXMLService> service = std::make_unique<OMEXMLServiceImpl>();

      std::ofstream results(resultfile.string().c_str());

      result_header(results);

      for(int i = 0; i < iterations; ++i)
        {
          IMetadata meta = service->createOMEXMLMetadata();
          // ByteArray isn't copyable or assignable, so we use a
          // unique_ptr to allow storage in a container.
          std::vector<std::vector<std::unique_ptr<ByteArray>>> pixels;

          timepoint read_start;
          timepoint read_init;

          {
            std::cout << "pass " << i << ": read init..." << std::flush;
            OMETiffReader ometiffreader;
            FormatReader reader = java_cast<FormatReader>(ometiffreader);
            reader.setMetadataStore(meta);
            reader.setId(infile.string());
            std::cout << "done\n" << std::flush;

            read_init = timepoint();

            pixels.resize(reader.getSeriesCount());

            for (jint series = 0;
                 series < reader.getSeriesCount();
                 ++series)
              {
                std::cout << "pass " << i << ": read series " << series << ": " << std::flush;
                reader.setSeries(series);

                std::vector<std::unique_ptr<ByteArray>>& planes = pixels.at(series);
                planes.resize(reader.getImageCount());

                for (jint plane = 0;
                     plane < reader.getImageCount();
                     ++plane)
                  {
                    planes.at(plane) = std::make_unique<ByteArray>(reader.openBytes(plane));
                    std::cout << '.' << std::flush;
                  }
                std::cout << " done\n" << std::flush;
              }
          }

          timepoint read_end;

          result(results, "ometiffdata.read", infile, read_start, read_end);
          result(results, "ometiffdata.read.init", infile, read_start, read_init);
          result(results, "ometiffdata.read.pixels", infile, read_init, read_end);

          // The Java writer doesn't automatically truncate the output file.
          if(boost::filesystem::exists(outfile))
            boost::filesystem::remove(outfile);

          timepoint write_start;
          timepoint write_init;
          timepoint close_start;

          {
            std::cout << "pass " << i << ": write init..." << std::flush;
            OMETiffWriter ometiffwriter;
            FormatWriter writer = java_cast<FormatWriter>(ometiffwriter);
            writer.setMetadataRetrieve(meta);
            writer.setInterleaved(true);
            ometiffwriter.setBigTiff(true);
            writer.setId(outfile.string());
            std::cout << "done\n" << std::flush;

            write_init = timepoint();

            for (jint series = 0;
                 series < static_cast<jint>(pixels.size());
                 ++series)
              {
                std::cout << "pass " << i << ": write series " << series << ": " << std::flush;
                writer.setSeries(series);

                std::vector<unique_ptr<ByteArray>>& planes = pixels.at(series);

                for (jint plane = 0;
                     plane < static_cast<jint>(planes.size());
                     ++plane)
                  {
                    int sizeX = meta.getPixelsSizeX(series).getNumberValue().intValue();
                    IFD ifd;
                    int rows = 65536 / sizeX;
                    if (rows < 1) {
                      rows = 1;
                    }
                    ifd.putIFDValue(IFD::ROWS_PER_STRIP(), static_cast<::jace::proxy::types::JInt>(rows));
                    ByteArray& buf = *(planes.at(plane));
                    TiffWriter tiffwriter = java_cast<TiffWriter>(ometiffwriter);
                    tiffwriter.saveBytes(plane, buf, ifd);
                    std::cout << '.' << std::flush;
                  }
                std::cout << " done\n" << std::flush;
              }

            close_start = timepoint();
            writer.close();
          }

          timepoint write_end;

          result(results, "ometiffdata.write", infile, write_start, write_end);
          result(results, "ometiffdata.write.init", infile, write_start, write_init);
          result(results, "ometiffdata.write.pixels", infile, write_init, close_start);
          result(results, "ometiffdata.write.close", infile, close_start, write_end);
        }
      return 0;
    }
  catch (const FormatException& fe)
    {
      const_cast<FormatException&>(fe).printStackTrace();
    }
  catch (const IOException& ioe)
    {
      const_cast<IOException&>(ioe).printStackTrace();
    }
  catch (const JNIException& jniException)
    {
      cout << "An unexpected JNI error occurred. " << jniException.what() << endl;
    }
  catch (const Exception& e)
    {
      const_cast<Exception&>(e).printStackTrace();
    }
  catch(const std::exception &e)
    {
      std::cerr << "Error: caught exception: " << e.what() << '\n';
    }
  catch(...)
    {
      std::cerr << "Error: unknown exception\n";
    }
  exit(1);
}
