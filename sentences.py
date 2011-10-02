#!/usr/bin/env python

# Processes and transforms Wikipedia article dumps into corpora
# suitable for Natural Language Processing.
#
# (c) Maciej Pacula 2011
#

import sys
import os
import numpy
import re
import xml.parsers.expat as sax
from optparse import OptionParser
from wiki import *
    
def fprint(x):
  print x

if __name__ == "__main__":
  try:
    parser = OptionParser(usage="usage: sentences.py [options] input-file")
    parser.add_option("--output",
                      action="store", type="string", dest="output",
                      help="file where to store the output sentences")
    (options, args) = parser.parse_args()

    if len(args) == 0:
      print parser.usage
      exit(1)
    elif len(args) > 1:
      print parser.usage
      exit(1)

    if options.output == None:
      print parser.usage
      exit(1)


    input_file_path = args[0]
    print "Extracting sentences..."
    parser = WikiParser(input_file_path, lambda a: fprint(a.title))
    parser.process()

    print "\nCleaning up..."
    parser.close()
    print "Done. Have fun!"
  except KeyboardInterrupt:
    print "\n\nCancelled. Partial results may have been generated."
    exit(1)
