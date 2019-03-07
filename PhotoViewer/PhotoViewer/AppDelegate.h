//
//  AppDelegate.h
//  PhotoViewer
//
//  Created by David Ross on 31/08/2015.
//  Copyright (c) 2015 David Ross. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

static NSString * const KeyUrl = @"URL";
static NSString * const KeyImg = @"IMG";
static NSString * const KeySel = @"SEL";

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (ALAssetsLibrary*)defaultAssetsLibrary;

@end

