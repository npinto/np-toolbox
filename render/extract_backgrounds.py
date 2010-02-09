#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import optparse
import hashlib
import scipy as sp
from scipy.misc import imread, imsave, imresize
from npprogressbar import *

# -----------------------------------------------------------------------------
DEFAULT_OUTPUT_DIR = "./out"
DEFAULT_EXTRACT_WIDTH = 400
DEFAULT_EXTRACT_HEIGHT = 400
DEFAULT_OUTPUT_WIDTH = 150
DEFAULT_OUTPUT_HEIGHT = 150
#DEFAULT_ROT_RANGE = 30
DEFAULT_COLOR = False
DEFAULT_NIMAGES = 1

SIZE_EPSILON = .2

# -----------------------------------------------------------------------------
widgets = [RotatingMarker(), " Progress: ", Percentage(), " ",
           #" (", FilenameUpdate(fnames), ") ", ETA()]           
           Bar(left='[',right=']'), ' ', ETA()]

# -----------------------------------------------------------------------------
def extract_backgrounds(
    input_filenames,    
    # --
    output_dir = DEFAULT_OUTPUT_DIR,
    # --    
    extract_width = DEFAULT_EXTRACT_WIDTH,
    extract_height = DEFAULT_EXTRACT_HEIGHT,
    output_width = DEFAULT_OUTPUT_WIDTH,
    output_height = DEFAULT_OUTPUT_HEIGHT,
    # --
    #rot_range = DEFAULT_ROT_RANGE,
    # --
    nimages = DEFAULT_NIMAGES,
    # color = DEFAULT_COLOR,
    ):

    assert os.path.isdir(output_dir)

    print "Number of input files:", len(input_filenames)
    print "Number of output files:", nimages


    pbar = ProgressBar(widgets=widgets, maxval=nimages)
    pbar.start()
    for n in xrange(nimages):
        # 1. select a random (valid) image 
        done = False
        while not done:
            fname = input_filenames[sp.random.randint(len(input_filenames))]
            arr_in = sp.atleast_3d(imread(fname))
            arr_h, arr_w = shap = arr_in.shape[:2]
            if (sp.array([extract_height, extract_width])*(1.+SIZE_EPSILON)
                <= shap).all():
                done = True
                arr_in = arr_in.mean(2)
                
        # 2. select a random (valid) position
        posx = sp.random.randint(arr_w-extract_width)
        posy = sp.random.randint(arr_h-extract_height)

        # 3. extract the patch
        arr_out = arr_in[posy:posy+extract_height, posx:posx+extract_width]
        assert arr_out.shape == (extract_height, extract_width)

        # 4. resize the image
        arr_out = imresize(arr_out, (output_height, output_width))
        assert arr_out.shape == (output_height, output_width)

        # 5. normalize
        arr_out = arr_out.astype('float32')
        arr_out -= arr_out.mean()
        arr_out_std = arr_out.std()
        assert arr_out_std != 0
        arr_out /= arr_out_std

        # 6. save output
        sha = hashlib.sha1(arr_out.tostring()).hexdigest()
        output_filename = os.path.join(output_dir, "%s.png" % sha)
        imsave(output_filename, arr_out)

        pbar.update(n+1)

    pbar.finish()
    



# -----------------------------------------------------------------------------
def main():
    
    usage = "usage: %prog [options] <image1.ext> <image2.ext> ..."
    parser = optparse.OptionParser(usage=usage)

    parser.add_option("--output_dir", "-o", 
                      metavar="STR", type="str",
                      default=DEFAULT_OUTPUT_DIR,
                      help="[default=%default]")

    parser.add_option("--extract_width",
                      metavar="INT", type="int",
                      default=DEFAULT_EXTRACT_WIDTH,
                      help="[default=%default]")

    parser.add_option("--extract_height",
                      metavar="INT", type="int",
                      default=DEFAULT_EXTRACT_HEIGHT,
                      help="[default=%default]")

    parser.add_option("--output_width",
                      metavar="INT", type="int",
                      default=DEFAULT_OUTPUT_WIDTH,
                      help="[default=%default]")

    parser.add_option("--output_height",
                      metavar="INT", type="int",
                      default=DEFAULT_OUTPUT_HEIGHT,
                      help="[default=%default]")

#     parser.add_option("--rot_range", 
#                       metavar="FLOAT", type="float",
#                       default=DEFAULT_ROT_RANGE,
#                       help="[default=%default]")

    parser.add_option("--nimages", "-n", 
                      metavar="INT", type="int",
                      default=DEFAULT_NIMAGES,
                      help="[default=%default]")

    opts, args = parser.parse_args()

    if len(args) < 1:
        parser.print_help()
    else:
        input_filenames = args
        
        extract_backgrounds(
            input_filenames,
            # --
            output_dir = opts.output_dir,
            # --    
            extract_width = opts.extract_width,
            extract_height = opts.extract_height,
            output_width = opts.output_width,
            output_height = opts.output_height,
            # --
            #rot_range = opts.rot_range,
            # --            
            nimages = opts.nimages,            
            )

# -----------------------------------------------------------------------------
if __name__ == "__main__":
    main()
