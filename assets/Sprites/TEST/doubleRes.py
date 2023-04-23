import cv2, os
import numpy as np


def blowItUp(imgName, size):
    img = cv2.imread(imgName, cv2.IMREAD_UNCHANGED)
    newImg = np.zeros((len(img)*size, len(img[0])*size, 4), np.uint8)
    for row in range(len(newImg)):
        for col in range(len(newImg[0])):
            newImg[row][col] = img[row//size][col//size]
    cv2.imwrite(imgName[:-7] + '.png', newImg)  


if __name__ == '__main__':
    size = 0
    while size not in range(1,6):
        sizeInp = input('Resolution Multiplier (1-5): ')
        if sizeInp in ['1', '2', '3', '4', '5']:
            size = int(sizeInp)
    
    for img in os.listdir():
        if img[-4:] == '.png':
            blowItUp(img, size)