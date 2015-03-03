# -*- coding: utf-8 -*-
"""
  Prototype for Crowdsourced Offline Handwriting Recognition
  for Computer Vision under Assumption of Value, Aspiring Researchers Program, Spring 2015

The program is distributed under the terms of the GNU General Public License version 3
which can be found in the root directory and at http://www.gnu.org/licenses/gpl-3.0.txt

Copyright 2015 Ayush Sagar

Created on Mon Mar 02 00:55:07 2015
"""

import os
import argparse
import cv2

parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, \
                                description='-------------------------------------------------------\nCrowdsourced Offline Handwriting Recognition Prototype.\n-------------------------------------------------------\nConverts image into XML. Refer to readme for more information')
parser.add_argument('-i', dest='input', metavar='', help='source file of type: bmp, jpg, jp2, png, pbm, pgm, ppm, sr, ras, tiff', required=True)
parser.add_argument('-o', dest='output', metavar='', help='destination XML file storing recognized text, images and formatting')
args = parser.parse_args()


def image2XML():

    # input pre-processed image
    image = inputImage()

    # block/paragraph segmentation.
    blockList = segmentIntoBlocks(image)

    # take each block, and process to add recognized text or base64 image data
    for i in range(len(blockList)):
            # save each block list tuple
            blockDimensions = blockList[i]

            # reformat blockList item to contain block data
            blockList[i] = [blockDimensions, processBlock(blockList[i], image)]

    #convert to XML and save output
    saveXML(blockList)

    return

def inputImage():
    '''Get image file and return an RGB image (BGR actually).'''
    global args    
    
    #read 1st command line argument
    fileName = args.input
    
    if(os.path.isfile(fileName)):
        try:
            image = cv2.imread(fileName)
        except Exception as e:
            print e
        else:
            return image
    else:
        raise IOError('file not found')
        
def segmentIntoBlocks(image):
    '''Takes an image and returns a list of detected text blocks:
    e.g. [[left1, top1, width1, height1], [left2, top2, width2, height2], ...]'''

    # Apply segmentation on the image and get dimensions of each block
    blocks = getBlocksByCV(image)

    # Update blocks by sending to Human
    try:
        blocks = getBlocksByHPU(image, blocks)

    except Exception as e:
        print e
 
   # Return updated block
    return blocks

def cropImage(blockDimensions, image):
    '''Returns cropped input image according to given dimensions.'''
    x = blockDimensions[0]
    y = blockDimensions[1]
    w = blockDimensions[2]
    h = blockDimensions[3]

    # return sliced image
    return image[y : y + h, x : x + w]

def segmentIntoLines(blockDimensions):
    return

def processBlock(blockDimensions, image):
    #return test values
    dataDict = {(290, 23, 164, 124): (True, "imagedata") , (547, 82, 131, 35): (False, "11.23.99"), (78, 135, 103, 37): (False, "alan,"), (64, 210, 634, 258): (False, "I understand that you have volunteered for my campaign. I am grateful to have you on my team"), (48, 477, 604, 287): (False, "Your state is very important to winning back the White House. I am working hard to build a Strong grassroots <unitelligible> to carry MI."), (38, 776, 622, 156): (False, "I hope you will continue working hard. Together I am confident we will win."), (394, 909, 262, 85): (True, "image"), (170, 944, 165, 49): (False, "Sincerely,")}

    return dataDict[blockDimensions]

def saveXML(blockList):
    '''output to XML file'''
    global args
    #read 2nd command line argument
    fileName = args.output

    if fileName == None:
        print blockList
        return

    try:
        outputFile = open(fileName, 'w')

    except Exception as e:
        print e
    
    #begin writing XML
    else:
        outputFile.write('<?xml version="1.0"?>\n')

        for i in range(len(blockList)):
            left = str(blockList[i][0][0])
            top = str(blockList[i][0][1])
            width = str(blockList[i][0][2])
            height = str(blockList[i][0][3])
            isImage = str(blockList[i][1][0])
            data = blockList[i][1][1]

            outputFile.write(
            '<block index="' + str(i) + \
            '" left="' + left + \
            '" top="' + top + \
            '" width="' + width + \
            '" height="' + height + \
            '" isImage="' + isImage + \
            '" data="' + data + \
            '"/>\n')

        outputFile.close()

def getBlocksByHPU(image, blocks):
    # returning test value for now    
    return [(290, 23, 164, 124), (547, 82, 131, 35), (78, 135, 103, 37), (64, 210, 634, 258), (48, 477, 604, 287), (38, 776, 622, 156), (394, 909, 262, 85), (170, 944, 165, 49)]

def getBlocksByCV(image):
    ''' Return a list of bouding boxes around text blocks in input image '''
    # returning test value for now    
    return [(290, 23, 164, 124), (547, 82, 131, 35), (78, 135, 103, 37), (64, 210, 634, 258), (48, 477, 604, 287), (38, 776, 622, 156), (394, 909, 262, 85), (170, 944, 165, 49)]

if __name__ == "__main__":
    image2XML()