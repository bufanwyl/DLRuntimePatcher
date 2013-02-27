DLRuntimePatcher
================

Demonstration of interception of any message sent to NSObject subclasses.
Usage with standard classes (UI and NS) is not stable now, so try it on your custom classes first.

**ATTENTION: the approach I've used is very very dirty, so please use provided code only for educational or debugging purposes.**

## Usage

The project contains some examples. 

Listen to all `UIResponder` instance methods: 
``` objective-c
  [UIResponder listenToAllInstanceMethods:^(NSObject *obj, SEL selector) {
		NSLog(@"%@ called: '%@'", obj, NSStringFromSelector(selector));
	} includePrivate:NO];
```

The block will be called if any of UIResponder's methods is invoked.

Add additional behaviour to specific method:
``` objective-c
  [TestA complementInstanceMethod:@selector(foo) byCalling:^(NSObject *obj){
		NSLog(@"%@ concrete method intercepted %@", obj, NSStringFromSelector(@selector(foo)));
	}];
```

## TODO

There is a lot of TODO placed in code. Also, it will be nice to be able to listen to methods of particular instance of a class and to 'class' methods. Any suggestions are highly appreciated.
