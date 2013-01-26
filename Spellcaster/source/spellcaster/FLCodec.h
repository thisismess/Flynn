// 
// Copyright 2013 Mess, All rights reserved.
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// 
// Made by Mess - http://thisismess.com/
// 

/**
 * The codec version. This should be an NSNumber.
 */
#define kFLCodecVersionKey @"FLCodecVersion"

/**
 * The block size to use for encoding. This should be an NSNumber.
 */
#define kFLCodecBlockSizeKey @"FLCodecBlockSize"

/**
 * The maximum image size to use for encoding. This should be an NSNumber.
 */
#define kFLCodecImageSizeKey @"FLCodecImageSize"

/**
 * The format encoded images should be produced in. This should be a UTI string, only JPEG and PNG are supported.
 */
#define kFLCodecImageFormatKey @"FLCodecImageFormat"

/**
 * The maximum number of pixel discrepencies between two blocks before a block is updated. This should be an NSNumber.
 */
#define kFLCodecBlockPixelDiscrepancyThresholdKey @"FLCodecBlockPixelDiscrepancyThreshold"

/**
 * Validate settings
 */
BOOL FLCodecSettingsValid(NSDictionary *settings, NSError **error);

