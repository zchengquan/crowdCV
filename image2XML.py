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
    '''Get image file and return an RGB image (BGR actually).

    Arguments:
        None
    Returns:
        image, compund list with indexes [row][col][color][intensity]
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
        image, compund list with indexes [row][col][color][intensity]
    Output:
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
        image, compund list with indexes [row][col][color][intensity]
    Returns:
        image, compund list with indexes [row][col][color][intensity]'''
        
    x = blockDimensions[0]
    y = blockDimensions[1]
    w = blockDimensions[2]
    h = blockDimensions[3]

    # return sliced image
    return image[y : y + h, x : x + w]

def processBlock(blockDimensions, image):
    '''Recognizes text in given area of image and returns a tuple (isImage, data)
    where isImage[boolean] = True, if base64 image is present in data and,
    isImage = False if data is text. data[string] is recognized text or base64 image, 
    depending on processing result

    Arguments: 
        blockDimensions: tuple containing integers (left,top,width,height)
        image: compund list with indexes [row][col][color][intensity]
    Output: 
        tuple (isImage boolean, data) where isImage is boolean and data is string'''

    #return test values
    dataDict = {(290, 23, 164, 124): (True, "imagedata") , (547, 82, 131, 35): (False, "11.23.99"), (78, 135, 103, 37): (False, "alan,"), (64, 210, 634, 258): (False, "I understand that you have volunteered for my campaign. I am grateful to have you on my team"), (48, 477, 604, 287): (False, "Your state is very important to winning back the White House. I am working hard to build a strong grassroot aggregation to carry MI."), (38, 776, 622, 156): (False, "I hope you will continue working hard. Together I am confident we will win."), (394, 909, 262, 85): (True, "image"), (170, 944, 165, 49): (False, "Sincerely,")}
    return dataDict[blockDimensions]

def saveXML(blockList):
    '''output blockList to XML file

    Arguments:
        blockList: compund list containing two tuples:
        [[(left,top,width,height),(isImage, data)], ... ]
    Returns:None'''
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
        image, compund list with indexes [row][col][color][intensity]
        blocks, list of tuple containing integers (left, top, width, height)
    Output: 
        list of tuple containing integers (left, top, width, height)'''

    # returning test value for now
    return [(290, 23, 164, 124), (547, 82, 131, 35), (78, 135, 103, 37), (64, 210, 634, 258), (48, 477, 604, 287), (38, 776, 622, 156), (394, 909, 262, 85), (170, 944, 165, 49)]

def getBlocksByCV(image):
    '''Compute bouding boxes around suspected text blocks in input image

    Arguments:
        image, compund list with indexes [row][col][color][intensity]
    Output: 
        list of tuple containing integer dimensions (left, top, width, height)'''

    # returning test value for now
    return [(290, 23, 164, 124), (547, 82, 131, 35), (78, 135, 103, 37), (64, 210, 634, 258), (48, 477, 604, 287), (38, 776, 622, 156), (394, 909, 262, 85), (170, 944, 165, 49)]

if __name__ == "__main__":
    image2XML()