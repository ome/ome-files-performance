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
#include <vector>

#include <boost/container/vector.hpp>

#include <ome/common/log.h>

#include <ome/files/FormatException.h>
#include <ome/files/VariantPixelBuffer.h>
#include <ome/files/in/OMETIFFReader.h>
#include <ome/files/out/OMETIFFWriter.h>

#include <ome/xml/meta/OMEXMLMetadata.h>

int main(int argc, char *argv[])
{
  if (argc != 4)
    {
      std::cerr << "Usage: " << argv[0] << " iterations inputfile outputfile\n";
      std::exit(1);
    }

  try
    {
      ome::common::setLogLevel(ome::logging::trivial::warning);

      int iterations = std::atoi(argv[1]);
      boost::filesystem::path infile(argv[2]);
      boost::filesystem::path outfile(argv[3]);

      result_header(std::cout);

      for(int i = 0; i < iterations; ++i)
        {
          ome::compat::shared_ptr< ::ome::xml::meta::OMEXMLMetadata> omexmlmeta = ome::compat::make_shared<ome::xml::meta::OMEXMLMetadata>();
          ome::compat::shared_ptr< ::ome::xml::meta::MetadataStore> store = ome::compat::dynamic_pointer_cast< ::ome::xml::meta::MetadataStore>(omexmlmeta);
          ome::compat::shared_ptr< ::ome::xml::meta::MetadataRetrieve> retrieve;
          boost::container::vector<boost::container::vector<ome::files::VariantPixelBuffer> > pixels;

          timepoint read_start;

          {
            ome::files::in::OMETIFFReader reader;
            reader.setMetadataStore(store);
            reader.setId(infile);
            //            store = reader.getMetadataStore();

            pixels.resize(reader.getSeriesCount());
            for (ome::files::dimension_size_type series = 0;
                 series < reader.getSeriesCount();
                 ++series)
              {
                reader.setSeries(series);

                boost::container::vector<ome::files::VariantPixelBuffer>& planes = pixels.at(series);
                planes.resize(reader.getImageCount(), ome::files::VariantPixelBuffer());
                for (ome::files::dimension_size_type plane = 0;
                     plane < reader.getImageCount();
                     ++plane)
                  {
                    reader.setPlane(plane);

                    ome::files::VariantPixelBuffer& buf = planes.at(plane);
                    reader.openBytes(plane, buf);
                  }
              }
          }

          timepoint read_end;

          result(std::cout, "pixeldata.read", infile, read_start, read_end);

          retrieve = ome::compat::dynamic_pointer_cast<ome::xml::meta::MetadataRetrieve>(store);
          if (!retrieve)
            {
              throw ome::files::FormatException("MetadataStore does not implement MetadataRetrieve");
            }

          timepoint write_start;

          {
            ome::compat::shared_ptr<ome::files::FormatWriter> writer = ome::compat::make_shared<ome::files::out::OMETIFFWriter>();
            writer->setMetadataRetrieve(retrieve);
            writer->setInterleaved(true);
            writer->setId(outfile);

            for (ome::files::dimension_size_type series = 0;
                 series < pixels.size();
                 ++series)
              {
                writer->setSeries(series);

                boost::container::vector<ome::files::VariantPixelBuffer>& planes = pixels.at(series);

                for (ome::files::dimension_size_type plane = 0;
                     plane < planes.size();
                     ++plane)
                  {
                    writer->setPlane(plane);

                    ome::files::VariantPixelBuffer& buf = planes.at(plane);
                    writer->saveBytes(plane, buf);
                  }
              }

            writer->close();
          }

          timepoint write_end;

          result(std::cout, "pixeldata.write", infile, write_start, write_end);

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
