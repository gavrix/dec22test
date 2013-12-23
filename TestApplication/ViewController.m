//
//  ViewController.m
//  TestApplication
//
//  Created by Pascal Vantrepote on 12/18/2013.
//  Copyright (c) 2013 Pascal Vantrepote. All rights reserved.
//

#import "ViewController.h"
#import "MockProductAPI.h"
#import "ProductsAPI.h"

#import <libextobjc/extobjc.h>

//rac custom additions

#import "NSIndexSet+RACSequenceAdditions.h"

// this value is measured so that one pgae filled with items fits the screen.
// It is supposed to be different for 3.5" and 10"screens
const NSUInteger ViewControllerProductsPageSize = 13;
const NSUInteger ViewControllerScrollViewAtBottomThreshold = 5;

@interface ViewController ()
{
	RACCommand *_loadNextPageCommand;
}

@property (nonatomic) NSArray *loadedItems;
@property (nonatomic) NSNumber *loading;
@end

@implementation ViewController

#pragma mark - Construction & destruction

// I always give to such _commonInit.. methods unique part, usually containing name of this class
// to prevent overriding possible method in one of it's superclasses implementations, as they may follow
// same pattern.
- (void)_commonViewControllerInit {
	self.loadedItems = @[];
	
	_loadNextPageCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSNumber *pageIndexNumber) {

		return [[MockProductAPI sharedInstance] productsAtPage:pageIndexNumber.unsignedIntegerValue
													  pageSize:ViewControllerProductsPageSize];
	}];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self _commonViewControllerInit];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _commonViewControllerInit];
	}
	return self;
}

#pragma mark - UIViewController methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self _setupLoadingIndicatorRelations];
	[self _setupItemsLoadedRelations];
	
	
	[_loadNextPageCommand execute:@(self.loadedItems.count)];
}

#pragma mark - Reactive declarations

- (void)_setupItemsLoadedRelations {
	@weakify(self)
	RACSignal *nextItemsLoadedSignal = [[[_loadNextPageCommand executionSignals] flatten] map:^id(id<ProductsResponse> response) {
		return [response items];
	}];
	
	RAC(self, loadedItems) = [nextItemsLoadedSignal map:^id(NSArray *value) {
		@strongify(self);
		return [self.loadedItems arrayByAddingObjectsFromArray:value];
	}];
	
	[[[[[_loadNextPageCommand executionSignals] flattenMap:^RACStream *(RACSignal *executionSignal) {
		return [executionSignal takeLast:1];
	}] map:^id(id<ProductsResponse> response) {
		return response.items;
	}] map:^id(NSArray *items) {
		@strongify(self);
		NSIndexSet *itemsIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.loadedItems.count - items.count, items.count)];
		
		return [[itemsIndexes.rac_sequence map:^id(NSNumber *idx) {
			return [NSIndexPath indexPathForRow:idx.unsignedIntegerValue inSection:0];
		}] array];
	}] subscribeNext:^(NSArray *indexPaths) {
		@strongify(self);
		[self.tableView beginUpdates];
		
		[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] - 1 inSection:0]]
							  withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView insertRowsAtIndexPaths:indexPaths
							  withRowAnimation:UITableViewRowAnimationNone];
		
		[self.tableView endUpdates];
	}];
	
}

- (void)_setupLoadingIndicatorRelations {
	RACSignal *fadeValueSignal = [RACSignal return: @(UITableViewRowAnimationFade)];
	
	RACSignal *loadingStartedSignal = [[_loadNextPageCommand executionSignals] map:^id(id value) {
		return @(YES);
	}];
	
	RACSignal *loadingFinishedSignal = [_loadNextPageCommand.executionSignals flattenMap:^RACStream *(RACSignal *subscribeSignal) {
		return [[[subscribeSignal materialize] filter:^BOOL(RACEvent *event) {
			return event.eventType == RACEventTypeCompleted;
		}] map:^id(id value) {
			return @(NO);
		}];
	}];
	
	RACSignal *loadingErrorSignal = [_loadNextPageCommand.errors map:^id(id value) {
		return @(NO);
	}];
	
	RAC(self, loading) = [RACSignal merge:@[loadingStartedSignal, loadingFinishedSignal, loadingErrorSignal]];
	
	@weakify(self);
	[self.tableView rac_liftSelector:@selector(insertRowsAtIndexPaths:withRowAnimation:)
						 withSignals:[loadingStartedSignal map:^id(id value) {
		@strongify(self);
		return @[[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] inSection:0]];
	}], fadeValueSignal, nil];
	
	[self.tableView rac_liftSelector:@selector(deleteRowsAtIndexPaths:withRowAnimation:)
						 withSignals:[loadingErrorSignal map:^id(id value) {
		@strongify(self);
		return @[[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] - 1 inSection:0]];
	}], fadeValueSignal, nil];

}

#pragma mark - UITableViewDleegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.loadedItems.count + (self.loading.boolValue ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	if (indexPath.row >= self.loadedItems.count && self.loading.boolValue) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"activity" forIndexPath:indexPath];
		// Weird UIKit behavior workaround. Although I set in IB for this activity indicator to always
		// animate, after being removed and re-added to table view is stops animating.
		// Have to restart this animating manually.
		for (UIView *subView in cell.contentView.subviews) {
			if ([subView isKindOfClass:[UIActivityIndicatorView class]]) {
				[(UIActivityIndicatorView *)subView startAnimating];
			}
		}
	}
	else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
		cell.textLabel.text = self.loadedItems[indexPath.row];
	}
	
	return cell;
}

#pragma - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.contentOffset.y >
		(scrollView.contentSize.height - scrollView.bounds.size.height) - ViewControllerScrollViewAtBottomThreshold) {
		[_loadNextPageCommand execute:@(self.loadedItems.count / ViewControllerProductsPageSize)];
	}
}
@end
