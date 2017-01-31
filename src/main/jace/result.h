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

#pragma once

#include <boost/chrono/process_cpu_clocks.hpp>
#include <boost/chrono/system_clocks.hpp>
#include <boost/chrono/thread_clock.hpp>

#ifndef BOOST_CHRONO_HAS_PROCESS_CLOCKS
#error Process clocks are required for profiling
#endif

typedef boost::chrono::duration<boost::chrono::process_times<boost::chrono::milliseconds::rep>, boost::milli> cpu_clock_milliseconds;

#include <boost/filesystem/path.hpp>

/**
 * The various time measurements being recorded.  This is used to
 * record a single point in time; the difference between two
 * timepoints will give the time duration a test took to run.
 */
struct timepoint
{
timepoint():
  system(boost::chrono::high_resolution_clock::now()),
    thread(boost::chrono::thread_clock::now()),
    process(boost::chrono::process_cpu_clock::now())
  {}

  boost::chrono::high_resolution_clock::time_point system;
  boost::chrono::thread_clock::time_point thread;
  boost::chrono::process_cpu_clock::time_point process;
};

/**
 * Output TSV header.
 *
 * @param os the stream to use.
 */
void
result_header(std::ostream& os);

/**
 * Output TSV test result.
 *
 * The time duration for each recorded timepoint will be output with
 * millisecond precision.
 *
 * @param os the stream to use.
 * @param testname the name of the test.
 * @param testfile the input filename of the test data.
 * @param start the start timepoint.
 * @param end the end timepoint.
 */
void
result(std::ostream& os,
       const std::string& testname,
       const boost::filesystem::path& testfile,
       const timepoint& start,
       const timepoint& end);

/*
 * Local Variables:
 * mode:C++
 * End:
 */
