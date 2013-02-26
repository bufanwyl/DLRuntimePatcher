//
//  NSObject+DLObjcPatcher.h
//  Runtime
//
//  Created by Denis Lebedev on 2/26/13.
//  Copyright (c) 2013 Denis Lebedev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DLVoidBlock)(void);
typedef void (^DLSelectorBlock)(SEL selector);

@interface NSObject (DLObjcPatcher)

+ (void)complementInstanceMethod:(SEL)selector byCalling:(DLVoidBlock)block;
+ (void)listenToAllInstanceMethods:(DLSelectorBlock)block;

@end
