//
//  MockProductAPI.h
//  TestApplication
//
//  Created by Pascal Vantrepote on 12/18/2013.
//  Copyright (c) 2013 Pascal Vantrepote. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>

#import "ProductsAPI.h"

@interface MockProductAPI : NSObject<ProductsAPI>

+ (instancetype)sharedInstance;

- (RACSignal *)productsAtPage:(NSUInteger)pageIndex
					 pageSize:(NSUInteger)pageSize;

- (RACSignal *)productsAtRange:(NSRange)range;

@end
