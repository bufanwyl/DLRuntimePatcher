//
//  NSObject+DLObjcPatcher.h
//  Runtime
//
//  Created by Denis Lebedev on 2/26/13.
//  Copyright (c) 2013 Denis Lebedev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DLRetBlock)(NSObject *callee);
typedef void (^DLRetWithSelectorBlock)(NSObject *callee, SEL selector);

@interface NSObject (DLObjcPatcher)

+ (void)complementInstanceMethod:(SEL)selector byCalling:(DLRetBlock)block;
+ (void)listenToAllInstanceMethods:(DLRetWithSelectorBlock)block;
+ (void)listenToAllInstanceMethods:(DLRetWithSelectorBlock)block includePrivate:(BOOL)privateMethods;

- (void)complementMethod:(SEL)selector byCalling:(DLRetBlock)block;


@end
