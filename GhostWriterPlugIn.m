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
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Destination File Path", QCPortAttributeNameKey, nil];
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

	return [super serializedValueForKey:key];
}

- (void)setSerializedValue:(id)serializedValue forKey:(NSString*)key {
	/*
	Provide deserialization for the plug-in internal settings that were custom serialized in -serializedValueForKey.
	Deserialize the value, then call [self setValue:value forKey:key] to set the corresponding internal setting of the plug-in instance to that deserialized value.
	*/

	[super setSerializedValue:serializedValue forKey:key];
}

- (QCPlugInViewController*)createViewController {
	/*
	Return a new QCPlugInViewController to edit the internal settings of this plug-in instance.
	You can return a subclass of QCPlugInViewController if necessary.
	*/

	return [[QCPlugInViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

#pragma mark -
#pragma mark EXECUTION

- (BOOL)startExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	*/

	return YES;
}

- (void)enableExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	*/
}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
    // only process input on the rising edge
    if (![self didValueForInputKeyChange:@"inputWriteSignal"])
        return YES;

    // TODO - actually do something

	return YES;
}

- (void)disableExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	*/
}

- (void)stopExecution:(id<QCPlugInContext>)context {
	/*
	Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	*/
}

@end
