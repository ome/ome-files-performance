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

#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iterator>
#include <limits>
#include <memory>
#include <random>
#include <sstream>
#include <vector>

#include <boost/filesystem.hpp>

#include <boost/random/normal_distribution.hpp>
#include <boost/random/uniform_01.hpp>
#include <boost/random.hpp>

#include <ome/compat/array.h>
#include <ome/common/log.h>

#include <ome/files/tiff/TIFF.h>
#include <ome/files/tiff/IFD.h>
#include <ome/files/PixelProperties.h>
#include <ome/files/VariantPixelBuffer.h>

using namespace ome::files::tiff;
using ome::files::PixelBuffer;
using ome::files::PixelProperties;
using ome::files::VariantPixelBuffer;
using ome::xml::model::enums::PixelType;

namespace
{

  struct RandomFillVisitor : public boost::static_visitor<>
  {
    RandomFillVisitor():
      rng(9343)
    {
    }

    template<typename T>
    typename boost::enable_if_c<
      boost::is_integral<T>::value, void
      >::type
    operator() (std::shared_ptr<PixelBuffer<T>>& buffer)
    {
      boost::random::uniform_int_distribution<T> distrib
        (std::numeric_limits<T>::min(), std::numeric_limits<T>::max() - 1);
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
      boost::random::uniform_real_distribution<T> distrib(0, 1);

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
      boost::random::uniform_real_distribution<T> distrib(0, 1);

      typename PixelBuffer<std::complex<T>>::value_type *data = buffer->data();
      for(typename PixelBuffer<std::complex<T>>::size_type i = 0;
          i < buffer->num_elements();
          ++i)
        {
          data[i] = std::complex<T>(distrib(rng),distrib(rng));
        }
    }

    void
    operator() (std::shared_ptr<PixelBuffer<PixelProperties<PixelType::BIT>::std_type>>& buffer)
    {
      boost::random::uniform_01<boost::mt19937> distrib(rng);

      typename PixelBuffer<PixelProperties<::ome::xml::model::enums::PixelType::BIT>::std_type>::value_type *data = buffer->data();
      for(typename PixelBuffer<PixelProperties<::ome::xml::model::enums::PixelType::BIT>::std_type>::size_type i = 0;
          i < buffer->num_elements();
          ++i)
        {
          data[i] = distrib();
        }
    }

  private:
    boost::mt19937 rng;
  };

  struct test_data
  {
    int iteration;
    PixelType pixeltype;
    TileType tiletype;
    unsigned int sizex;
    unsigned int sizey;
    unsigned int tilexsize;
    unsigned int tileysize;
    unsigned int tilexcount;
    unsigned int tileycount;
  };

  void
  run_tests(const std::vector<test_data>& tests,
            const std::string& outfileprefix,
            const boost::filesystem::path& resultfile,
            const boost::filesystem::path& sizefile)
  {
    RandomFillVisitor random_fill;

    std::ofstream results(resultfile.string().c_str());
    std::ofstream sizes(sizefile.string().c_str());

    result_header(results);
    extra_result_header(sizes, {{"filesize"}});

    for (const auto& t : tests)
      {

        std::ostringstream desc;
        desc << t.sizex << '-' << t.sizey << '-'
             << (t.tiletype == TILE ? "tile" : "strip") << '-'
             << t.tilexsize << '-' << t.tileysize << '-'
             << t.pixeltype;
        std::cout << "TEST: [" << t.iteration << "] " << desc.str() << std::endl;

        VariantPixelBuffer buf(boost::extents[t.tilexsize][t.tileysize][1][1][1][1][1][1][1],
                               t.pixeltype);
        // Fill with random data, to avoid the filesystem not writing
        // (or compressing) empty data blocks as an optimisation.
        boost::apply_visitor(random_fill, buf.vbuffer());

        boost::filesystem::path outfile(outfileprefix + '-' + desc.str() + ".tiff");
        boost::filesystem::remove(outfile);
        auto tiff = TIFF::open(outfile, "w8");
        auto ifd = tiff->getCurrentDirectory();
        ifd->setImageWidth(t.sizex);
        ifd->setImageHeight(t.sizex);
        ifd->setTileType(t.tiletype);
        ifd->setTileWidth(t.tilexsize);
        ifd->setTileHeight(t.tileysize);

        ifd->setPixelType(t.pixeltype);
        ifd->setBitsPerSample(ome::files::bitsPerPixel(t.pixeltype));
        ifd->setSamplesPerPixel(1);
        ifd->setPlanarConfiguration(CONTIG);
        ifd->setPhotometricInterpretation(MIN_IS_BLACK);

        timepoint write_start;

        for (unsigned int tilex = 0; tilex < t.tilexcount; ++tilex)
          {
            unsigned int x = tilex * t.tilexsize;
            unsigned int sx = t.tilexsize;
            for (unsigned int tiley = 0; tiley < t.tileycount; ++tiley)
              {
                unsigned int y = tiley * t.tileysize;
                unsigned int sy = t.tileysize;
                ifd->writeImage(buf, x, y, sx, sy);
              }
          }
        tiff->close();

        timepoint write_end;
        result(results, "pixeldata.write", desc.str(), write_start, write_end);
        extra_result(sizes, "pixeldata.write", desc.str(), boost::filesystem::file_size(outfile));
      }
  }

}

int main(int argc, char *argv[])
{
  if (argc != 12)
    {
      std::cerr << "Usage: " << argv[0] << " iterations sizex sizey tiletype tilesizestart tilesizeend tilesizestep pixeltype outputfileprefix resultfile sizefile\n";
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
      boost::filesystem::path sizefile(argv[11]);

      std::vector<test_data> tests;
      std::vector<test_data> unique_tests;
      for(unsigned int tilesize = tilestart;
          tilesize <= tileend;
          tilesize += tilestep)
        {
          test_data t {0, {pixeltype}, tiletype, sizex, sizey, 0, 0, 0, 0};

          if (t.tiletype == STRIP)
            {
              t.tilexsize = sizex;
              t.tilexcount = 1;
            }
          else
            {
              t.tilexsize = tilesize;
              t.tilexcount = t.sizex / tilesize;
              if (t.sizex % tilesize)
                ++ t.tilexcount;
            }
          t.tileysize = tilesize;
          t.tileycount = t.sizey / tilesize;
          if (t.sizey % tilesize)
            ++ t.tileycount;

          unique_tests.push_back(t);
        }

      for(int i = 0; i < iterations; ++i)
        {
          // Randomise test order.
          std::random_device rd;
          std::mt19937 g(rd());
          std::shuffle(unique_tests.begin(), unique_tests.end(), g);
          for (auto& t : unique_tests)
            t.iteration = i;
          tests.insert(tests.end(), unique_tests.begin(), unique_tests.end());
        }

      run_tests(tests, outfileprefix, resultfile, sizefile);
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
