#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import division

import os, sys
import optparse

import scipy as sp

import sys, os
import pylab as pl
import warnings

from matplotlib import artist
from matplotlib.artist import Artist, allow_rasterization
from matplotlib.patches import Rectangle
from matplotlib.cbook import is_string_like
from matplotlib.text import Text
from matplotlib.transforms import Bbox
from matplotlib.table import Table

# -----------------------------------------------------------------------------

DEFAULT_IMGSIZE = 32
DEFAULT_CROP = False

# -----------------------------------------------------------------------------
def mytable(ax, csize=0.04,
    cellText=None, cellColours=None,
    cellLoc='right', colWidths=None,
    rowLabels=None, rowColours=None, rowLoc='left',
    colLabels=None, colColours=None, colLoc='center',
    loc='bottom', bbox=None):
    # Check we have some cellText
    if cellText is None:
        # assume just colours are needed
        rows = len(cellColours)
        cols = len(cellColours[0])
        cellText = [[''] * rows] * cols

    rows = len(cellText)
    cols = len(cellText[0])
    for row in cellText:
        assert len(row) == cols

    if cellColours is not None:
        assert len(cellColours) == rows
        for row in cellColours:
            assert len(row) == cols
    else:
        cellColours = ['w' * cols] * rows

    # Set colwidths if not given
    if colWidths is None:
        colWidths = [1.0/cols] * cols

    # Check row and column labels
    rowLabelWidth = 0
    if rowLabels is None:
        if rowColours is not None:
            rowLabels = [''] * cols
            rowLabelWidth = colWidths[0]
    elif rowColours is None:
        rowColours = 'w' * rows

    if rowLabels is not None:
        assert len(rowLabels) == rows

    offset = 0
    if colLabels is None:
        if colColours is not None:
            colLabels = [''] * rows
            offset = 1
    elif colColours is None:
        colColours = 'w' * cols
        offset = 1

    if rowLabels is not None:
        assert len(rowLabels) == rows

    # Set up cell colours if not given
    if cellColours is None:
        cellColours = ['w' * cols] * rows

    # Now create the table
    table = Table(ax, loc, bbox)
    height = csize

    # Add the cells
    for row in xrange(rows):
        for col in xrange(cols):
            table.add_cell(row+offset, col,
                           width=height, height=height,
                           text=cellText[row][col],
                           facecolor=cellColours[row][col],
                           loc=cellLoc)
    ax.add_table(table)
    return table


# -----------------------------------------------------------------------------
def convert_image_to_table(in_fname,
                           out_fname,
                           imgsize = DEFAULT_IMGSIZE,
                           crop = DEFAULT_CROP,
                           ):

    if imgsize > 32:
        raise ValueError, "imgsize > 32 may not work"    
    
    arr = sp.misc.imread(in_fname).mean(2)
    arr = sp.misc.imresize(arr, (imgsize, imgsize))
    chars = [ ['%03d' % c for c in row] for row in arr]

    NN = len(row)
    C = NN
    csize = 1./NN + 0.004
    fig = pl.figure(figsize=(8,8))

    tab = mytable(pl.gca().get_axes(),
                  csize = csize,
                  cellText=chars,
                  loc='center',
                  )
    pl.axis('off')
    
    pl.savefig(out_fname)

    if crop:
        raise NotImplementedError
        

# -----------------------------------------------------------------------------
def main():
    
    usage = "usage: %prog [options] <in_fname> <out_fname>"
    parser = optparse.OptionParser(usage=usage)

    parser.add_option("--imgsize", "-s", 
                      metavar="INT", type="int",
                      default=DEFAULT_IMGSIZE,
                      help="resize image to [default=%default]")

    parser.add_option("--crop", "-c", 
                      metavar="BOOL", 
                      default = DEFAULT_CROP,
                      action = ["store_true", "store_false"][DEFAULT_CROP],
                      help="crop the output image [default=%default]")

    opts, args = parser.parse_args()

    if len(args) != 2:
        parser.print_help()
    else:
        in_fname = args[0]
        out_fname = args[1]

        convert_image_to_table(in_fname,
                               out_fname,
                               imgsize = opts.imgsize,
                               crop = opts.crop,
                               )
        
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    main()
