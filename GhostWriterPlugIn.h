//
//  GhostWriterPlugIn.h
//  GhostWriter
//
//  Created by jpld on 11 Mar 2010.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface GhostWriterPlugIn : QCPlugIn {}
@property (nonatomic, assign) id<QCPlugInInputImageSource> inputImage;
@property (nonatomic, assign) NSString* inputDestinationFilePath;
@property (nonatomic) BOOL inputWriteSignal;
@end
