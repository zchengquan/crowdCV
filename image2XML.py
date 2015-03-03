#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
The program is distributed under the terms of the GNU General Public License version 3
which can be found in the root directory and at http://www.gnu.org/licenses/gpl-3.0.txt

Copyright 2015 Ayush Sagar

Created on Mon Mar 02 00:55:07 2015
"""

import os.path
import argparse
import cv2

# Command line argument parser
parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, \
description='\
-------------------------------------------------------\n\
Crowdsourced Offline Handwriting Recognition Prototype.\n\
-------------------------------------------------------\n\
Converts image into XML. Refer to readme for more information')
parser.add_argument('-i', dest='input', metavar='', help='\source file of type: bmp, jpg, jp2, png, pbm, pgm, ppm, sr, ras, tiff', required=True)
parser.add_argument('-o', dest='output', metavar='', help='destination XML file storing recognized text, images and formatting')
args = parser.parse_args()

def image2XML():
    '''Recognizes text in given image and outputs strings,
    unconverted segments and formatting data into an XML file.
    If an XML file is not specified, the output is printed in list form.'''

    # input pre-processed image
    image = inputImage()

    # block/paragraph segmentation.
    blockList = segmentIntoBlocks(image)
    
    # take each block in blockList, and add recognized text or base64 image data
    blockList = processBlockList(blockList, image)    
    
    #convert to XML and save output
    saveXML(blockList)
    return

def inputImage():
    '''Get image file and return an RGB image (BGR actually).
    Arguments:
        None
    Returns:
        an image, compund list with indexes [row][col][color][intensity]
        '''

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
    '''Takes an image and returns detected text blocks.
    Arguments:
        image -- compund list with indexes [row][col][color][intensity]
    Returns:
        list of tuple containing integer dimensions of bounding boxes:
        (left, top, width, height)'''

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
    '''Returns cropped input image according to given dimensions.
    Arguments:
        blockDimensions -- tuple containing integer block dimensions (left,top,width,height)
        image -- compund list with indexes [row][col][color][intensity]
    Returns:
        an image, compund list with indexes [row][col][color][intensity]'''

    x = blockDimensions[0]
    y = blockDimensions[1]
    w = blockDimensions[2]
    h = blockDimensions[3]

    # return sliced image
    return image[y : y + h, x : x + w]

def processBlockList(blockList, image):
    '''Take each block in blockList, and add recognized text or base64 image data.
    Arguments:
        blockList -- list of tuple containing integer block dimensions (left, top, width, height)
        image -- compund list with indexes [row][col][color][intensity]
    Returns:
        blockList, compund list containing two tuples [[(left,top,width,height),(isImage, data)], ... ]'''
                
    for i in range(len(blockList)):
        # save each block list tuple
        blockDimensions = blockList[i]

        # reformat blockList item to contain block data
        blockList[i] = [blockDimensions, processBlock(blockList[i], image)]

    return blockList

def processBlock(blockDimensions, image):
    '''Recognizes text in given area of image and returns a tuple (isImage, data)
    where isImage = True, if base64 image is present in data and,
    isImage = False if data is text. data[string] is recognized text or base64 image,
    depending on processing result
    Arguments:
        blockDimensions -- tuple containing integers (left,top,width,height)
        image -- compund list with indexes [row][col][color][intensity]
    Output:
        tuple (isImage boolean, data) where isImage is boolean and data is string'''

    #return test values
    dataDict = {(290, 23, 164, 124): (True, r"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") , \
    (547, 82, 131, 35): (False, "11.23.99"), \
    (78, 135, 103, 37): (False, "alan,"), \
    (64, 210, 634, 258): (False, "I understand that you have volunteered for my campaign. I am grateful to have you on my team"), \
    (48, 477, 604, 287): (False, "Your state is very important to winning back the White House. I am working hard to build a strong grassroot aggregation to carry MI."), \
    (38, 776, 622, 156): (False, "I hope you will continue working hard. Together I am confident we will win."), \
    (394, 909, 262, 85): (True, r"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"), \
    (170, 944, 165, 49): (False, "Sincerely,")}

    return dataDict[blockDimensions]

def saveXML(blockList):
    '''output blockList to XML file
    Arguments:
        blockList -- compund list containing two tuples [[(left,top,width,height),(isImage, data)], ... ]
    Returns:
        None'''

    global args

    #read 2nd command line argument
    fileName = args.output
    if fileName == None:
        print blockList
        return

    #create or overwrite output file
    try:
        outputFile = open(fileName, 'w')

    except IOError as e:
        print "I/O error({0}): {1}\nCannot create and open file:{2}".format(e.errno, e.strerror, e.filename)

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
    '''Send given image and bouding boxes to humans to verify and return with
    changes if required.
    Arguments:
        image -- compund list with indexes [row][col][color][intensity]
        blocks -- list of tuple containing integers (left, top, width, height)
    Output:
        list of tuple containing integers (left, top, width, height)'''

    # returning test value for now
    return [(290, 23, 164, 124), (547, 82, 131, 35), (78, 135, 103, 37), (64, 210, 634, 258), (48, 477, 604, 287), (38, 776, 622, 156), (394, 909, 262, 85), (170, 944, 165, 49)]

def getBlocksByCV(image):
    '''Compute bouding boxes around suspected text blocks in input image
    Arguments:
        image -- compund list with indexes [row][col][color][intensity]
    Output:
        list of tuple containing integer block dimensions (left, top, width, height)'''

    # returning test value for now
    return [(290, 23, 164, 124), (547, 82, 131, 35), (78, 135, 103, 37), (64, 210, 634, 258), (48, 477, 604, 287), (38, 776, 622, 156), (394, 909, 262, 85), (170, 944, 165, 49)]

if __name__ == "__main__":
    image2XML()