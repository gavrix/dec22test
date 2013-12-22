//
//  ProductsAPI.h
//  TestApplication
//
//  Created by Pascal Vantrepote on 12/18/2013.
//  Copyright (c) 2013 Pascal Vantrepote. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ProductsResponse <NSObject>

// For now items are just strings
@property (nonatomic, readonly) NSArray* items;

@end

@protocol ProductsAPI <NSObject>

// Get all the products from a given page containing a # of items
// Returns an ProductsResponse that contains an array of products.
// We rich the last page if the number of items in the array is lower than the requested size
- (id<ProductsResponse>)getProductsFromPage:(NSUInteger) page andNumberOfItemPerPage:(NSUInteger) numberOfItemPerPage;

- (void)productsAtPage:(NSUInteger)pageIndex
              pageSize:(NSUInteger)pageSize
   withCompletionBlock:(void (^)(id<ProductsResponse> response, NSError *error)) completionBlock;

- (void)productsAtRange:(NSRange)range
    withCompletionBlock:(void (^)(id<ProductsResponse> response, NSError *error)) completionBlock;
@end
