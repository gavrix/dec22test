//
//  MockProductsResponse.m
//  TestApplication
//
//  Created by Pascal Vantrepote on 12/18/2013.
//  Copyright (c) 2013 Pascal Vantrepote. All rights reserved.
//

#import "MockProductsResponse.h"

@interface MockProductsResponse () {
	NSArray* _items;
}

@end

@implementation MockProductsResponse

#pragma mark - Init/Dealloc

- (instancetype)initWithItems:(NSArray *)items {
	self = [super init];
	if (self) {
		_items = items;
	}
	
	return self;
}

#pragma mark - ProductsResponse

@synthesize items = _items;

@end
