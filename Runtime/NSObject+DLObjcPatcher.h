//
//  NSObject+DLObjcPatcher.h
//  Runtime
//
//  Created by Denis Lebedev on 2/26/13.
//  Copyright (c) 2013 Denis Lebedev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DLVoidBlock)(void);

@interface NSObject (DLObjcPatcher)

+ (void)complementMethod:(SEL)selector byCalling:(DLVoidBlock)block;

@end
