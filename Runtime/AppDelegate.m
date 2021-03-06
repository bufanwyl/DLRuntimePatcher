//
//  AppDelegate.m
//  Runtime
//
//  Created by Denis Lebedev on 2/22/13.
//  Copyright (c) 2013 Denis Lebedev. All rights reserved.
//

#import "AppDelegate.h"

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
    self.window.backgroundColor = [UIColor whiteColor];
	
	[UIResponder listenToAllInstanceMethods:^(NSObject *obj, SEL selector) {
		NSLog(@"%@ called: '%@'", obj, NSStringFromSelector(selector));
	} includePrivate:NO];
	
	TestA * a = [[TestA alloc] init];
	TestA * b = [[TestA alloc] init];

	[a complementMethod:@selector(bar) byCalling:^(NSObject *callee) {
		NSLog(@"Intercepted bar!");
		
	}];
	
	[TestA complementInstanceMethod:@selector(foo) byCalling:^(NSObject *obj){
		NSLog(@"%@ concrete method intercepted %@", obj, NSStringFromSelector(@selector(foo)));
	}];
	
	
	[a foo];
	[b foo];
	[a bar];
	[b bar];
	
	[self.window makeKeyAndVisible];

    return YES;
}

@end
