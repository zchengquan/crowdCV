# -*- coding: utf-8 -*-
"""
  Prototype for Crowdsourced Offline Handwriting Recognition
  for Computer Vision under Assumption of Value, Aspiring Researchers Program, Spring 2015

The program is distributed under the terms of the GNU General Public License version 3
which can be found in the root directory and at http://www.gnu.org/licenses/gpl-3.0.txt

Copyright 2015 Ayush Sagar

Created on Mon Mar 02 00:55:07 2015
"""

def main():

    # input pre-processed image
    img = inputImage()


    # block/paragraph segmentation.
    blockList = segmentIntoBlocks(img)

    # take each block, read text and add recognized text
    i = 0    
    for blockDimensions in blockList:
        if isBlockNotSmall(block):
            blockImg = cropImage(blockDimensions, img)
            blockList[i].append(findTextInBlock(blockImg))
        else:
            blockList[i].append('')
        i += 1
    
        
def inputImage():
    pass

def segmentIntoBlocks(image):
    pass

def isBlockNotSmall():
    pass

def cropImage(blockDimensions, image):
    pass

def segmentIntoLines(BlockImage):
    pass

def findTextInBlock(BlockImage):
    pass

    
if __name__ == "__main__":
    main()    