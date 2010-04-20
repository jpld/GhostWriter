//
//  GhostWriterPlugIn.m
//  GhostWriter
//
//  Created by jpld on 11 Mar 2010.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "GhostWriterPlugIn.h"

#if CONFIGURATION == DEBUG
    #define GWDebugLogSelector() NSLog(@"-[%@ %@]", /*NSStringFromClass([self class])*/self, NSStringFromSelector(_cmd))
    #define GWDebugLog(a...) NSLog(a)
#else
    #define GWDebugLogSelector()
    #define GWDebugLog(a...)
#endif

#define GWLocalizedString(key, comment) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:(nil)]


// WORKAROUND - naming violation for cocoa memory management
@interface QCPlugIn(GhostWriterAdditions)
- (QCPlugInViewController*)createViewController NS_RETURNS_RETAINED;
@end


@interface GhostWriterPlugIn()
- (BOOL)_saveImage;
@end

@implementation GhostWriterPlugIn

@dynamic inputImage, inputDestinationFilePath, inputWriteSignal;

+ (NSDictionary*)attributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:GWLocalizedString(@"kQCPlugIn_Name", NULL), QCPlugInAttributeNameKey, GWLocalizedString(@"kQCPlugIn_Description", NULL), QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    // TODO - localize?
    if ([key isEqualToString:@"inputImage"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
    else if ([key isEqualToString:@"inputDestinationFilePath"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Destination File Path", QCPortAttributeNameKey, @"~/Desktop/ghost.png", QCPortAttributeDefaultValueKey, nil];
    else if ([key isEqualToString:@"inputWriteSignal"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Write Signal", QCPortAttributeNameKey, nil];
    return nil;
}

+ (QCPlugInExecutionMode)executionMode {
    return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode)timeMode {
    return kQCPlugInTimeModeNone;
}

+ (NSArray*)plugInKeys {
    /*
    Return a list of the KVC keys corresponding to the internal settings of the plug-in.
    */

    return nil;
}

#pragma mark -

- (id)init {
    self = [super init];
    if (self) {
    }	
    return self;
}

- (void)finalize {
    [super finalize];
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -

- (id)serializedValueForKey:(NSString*)key {
    /*
    Provide custom serialization for the plug-in internal settings that are not values complying to the <NSCoding> protocol.
    The return object must be nil or a PList compatible i.e. NSString, NSNumber, NSDate, NSData, NSArray or NSDictionary.
    */

    GWDebugLogSelector();

    return [super serializedValueForKey:key];
}

- (void)setSerializedValue:(id)serializedValue forKey:(NSString*)key {
    /*
    Provide deserialization for the plug-in internal settings that were custom serialized in -serializedValueForKey.
    Deserialize the value, then call [self setValue:value forKey:key] to set the corresponding internal setting of the plug-in instance to that deserialized value.
    */

    GWDebugLogSelector();

    [super setSerializedValue:serializedValue forKey:key];
}

- (QCPlugInViewController*)createViewController {
    /*
    Return a new QCPlugInViewController to edit the internal settings of this plug-in instance.
    You can return a subclass of QCPlugInViewController if necessary.
    */

    GWDebugLogSelector();

    return [[QCPlugInViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

#pragma mark -
#pragma mark EXECUTION

- (BOOL)startExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
    Return NO in case of fatal failure (this will prevent rendering of the composition to start).
    */

    GWDebugLogSelector();

    return YES;
}

- (void)enableExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
    */

    GWDebugLogSelector();
}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
    // bail if we don't have an input
    if (!self.inputImage)
        return YES;

    // only process input on the rising edge
    if (!([self didValueForInputKeyChange:@"inputWriteSignal"] && self.inputWriteSignal))
        return YES;

    GWDebugLogSelector();

    [self _saveImage];

    return YES;
}

- (void)disableExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
    */

    GWDebugLogSelector();
}

- (void)stopExecution:(id<QCPlugInContext>)context {
    /*
    Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
    */

    GWDebugLogSelector();
}

#pragma mark -
#pragma mark PRIVATE

- (BOOL)_saveImage {
    BOOL status = YES;

    // divine pixel format from colorspace
    CGColorSpaceRef colorSpace = [self.inputImage imageColorSpace];
    NSString* pixelFormat = nil;
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
        pixelFormat = QCPlugInPixelFormatI8;
    else if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB)
#if __BIG_ENDIAN__
        pixelFormat = QCPlugInPixelFormatARGB8;
#else
        pixelFormat = QCPlugInPixelFormatBGRA8;
#endif

    if (!pixelFormat) {
        CFStringRef colorSpaceName = CGColorSpaceCopyName(colorSpace);
        NSLog(@"ERROR - unable to divine pixel format for color space '%@', image input not saved", colorSpaceName);
        CFRelease(colorSpaceName);
        return NO;
    }

    // create in-memory buffer of input image
    if (![self.inputImage lockBufferRepresentationWithPixelFormat:pixelFormat colorSpace:colorSpace forBounds:[self.inputImage imageBounds]]) {
        CFStringRef colorSpaceName = CGColorSpaceCopyName(colorSpace);
        NSLog(@"ERROR - unable to craete memory buffer representation of input image with pixelFormat '%@' and color space '%@'", pixelFormat, colorSpaceName);
        CFRelease(colorSpaceName);
        return NO;
    }

    // create CGImage from buffer
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, [self.inputImage bufferBaseAddress], [self.inputImage bufferPixelsHigh]*[self.inputImage bufferBytesPerRow], NULL);
    CGImageRef image = CGImageCreate([self.inputImage bufferPixelsWide], [self.inputImage bufferPixelsHigh], 8, (pixelFormat == QCPlugInPixelFormatI8 ? 8 : 32), [self.inputImage bufferBytesPerRow], colorSpace, (pixelFormat == QCPlugInPixelFormatI8 ? 0 : kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host), dataProvider, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    if (!image) {
        NSLog(@"ERROR - filed to create CGImage from input image memory buffer provider");
        status = NO;
        goto cleanup;
    }

    // figure out the save location
    NSString* filePath = [self.inputDestinationFilePath stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        GWDebugLog(@"file at path '%@' already exists, will overwrite", filePath);
    }

    // divine image type from file extension, defaults to PNG
    NSString* extension = [[filePath pathExtension] lowercaseString];
    CFStringRef imageType = NULL;
    if ([extension isEqualToString:@"png"])
        imageType = kUTTypePNG;
    else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"])
        imageType = kUTTypeJPEG;
    else if ([extension isEqualToString:@"tif"] || [extension isEqualToString:@"tiff"])
        imageType = kUTTypeTIFF;
    else {
        if (![extension isEqualToString:@""])
            NSLog(@"ERROR - unable to divine image type from file extension '%@', defaulting to PNG", extension);
        filePath = [NSString stringWithFormat:@"%@.png", filePath];
        imageType = kUTTypePNG;
    }
    NSURL* fileURL = [NSURL fileURLWithPath:filePath];

    // create image destination and write it to disk
    CGImageDestinationRef imageDestimation = CGImageDestinationCreateWithURL((CFURLRef)fileURL, imageType, 1, NULL);
    if (!imageDestimation) {
        NSLog(@"ERROR - failed to craete image destination with URL '%@'", fileURL);
        status = NO;
        goto cleanup;
    }
    CGImageDestinationAddImage(imageDestimation, image, NULL);
    GWDebugLog(@"saving file at URL '%@'", fileURL);
    status = CGImageDestinationFinalize(imageDestimation);
    CFRelease(imageDestimation);

cleanup:
    CGImageRelease(image);

    [self.inputImage unlockBufferRepresentation];

    return status;
}

@end
