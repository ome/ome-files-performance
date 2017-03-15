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

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <vector>

#include <ome/compat/array.h>
#include <ome/common/log.h>

#include <ome/files/FormatException.h>
#include <ome/files/VariantPixelBuffer.h>
#include <ome/files/in/MinimalTIFFReader.h>
#include <ome/files/out/MinimalTIFFWriter.h>

#include <ome/xml/meta/OMEXMLMetadata.h>

int main(int argc, char *argv[])
{
  if (argc < 5)
    {
      std::cerr << "Usage: " << argv[0] << " iterations inputfile outputfile resultfile\n";
      std::exit(1);
    }

  try
    {
      ome::common::setLogLevel(ome::logging::trivial::warning);

      int iterations = std::atoi(argv[1]);
      std::vector<boost::filesystem::path> infiles;
      for(int i = 2; i < argc-2; ++i)
        {
          infiles.push_back(argv[i]);
        }
      boost::filesystem::path outfile(argv[argc-2]);
      boost::filesystem::path resultfile(argv[argc-1]);

      std::ofstream results(resultfile.string().c_str());

      result_header(results);

      for(int i = 0; i < iterations; ++i)
        {
          std::vector<timepoint> read_start(infiles.size());
          std::vector<timepoint> read_init(infiles.size());
          std::vector<timepoint> read_end(infiles.size());
          std::vector<timepoint> write_start(infiles.size());
          std::vector<timepoint> write_init(infiles.size());
          std::vector<timepoint> write_close_start(infiles.size());
          std::vector<timepoint> write_end(infiles.size());

          for(std::vector<boost::filesystem::path>::size_type j = 0; j < infiles.size(); ++j)
            {
              const auto& infile = infiles.at(j);

              std::shared_ptr< ::ome::xml::meta::OMEXMLMetadata> omexmlmeta = std::make_shared<ome::xml::meta::OMEXMLMetadata>();
              std::shared_ptr< ::ome::xml::meta::MetadataStore> store = std::dynamic_pointer_cast< ::ome::xml::meta::MetadataStore>(omexmlmeta);
              std::shared_ptr< ::ome::xml::meta::MetadataRetrieve> retrieve;
              std::vector<std::vector<std::unique_ptr<ome::files::VariantPixelBuffer> > > pixels;
              std::vector<bool> interleaved;

              read_start[j] = timepoint();

              std::cout << "pass " << i << ": read init..." << std::flush;
              ome::files::in::MinimalTIFFReader reader;
              reader.setMetadataStore(store);
              reader.setId(infile);
              std::cout << "done\n" << std::flush;

              read_init[j] = timepoint();

              {
                pixels.resize(reader.getSeriesCount());
                interleaved.resize(reader.getSeriesCount());

                for (ome::files::dimension_size_type series = 0;
                     series < reader.getSeriesCount();
                     ++series)
                  {
                    std::cout << "pass " << i << ": read series " << series << ": " << std::flush;
                    reader.setSeries(series);

                    std::vector<std::unique_ptr<ome::files::VariantPixelBuffer> >& planes = pixels.at(series);
                    planes.resize(reader.getImageCount());
                    interleaved.at(series) = reader.isInterleaved();

                    for (ome::files::dimension_size_type plane = 0;
                         plane < reader.getImageCount();
                         ++plane)
                      {
                        reader.setPlane(plane);
                        std::unique_ptr<ome::files::VariantPixelBuffer>& buf = planes.at(plane);
                        buf = std::make_unique<ome::files::VariantPixelBuffer>
                          (boost::extents[1][1][1][1][1][1][1][1][1],
                           reader.getPixelType(),
                           ome::files::PixelBufferBase::make_storage_order(reader.getDimensionOrder(), reader.isInterleaved()));
                        reader.openBytes(plane, *buf);
                        std::cout << '.' << std::flush;
                      }
                    std::cout << " done\n" << std::flush;
                  }
              }

              read_end[j] = timepoint();

              retrieve = std::dynamic_pointer_cast<ome::xml::meta::MetadataRetrieve>(store);
              if (!retrieve)
                {
                  throw ome::files::FormatException("MetadataStore does not implement MetadataRetrieve");
                }

              // To keep the logic the same as for JACE, even though it's unnecessary here
              if(boost::filesystem::exists(outfile))
                boost::filesystem::remove(outfile);

              write_start[j] = timepoint();

              {
                std::cout << "pass " << i << ": write init..." << std::flush;
                std::unique_ptr<ome::files::FormatWriter> writer = std::make_unique<ome::files::out::MinimalTIFFWriter>();
                writer->setMetadataRetrieve(retrieve);
                writer->setInterleaved(interleaved.at(0));
                dynamic_cast<ome::files::out::MinimalTIFFWriter &>(*writer.get()).setBigTIFF(true);
                writer->setId(outfile);
                std::cout << "done\n" << std::flush;

                write_init[j] = timepoint();

                for (ome::files::dimension_size_type series = 0;
                     series < pixels.size();
                     ++series)
                  {
                    std::cout << "pass " << i << ": write series " << series << ": " << std::flush;
                    writer->setInterleaved(interleaved.at(series));
                    writer->setSeries(series);

                    std::vector<std::unique_ptr<ome::files::VariantPixelBuffer> >& planes = pixels.at(series);

                    for (ome::files::dimension_size_type plane = 0;
                         plane < planes.size();
                         ++plane)
                      {
                        writer->setPlane(plane);

                        std::unique_ptr<ome::files::VariantPixelBuffer>& buf = planes.at(plane);
                        writer->saveBytes(plane, *buf);
                        std::cout << '.' << std::flush;
                      }
                    std::cout << " done\n" << std::flush;
                  }
                write_close_start[j] = timepoint();
                writer->close();
              }

              write_end[j] = timepoint();
            }
          result(results, "pixeldata.read", infiles[0], read_start, read_end);
          result(results, "pixeldata.read.init", infiles[0], read_start, read_init);
          result(results, "pixeldata.read.pixels", infiles[0], read_init, read_end);
          result(results, "pixeldata.write", infiles[0], write_start, write_end);
          result(results, "pixeldata.write.init", infiles[0], write_start, write_init);
          result(results, "pixeldata.write.pixels", infiles[0], write_init, write_close_start);
          result(results, "pixeldata.write.close", infiles[0], write_close_start, write_end);
        }
      return 0;
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
