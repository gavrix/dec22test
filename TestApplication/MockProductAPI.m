//
//  MockProductAPI.m
//  TestApplication
//
//  Created by Pascal Vantrepote on 12/18/2013.
//  Copyright (c) 2013 Pascal Vantrepote. All rights reserved.
//

#import "MockProductAPI.h"

#import "MockProductsResponse.h"

@interface MockProductAPI () {
	NSMutableArray* _allElements;
}

@end

@implementation MockProductAPI

#pragma mark Init/Dealloc

+ (instancetype)sharedInstance {
	static MockProductAPI* sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		// Init all fake objects
		_allElements = [NSMutableArray array];
		for (NSUInteger idx = 0; idx < 100001; idx++) {
			[_allElements addObject:[NSString stringWithFormat:@"Element: %u", idx]];
		}
	}
	
	return self;
}

#pragma mark - ProductsAPI

- (id<ProductsResponse>) getProductsFromPage:(NSUInteger)page andNumberOfItemPerPage:(NSUInteger)numberOfItemPerPage {
	
	NSUInteger fromItem = MIN(page * numberOfItemPerPage, _allElements.count);
	NSUInteger toItem = MIN((page + 1) * numberOfItemPerPage, _allElements.count);
	
	NSArray* items = [_allElements subarrayWithRange:NSMakeRange(fromItem, toItem - fromItem)];
	return [[MockProductsResponse alloc] initWithItems:items];
}

- (void)productsAtPage:(NSUInteger)pageIndex
              pageSize:(NSUInteger)pageSize
   withCompletionBlock:(void (^)(id<ProductsResponse> response, NSError *error)) completionBlock {
	[self productsAtRange:NSMakeRange(pageIndex * pageSize, pageSize) withCompletionBlock:completionBlock];
}

- (void)productsAtRange:(NSRange)range
    withCompletionBlock:(void (^)(id<ProductsResponse> response, NSError *error)) completionBlock {
	
	if (completionBlock) {
		double variableDelayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (arc4random() % (int64_t)(variableDelayInSeconds * NSEC_PER_SEC)));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			NSRange resultRange = NSIntersectionRange(NSMakeRange(0, _allElements.count), range);
			MockProductsResponse *response = nil;
			NSError *error = nil;
			if (resultRange.length) {
				response = [[MockProductsResponse alloc] initWithItems:[_allElements subarrayWithRange:resultRange]];
			}
			else {
				error = [NSError errorWithDomain:@"ProductAPIErrorDomain"
											code:0
										userInfo:@{NSLocalizedDescriptionKey:
				   [NSString stringWithFormat:@"items range requested (%@) doesn't exists", NSStringFromRange(range)]
												   }];
			}
			completionBlock(response, error);
		});
	}
}


#pragma mark - ReactiveCocoa support

- (RACSignal *)productsAtPage:(NSUInteger)pageIndex
					 pageSize:(NSUInteger)pageSize {
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		[self productsAtPage:pageIndex
					pageSize:pageSize
		 withCompletionBlock:^(id<ProductsResponse> response, NSError *error) {
			 if (error) {
				 [subscriber sendError:error];
			 }
			 else {
				 [subscriber sendNext:response];
				 [subscriber sendCompleted];
			 }
		 }];
		return nil;// for now this signal is not cancellable
	}];
}

- (RACSignal *)productsAtRange:(NSRange)range {
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		
		[self productsAtRange:range
		  withCompletionBlock:^(id<ProductsResponse> response, NSError *error) {
			  if (error) {
				  [subscriber sendError:error];
			  }
			  else {
				  [subscriber sendNext:response];
				  [subscriber sendCompleted];
			  }
		  }];
		
		return nil;
	}];
}


@end
