//
//  ImageController.m
//  PhotoViewer
//
//  Created by David Ross on 01/09/2015.
//  Copyright (c) 2015 David Ross. All rights reserved.
//

#import "ImageController.h"
#import "AppDelegate.h"

typedef enum { IMG_MOVE_NONE, IMG_MOVE_LEFT, IMG_MOVE_RIGHT } ImageMoveMode;

@interface ImageController ()

- (void)updateTitle;
- (void)loadImageAtIndex:(NSUInteger)idx mode:(ImageMoveMode)mode;

@end

@implementation ImageController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.imageView setAlignTop:YES];
    
    [self.imageView setUserInteractionEnabled:YES];
    
    UISwipeGestureRecognizer *swipeL = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    [swipeL setDirection: UISwipeGestureRecognizerDirectionLeft];
    [self.imageView addGestureRecognizer:swipeL];
    
    UISwipeGestureRecognizer *swipeR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    [swipeR setDirection: UISwipeGestureRecognizerDirectionRight];
    [self.imageView addGestureRecognizer:swipeR];
    
    [self updateTitle];
    [self loadImageAtIndex:self.index mode:IMG_MOVE_NONE];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)])
    {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)updateTitle
{
    self.title = [NSString stringWithFormat:@"%d of %d", (int)self.index+1, (int)[self.items count]];
}

- (void)loadImageAtIndex:(NSUInteger)idx mode:(ImageMoveMode)mode
{
    if (nil != self.items)
    {
        NSMutableDictionary *dict = (NSMutableDictionary*)[self.items objectAtIndex:idx];
        NSURL *url = (NSURL*)[dict objectForKey:KeyUrl];
        ALAssetsLibrary *library = [AppDelegate defaultAssetsLibrary];
        
        [library assetForURL:url resultBlock:^(ALAsset *asset)
         {
             if (nil != asset)
             {
                 ALAssetRepresentation *rep = asset.defaultRepresentation;
                 
                 CGImageRef iref = [rep fullScreenImage];
                 if (nil != iref)
                 {
                     UIImage *img = [UIImage imageWithCGImage:[rep fullScreenImage] scale:[rep scale] orientation:UIImageOrientationUp];
                     
                     [self.imageView setImage:img];
                     
                     CATransition *transition = [CATransition animation];
                     
                     transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                     
                     switch (mode)
                     {
                         case IMG_MOVE_NONE:
                             transition.duration = 0.1f;
                             transition.type = kCATransitionFade;
                             break;
                             
                         case IMG_MOVE_LEFT:
                             transition.duration = 0.35f;
                             transition.type = kCATransitionMoveIn;
                             transition.subtype = kCATransitionFromLeft;
                             break;
                             
                         case IMG_MOVE_RIGHT:
                             transition.duration = 0.35f;
                             transition.type = kCATransitionMoveIn;
                             transition.subtype = kCATransitionFromRight;
                             break;
                             
                         default:
                             break;
                     }
                     
                     [self.imageView.layer addAnimation:transition forKey:nil];
                     [self updateTitle];
                 }
             }
             
         } failureBlock:^(NSError *error) {
             
         }];
    }
}

#pragma mark - Actions

- (void)swipeLeft:(UIGestureRecognizer*)aGesture
{
    NSUInteger count = [self.items count];
    
    if (self.index < count-1)
    {
        self.index += 1;
        [self loadImageAtIndex:self.index mode:IMG_MOVE_RIGHT];
    }
}

- (void)swipeRight:(UIGestureRecognizer*)aGesture
{
    if (self.index > 0)
    {
        self.index -= 1;
        [self loadImageAtIndex:self.index mode:IMG_MOVE_LEFT];
    }
}

@end
