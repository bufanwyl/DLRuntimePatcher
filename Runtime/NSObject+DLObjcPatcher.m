//
//  NSObject+DLObjcPatcher.m
//  Runtime
//
//  Created by Denis Lebedev on 2/26/13.
//  Copyright (c) 2013 Denis Lebedev. All rights reserved.
//

#import "NSObject+DLObjcPatcher.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface Interceptor : NSObject

@property (nonatomic, strong) NSMutableDictionary *blocksStore;

+ (instancetype)sharedInstance;

- (void)storeBlock:(DLVoidBlock)block forClass:(Class)aClass method:(SEL)method;
- (DLVoidBlock)blockForClass:(Class)aClass method:(SEL)method;

@end


@implementation Interceptor

- (void)storeBlock:(DLVoidBlock)block forClass:(Class)aClass method:(SEL)method {
	if (!_blocksStore) {
		_blocksStore = [NSMutableDictionary dictionary];
	}
	if (!_blocksStore[NSStringFromClass(aClass)]) {
		_blocksStore[NSStringFromClass(aClass)] = [NSMutableDictionary dictionary];
	}
	self.blocksStore[NSStringFromClass(aClass)][NSStringFromSelector(method)] = [block copy];
}

- (DLVoidBlock)blockForClass:(Class)aClass method:(SEL)method {
//@TODO: it's sure we should have some caching of selectors here
	DLVoidBlock result = self.blocksStore[NSStringFromClass(aClass)][NSStringFromSelector(method)];
	if (!result && [aClass superclass] != [NSObject class]) {
		result = [self blockForClass:[aClass superclass] method:method];
	}
	return result;
}

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end

@interface MySuper : NSObject


@end

@implementation MySuper

@end

@implementation NSObject (DLObjcPatcher)

+ (void)complementInstanceMethod:(SEL)selector byCalling:(DLVoidBlock)block {
	[[Interceptor sharedInstance] storeBlock:block forClass:self method:selector];
	Method origMethod = class_getInstanceMethod([self class], selector);
	IMP impl = class_getMethodImplementation([self class], selector);
	BOOL result = class_addMethod([self class],
					NSSelectorFromString([NSStringFromSelector(selector) stringByAppendingString:@"__"]),
					impl,
					method_getTypeEncoding(origMethod));
	NSAssert(result, @"Unable to add method");
	
	method_setImplementation(origMethod,
							 class_getMethodImplementation([self class], @selector(fakeSelector)));	
}

+ (void)listenToAllInstanceMethods:(DLSelectorBlock)block {
	unsigned int outCount;
    Method *methods = class_copyMethodList(self, &outCount);
    for (int i = 0; i < outCount; i++) {
		SEL sel = method_getName(methods[i]);
//@TODO: we don't need exactly all methods here (f.e. starting with dot)
		[self complementInstanceMethod:sel byCalling:^{
			//TODO: maybe we should 
			block(sel);
		}];
	}
    free(methods);
}

#pragma mark - Override

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	 
	SEL modifiedSelector = NSSelectorFromString([NSStringFromSelector(anInvocation.selector) stringByAppendingString:@"__"]); //TODO: more universal selector needed
	if ([self respondsToSelector:modifiedSelector]) {
		DLVoidBlock block = [[Interceptor sharedInstance] blockForClass:[[anInvocation target] class]
																 method:anInvocation.selector];
		block(); //@TODO: pass some args here, f.e.
		anInvocation.selector = modifiedSelector;
		[anInvocation invokeWithTarget:self];
	}
}

#pragma clang diagnostic pop

@end
