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

// this value is measured so that one pgae filled with items fits the screen.
// It is supposed to be different for 3.5" and 10"screens
const NSUInteger ViewControllerProductsPageSize = 13;
const NSUInteger ViewControllerScrollViewAtBottomThreshold = 5;

@interface ViewController ()
{
	NSMutableArray *_loadedItems;
	struct {
		unsigned int ItemsLoadingTriggered:1;
	} _flags;
}
@end

@implementation ViewController

#pragma mark - Construction & destruction

// I always give to such _commonInit.. methods unique part, usually containing name of this class
// to prevent overriding possible method in one of it's superclasses implementations, as they may follow
// same pattern.
- (void)_commonViewControllerInit {
	_loadedItems = [[NSMutableArray alloc] init];
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
	
	[self _loadNextPage];
}

#pragma mark - Private helper methods
- (void)_appendLoadedItems:(NSArray *)items {

	NSMutableArray *indexPaths = [NSMutableArray array];
	for (unsigned i = 0; i< items.count; ++i) {
		[indexPaths addObject:[NSIndexPath indexPathForRow:i + _loadedItems.count inSection:0]];
	}
	[_loadedItems addObjectsFromArray:items];
	[self.tableView insertRowsAtIndexPaths:indexPaths
						  withRowAnimation:UITableViewRowAnimationNone];

}

- (void)_loadNextPage {
	_flags.ItemsLoadingTriggered = YES;
	[_loadedItems addObject:@"Loading"];
	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_loadedItems.count - 1 inSection:0]]
						  withRowAnimation:UITableViewRowAnimationFade];

	[[MockProductAPI sharedInstance] productsAtPage:_loadedItems.count / ViewControllerProductsPageSize
										   pageSize:ViewControllerProductsPageSize
								withCompletionBlock:^(id<ProductsResponse> response, NSError *error) {
									_flags.ItemsLoadingTriggered = NO;
									
									[self.tableView beginUpdates];
									
									[_loadedItems removeLastObject];
									[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_loadedItems.count inSection:0]]
														  withRowAnimation:UITableViewRowAnimationFade];
									[self _appendLoadedItems:[response items]];
									
									[self.tableView endUpdates];
									
									
								}];
}

#pragma mark - UITableViewDleegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _loadedItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	if (indexPath.row == _loadedItems.count - 1 && _flags.ItemsLoadingTriggered) {
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
		cell.textLabel.text = _loadedItems[indexPath.row];
	}
	
	return cell;
}

#pragma - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView.contentOffset.y >
		(scrollView.contentSize.height - scrollView.bounds.size.height) - ViewControllerScrollViewAtBottomThreshold &&
		!_flags.ItemsLoadingTriggered) {
		[self _loadNextPage];
	}
}
@end
