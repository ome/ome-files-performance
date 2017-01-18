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

#include <ome/common/log.h>

#include <ome/files/FormatException.h>
#include <ome/files/MetadataTools.h>
#include <ome/files/tiff/TIFF.h>
#include <ome/files/tiff/IFD.h>
#include <ome/files/tiff/Exception.h>
#include <ome/files/tiff/Field.h>

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
          ome::compat::shared_ptr< ::ome::xml::meta::OMEXMLMetadata> meta;

          timepoint read_start;

          if(infile.extension() == ".tiff")
            {
              // OME-TIFF file
              try
                {
                  ome::compat::shared_ptr<ome::files::tiff::TIFF> tiff = ome::files::tiff::TIFF::open(infile, "r");
                  ome::compat::shared_ptr<ome::files::tiff::IFD> ifd (tiff->getDirectoryByIndex(0));
                  if (ifd)
                    {
                      std::string omexml;
                      ifd->getField(ome::files::tiff::IMAGEDESCRIPTION).get(omexml);
                      meta = ome::files::createOMEXMLMetadata(omexml);
                    }
                  else
                    throw ome::files::tiff::Exception("No TIFF IFDs found");
                }
              catch (const ome::files::tiff::Exception&)
                {
                  throw ome::files::FormatException("No TIFF ImageDescription found");
                }
            }
          else
            {
              // XML file
              meta = ome::files::createOMEXMLMetadata(infile);
            }

          timepoint read_end;

          result(std::cout, "metadata.read", infile, read_start, read_end);

          timepoint write_start;

          {
            std::string xml = ome::files::getOMEXML(*meta, true);
            std::ofstream out(outfile.string().c_str());
            out << xml;
            out << std::flush;
            out.close();
          }

          timepoint write_end;

          result(std::cout, "metadata.write", infile, write_start, write_end);
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
