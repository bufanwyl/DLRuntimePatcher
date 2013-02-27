//
//  AppDelegate.m
//  Runtime
//
//  Created by Denis Lebedev on 2/22/13.
//  Copyright (c) 2013 Denis Lebedev. All rights reserved.
//

#import "AppDelegate.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import "NSObject+DLObjcPatcher.h"

@interface TestA : NSObject

- (void)foo;
- (void)bar;

@end

@implementation TestA

- (void)foo {
	NSLog(@"Original foo");
}

- (void)bar {
	NSLog(@"Original bar");
}
@end




@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
	TestA * a = [[TestA alloc] init];
	[TestA complementInstanceMethod:@selector(foo) byCalling:^ (NSObject *obj){
		NSLog(@"%@ Intercepted %@", obj, NSStringFromSelector(@selector(foo)));
	}];
	
	[UIView listenToAllInstanceMethods:^(NSObject *obj, SEL selector) {
		NSLog(@"%@", NSStringFromSelector(selector));
	} includePrivate:NO];
	
	[a foo];
	[a foo];
	[a bar];
	
	[self.window makeKeyAndVisible];

    return YES;
}

@end
