//
//  ImageController.h
//  PhotoViewer
//
//  Created by David Ross on 01/09/2015.
//  Copyright (c) 2015 David Ross. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIImageViewAligned.h"

@interface ImageController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageViewAligned *imageView;

@property (nonatomic, strong) NSArray *items;

@property (nonatomic, assign) NSUInteger index;

- (void)swipeLeft:(UIGestureRecognizer*)aGesture;
- (void)swipeRight:(UIGestureRecognizer*)aGesture;

@end
