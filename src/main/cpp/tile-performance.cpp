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
#include <limits>
#include <memory>
#include <sstream>
#include <vector>

#include <boost/filesystem.hpp>

#include <boost/random/normal_distribution.hpp>
#include <boost/random.hpp>

#include <ome/compat/array.h>
#include <ome/common/log.h>

#include <ome/files/tiff/TIFF.h>
#include <ome/files/tiff/IFD.h>
#include <ome/files/PixelProperties.h>
#include <ome/files/VariantPixelBuffer.h>

using namespace ome::files::tiff;
using ome::files::PixelBuffer;
using ome::files::VariantPixelBuffer;
using ome::xml::model::enums::PixelType;

namespace
{

  struct RandomFillVisitor : public boost::static_visitor<>
  {
    RandomFillVisitor():
      rng(934)
    {
    }

    template<typename T>
    typename boost::enable_if_c<
      boost::is_integral<T>::value, void
      >::type
    operator() (std::shared_ptr<PixelBuffer<T>>& buffer)
    {
      boost::random::uniform_int_distribution<> distrib
        (std::numeric_limits<T>::min(), std::numeric_limits<T>::max());
      typename PixelBuffer<T>::value_type *data = buffer->data();
      for(typename PixelBuffer<T>::size_type i = 0;
          i < buffer->num_elements();
          ++i)
        {
          data[i] = distrib(rng);
        }
    }

    template<typename T>
    typename boost::enable_if_c<
      boost::is_floating_point<T>::value, void
      >::type
    operator() (std::shared_ptr<PixelBuffer<T>>& buffer)
    {
      boost::random::uniform_real_distribution<> distrib(0, 1);

      typename PixelBuffer<T>::value_type *data = buffer->data();
      for(typename PixelBuffer<T>::size_type i = 0;
          i < buffer->num_elements();
          ++i)
        {
          data[i] = distrib(rng);
        }
    }

    template<typename T>
    void
    operator() (std::shared_ptr<PixelBuffer<std::complex<T>>>& buffer)
    {
      boost::random::uniform_real_distribution<> distrib(0, 1);

      typename PixelBuffer<std::complex<T>>::value_type *data = buffer->data();
      for(typename PixelBuffer<std::complex<T>>::size_type i = 0;
          i < buffer->num_elements();
          ++i)
        {
          data[i] = std::complex<T>(distrib(rng),distrib(rng));
        }
    }

  private:
    boost::mt19937 rng;
  };

}

int main(int argc, char *argv[])
{
  if (argc != 11)
    {
      std::cerr << "Usage: " << argv[0] << " iterations sizex sizey tiletype tilesizestart tilesizeend tilesizestep pixeltype outputfileprefix resultfile\n";
      std::exit(1);
    }

  try
    {
      ome::common::setLogLevel(ome::logging::trivial::warning);

      int iterations = std::strtol(argv[1], nullptr, 10);
      unsigned int sizex = std::strtoul(argv[2], nullptr, 10);
      unsigned int sizey = std::strtoul(argv[3], nullptr, 10);
      TileType tiletype = (std::string("tile") == argv[4]) ? TILE : STRIP;
      unsigned int tilestart = std::strtoul(argv[5], nullptr, 10);
      unsigned int tileend = std::strtoul(argv[6], nullptr, 10);
      unsigned int tilestep = std::strtoul(argv[7], nullptr, 10);
      std::string pixeltype(argv[8]);
      std::string outfileprefix(argv[9]);
      boost::filesystem::path resultfile(argv[10]);

      RandomFillVisitor random_fill;

      std::ofstream results(resultfile.string().c_str());

      result_header(results);

      for(int i = 0; i < iterations; ++i)
        {
          for(unsigned int tilesize = tilestart;
              tilesize <= tileend;
              tilesize += tilestep)
            {
              unsigned int tilexsize, tileysize, tilexcount, tileycount;
              if (tiletype == STRIP)
                {
                  tilexsize = sizex;
                  tilexcount = 1;
                }
              else
                {
                  tilexsize = tilesize;
                  tilexcount = sizex / tilesize;
                  if (sizex % tilesize)
                    ++ tilexcount;
                }
              tileysize = tilesize;
              tileycount = sizey / tilesize;
              if (sizey % tilesize)
                ++ tileycount;

              std::ostringstream desc;
              desc << sizex << '-' << sizey << '-'
                   << (tiletype == TILE ? "tile" : "strip") << '-'
                   << tilexsize << '-' << tileysize << '-'
                   << pixeltype;

              VariantPixelBuffer buf(boost::extents[tilesize][tilesize][1][1][1][1][1][1][1],
                                     PixelType(pixeltype));
              // Fill with random data, to avoid the filesystem not
              // writing data blocks as an optimisation.
              boost::apply_visitor(random_fill, buf.vbuffer());


              boost::filesystem::path outfile(outfileprefix + '-' + desc.str() + ".tiff");
              boost::filesystem::remove(outfile);
              auto tiff = TIFF::open(outfile, "w8");
              auto ifd = tiff->getCurrentDirectory();
              ifd->setImageWidth(sizex);
              ifd->setImageHeight(sizex);
              ifd->setTileType(tiletype);
              ifd->setTileWidth(tilexsize);
              ifd->setTileHeight(tileysize);

              ifd->setPixelType(pixeltype);
              ifd->setBitsPerSample(ome::files::bitsPerPixel(pixeltype));
              ifd->setSamplesPerPixel(1);
              ifd->setPlanarConfiguration(CONTIG);
              ifd->setPhotometricInterpretation(MIN_IS_BLACK);

              timepoint write_start;

              for (unsigned int tilex = 0; tilex < tilexcount; ++tilex)
                {
                  unsigned int x = tilex * tilexsize;
                  unsigned int sx = tilexsize;
                  for (unsigned int tiley = 0; tiley < tileycount; ++tiley)
                    {
                      unsigned int y = tiley * tileysize;
                      unsigned int sy = tileysize;
                      ifd->writeImage(buf, x, y, sx, sy);
                    }
                }
              tiff->close();

              timepoint write_end;
              result(results, "pixeldata.write", desc.str(), write_start, write_end);

            }
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
