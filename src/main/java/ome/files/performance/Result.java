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

import java.io.Writer;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.nio.file.Path;
import java.util.List;

class Result {
  private Writer writer;
  private PrintWriter output;

  Result(Path filename) throws java.io.IOException {
    writer = new FileWriter(filename.toString());
    output = new PrintWriter(writer);
    output.println("test.lang\ttest.name\ttest.file\treal\tproc.cpu\tproc.user\tproc.system");
  }

  void add(String testname,
           Path testfile,
           Timepoint start,
           Timepoint end) {
    output.println("Java\t" + testname + "\t" +
                   testfile.getFileName().toString() + "\t" +
                   (end.real-start.real)/1000000 + "\t" +
                   (end.cpu-start.cpu)/1000000 + "\t" +
                   (end.user-start.user)/1000000 + "\t" +
                   (end.system-start.system)/1000000);

  }

  void add(String testname,
           Path testfile,
           List<Timepoint> start,
           List<Timepoint> end) {
    long real = 0, cpu = 0, user = 0, system = 0;
    for(int i = 0; i < start.size(); i++) {
      real += (end.get(i).real-start.get(i).real);
      cpu += (end.get(i).cpu-start.get(i).cpu);
      user += (end.get(i).user-start.get(i).user);
      system += (end.get(i).system-start.get(i).system);
    }
    output.println("Java\t" + testname + "\t" +
                   testfile.getFileName().toString() + "\t" +
                   real/1000000 + "\t" +
                   cpu/1000000 + "\t" +
                   user/1000000 + "\t" +
                   system/1000000);

  }

  void close() {
    output.close();
  }
}
