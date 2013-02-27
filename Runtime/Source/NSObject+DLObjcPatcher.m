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

@property (nonatomic, strong) NSMutableDictionary *classBlocksStore;
@property (nonatomic, strong) NSMutableDictionary *instanceBlocksStore;

+ (instancetype)sharedInstance;

- (void)storeBlock:(DLRetBlock)block forClass:(Class)aClass method:(SEL)method;
- (void)storeBlock:(DLRetBlock)block forInstance:(id)instance method:(SEL)method;

- (DLRetBlock)blockForClass:(Class)aClass method:(SEL)method;
- (DLRetBlock)blockForInstance:(id)instance method:(SEL)method;

@end


@implementation Interceptor

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)storeBlock:(DLRetBlock)block forClass:(Class)aClass method:(SEL)method {
	if (!_classBlocksStore) {
		_classBlocksStore = [NSMutableDictionary dictionary];
	}
	if (!_classBlocksStore[NSStringFromClass(aClass)]) {
		_classBlocksStore[NSStringFromClass(aClass)] = [NSMutableDictionary dictionary];
	}
	self.classBlocksStore[NSStringFromClass(aClass)][NSStringFromSelector(method)] = [block copy];
}

- (void)storeBlock:(DLRetBlock)block forInstance:(id)instance method:(SEL)method {
	NSInteger addr = (NSInteger)instance;
	if (!_instanceBlocksStore) {
		_instanceBlocksStore = [NSMutableDictionary dictionary];
	}
	if (!_instanceBlocksStore[@(addr)]) {
		_instanceBlocksStore[@(addr)] = [NSMutableDictionary dictionary];
	}
	self.instanceBlocksStore[@(addr)][NSStringFromSelector(method)] = [block copy];
}

- (DLRetBlock)blockForClass:(Class)aClass method:(SEL)method {
//@TODO: it's sure we should have some caching of selectors here
	DLRetBlock result = self.classBlocksStore[NSStringFromClass(aClass)][NSStringFromSelector(method)];
	if (!result && [aClass superclass] != [NSObject class]) {
		result = [self blockForClass:[aClass superclass] method:method];
	}
	return result;
}

- (DLRetBlock)blockForInstance:(id)instance method:(SEL)method {
	NSInteger addr = (NSInteger)instance;
	return self.instanceBlocksStore[@(addr)][NSStringFromSelector(method)];
}

@end

@implementation NSObject (DLObjcPatcher)

+ (void)complementInstanceMethod:(SEL)selector byCalling:(DLRetBlock)block {
	[[Interceptor sharedInstance] storeBlock:block forClass:self method:selector];
	Method origMethod = class_getInstanceMethod([self class], selector);
	IMP impl = class_getMethodImplementation([self class], selector);
	class_addMethod([self class],
					[NSObject patchedSelector:selector],
					impl,
					method_getTypeEncoding(origMethod));
	method_setImplementation(origMethod,
							 class_getMethodImplementation([self class], @selector(fakeSelector)));	
}

+ (void)listenToAllInstanceMethods:(DLRetWithSelectorBlock)block {
	[self listenToAllInstanceMethods:block includePrivate:YES];
}

+ (void)listenToAllInstanceMethods:(DLRetWithSelectorBlock)block includePrivate:(BOOL)privateMethods {
	unsigned int outCount;
    Method *methods = class_copyMethodList(self, &outCount);
    for (int i = 0; i < outCount; i++) {
		SEL sel = method_getName(methods[i]);
		if (sel_isEqual(sel, NSSelectorFromString(@"retain")) ||
			sel_isEqual(sel, NSSelectorFromString(@"release")) ||
			(sel_getName(sel)[0] == '_' && !privateMethods)) { //skip apple 'private' methods
			continue;
			//@TODO: we don't need exactly all methods here (f.e. starting with dot)
		}
		[self complementInstanceMethod:sel byCalling:^ (NSObject *callee){
			//TODO: maybe we should add more interesting info here (passed args)
			block(callee, sel);
		}];
	}
    free(methods);
}

- (void)complementMethod:(SEL)selector byCalling:(DLRetBlock)block {
	[[Interceptor sharedInstance] storeBlock:block forInstance:self method:selector];
	Method origMethod = class_getInstanceMethod([self class], selector);
	IMP impl = class_getMethodImplementation([self class], selector);
	class_addMethod([self class],
					[NSObject patchedSelector:selector],
					impl,
					method_getTypeEncoding(origMethod));
	method_setImplementation(origMethod,
							 class_getMethodImplementation([self class], @selector(fakeSelector)));
}
#pragma mark - Override

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	 
	SEL modifiedSelector = [NSObject patchedSelector:anInvocation.selector];
	if ([self respondsToSelector:modifiedSelector]) {
		DLRetBlock block = [[Interceptor sharedInstance] blockForClass:[[anInvocation target] class]
																 method:anInvocation.selector];
		if (block) {
			block(self);
		} else {
			DLRetBlock block = [[Interceptor sharedInstance] blockForInstance:[anInvocation target]
																	   method:anInvocation.selector];
			if (block) {
				block(self);
			}
		}
		
		
		anInvocation.selector = modifiedSelector;
		[anInvocation invokeWithTarget:self];
	}
}

#pragma clang diagnostic pop

#pragma mark - Private

+ (SEL)patchedSelector:(SEL)selector {
	NSString *strSelector = NSStringFromSelector(selector);
	return NSSelectorFromString([@"__" stringByAppendingString:strSelector]);
}

@end
