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

#include <boost/filesystem.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/make_shared.hpp>

// for Bio-Formats C++ bindings
#include <formats-api-5.2.4.h>
#include <formats-bsd-5.2.4.h>
#include <formats-common-5.2.4.h>

using namespace jace::proxy;
using jace::JNIException;
using jace::proxy::java::io::IOException;
using java::lang::String;

using loci::formats::FormatException;
using loci::formats::MetadataTools;
using loci::formats::meta::MetadataRetrieve;
using loci::formats::meta::MetadataStore;
using loci::formats::tiff::TiffParser;
using loci::formats::services::OMEXMLService;
using loci::formats::services::OMEXMLServiceImpl;

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

      JavaTools::createJVM();
      boost::shared_ptr<OMEXMLService> service = boost::make_shared<OMEXMLServiceImpl>();

      std::ofstream results(resultfile.string().c_str());

      result_header(results);

      for(int i = 0; i < iterations; ++i)
        {
          MetadataStore meta;

          timepoint read_start;

          std::cout << "pass " << i << ": read init...";
          if(infile.extension() == ".tiff")
            {
              // OME-TIFF file
              try
                {
                  TiffParser parser(infile.string());
                  std::string omexml = parser.getComment();
                  meta = service->createOMEXMLMetadata(omexml);
                }
              catch (const std::exception&)
                {
                  throw FormatException("No TIFF ImageDescription found");
                }
            }
          else
            {
              // XML file
              meta = service->createOMEXMLMetadata(infile.string());
            }
          std::cout << "done\n";

          timepoint read_end;

          result(results, "metadata.read", infile, read_start, read_end);

          timepoint write_start;

          {
            std::cout << "pass " << i << ": write init...";
            MetadataRetrieve retrieve = service->asRetrieve(meta);
            std::string xml = service->getOMEXML(retrieve);
            service->validateOMEXML(xml);
            std::ofstream out(outfile.string().c_str());
            out << xml;
            out << std::flush;
            out.close();
            std::cout << "done\n";
          }

          timepoint write_end;

          result(results, "metadata.write", infile, write_start, write_end);
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
