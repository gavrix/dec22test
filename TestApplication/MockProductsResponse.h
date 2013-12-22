//
//  MockProductsResponse.h
//  TestApplication
//
//  Created by Pascal Vantrepote on 12/18/2013.
//  Copyright (c) 2013 Pascal Vantrepote. All rights reserved.
//

#import "ProductsAPI.h"

@interface MockProductsResponse : NSObject<ProductsResponse>

- (instancetype)initWithItems:(NSArray*) items;

@end
