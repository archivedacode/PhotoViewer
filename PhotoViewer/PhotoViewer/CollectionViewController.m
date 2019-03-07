//
//  CollectionViewController.m
//  PhotoViewer
//
//  Created by David Ross on 31/08/2015.
//  Copyright (c) 2015 David Ross. All rights reserved.
//

#import "CollectionViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageController.h"
#import "CollectionViewCell.h"
#import "AppDelegate.h"

static NSString * const ReuseIdentifier = @"Cell";
static NSString * const StrSelect = @"Select All";
static NSString * const StrDeselect = @"Deselect All";

@interface CollectionViewController ()

@property (nonatomic, assign) CGSize cellSize;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) ALAssetsGroup *currentAssetGroup;

@end

@implementation CollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    CGFloat max = MAX(width, height);
    
    self.cellSize = CGSizeMake(60.0, 60.0);
        
    if (max == 667.0)
    {
        self.cellSize = CGSizeMake(71.0, 71.0);
    }
    else if (max == 736.0)
    {
        self.cellSize = CGSizeMake(79.0, 79.0);
    }
    
    self.isLoading = NO;
    
    self.navigationItem.title = @"Photos";
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
    
    [self.collectionView setContentInset:UIEdgeInsetsMake(0, 2, 0, 2)];
    [self.collectionView setAllowsMultipleSelection:YES];
    
    UINib *nib = [UINib nibWithNibName:@"CollectionViewCell" bundle:nil];
    
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:ReuseIdentifier];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(press:)];
    lpgr.minimumPressDuration = 0.5;
    lpgr.delegate = self;
    [self.collectionView addGestureRecognizer:lpgr];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetsChanged:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    
    [self setupToolbar];
    [self populatePhotos];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)assetsChanged:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ALAssetsLibraryChangedNotification
                                                  object:nil];
    
    [self populatePhotos];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetsChanged:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

- (void)setupToolbar
{
    UIBarButtonItem *btnSel = [[UIBarButtonItem alloc] initWithTitle:StrSelect
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(selectOrDeselect:)];
    
    UIBarButtonItem *btnFlex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                             target:nil
                                                                             action:nil];
    
    NSArray *array = [NSArray arrayWithObjects:btnSel, btnFlex, nil];
    
    [self setToolbarItems:array];
    [self.navigationController.toolbar setTranslucent:NO];
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)press:(UILongPressGestureRecognizer*)gesture
{
    if ([self.items count] == 0)
        return;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [gesture locationInView:self.collectionView];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
        if (nil != indexPath)
        {
            ImageController *cnt = [[ImageController alloc] initWithNibName:@"ImageController" bundle:nil];
            [cnt setHidesBottomBarWhenPushed:YES];
            [cnt setIndex:indexPath.row];
            [cnt setItems:self.items];
            [self.navigationController pushViewController:cnt animated:YES];
        }
    }
}

- (void)populatePhotos
{
    if (self.isLoading)
        return;
    
    self.isLoading = YES;
    
    self.assetsLibrary = [AppDelegate defaultAssetsLibrary];
    
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         if (group != nil)
         {
             NSMutableArray *data = [NSMutableArray array];
             
             self.currentAssetGroup = group;
             
             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
             
             [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop)
              {
                  if (nil != result)
                  {
                      NSURL *url = result.defaultRepresentation.url;
                      
                      CGImageRef ref = [result thumbnail];
                      UIImage *thumbnail = [UIImage imageWithCGImage:ref];
                      
                      if (nil != thumbnail && nil != url)
                      {
                          NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                       url, KeyUrl,
                                                       thumbnail, KeyImg,
                                                       [NSNumber numberWithBool:NO], KeySel,
                                                       nil];
                          
                          [data addObject:dict];
                      }
                  }
              }];
             
             self.items = nil;
             self.items = [[NSMutableArray alloc] initWithArray:[data copy]];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.collectionView reloadData];
                 self.isLoading = NO;
             });
         }
         
     } failureBlock:^(NSError *error) {
         self.isLoading = NO;
         NSLog(@"%@", [error localizedDescription]);
     }];
}

- (void)selectOrDeselect:(id)sender
{
    if ([self.items count] > 0)
    {
        UIBarButtonItem *btn = (UIBarButtonItem*)sender;
        
        BOOL isSelected = [btn.title isEqualToString:StrSelect];
        
        for (int row=0; row<[self.items count]; row++)
        {
            NSIndexPath *idx = [NSIndexPath indexPathForRow:row inSection:0];
            
            if (isSelected)
                [self.collectionView selectItemAtIndexPath:idx animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            else
                [self.collectionView deselectItemAtIndexPath:idx animated:NO];
            
            CollectionViewCell *cell = (CollectionViewCell*)[self.collectionView cellForItemAtIndexPath:idx];
            [self updateCellSelected:cell isSelected:isSelected];
            
            NSMutableDictionary *dict = (NSMutableDictionary*)[self.items objectAtIndex:idx.row];
            [dict setObject:[NSNumber numberWithBool:isSelected] forKey:KeySel];
        }
        
        btn.title = isSelected ? StrDeselect : StrSelect;
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.items count];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(3.0, 1.0, 3.0, 1.0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = (CollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:ReuseIdentifier forIndexPath:indexPath];
    NSMutableDictionary *dict = (NSMutableDictionary*)[self.items objectAtIndex:indexPath.row];
    UIImage *img = [dict objectForKey:KeyImg];
    [cell.imgView setImage:img];
    
    BOOL isSelected = [[dict objectForKey:KeySel] boolValue];
    [cell setSelected:isSelected];
    [self updateCellSelected:cell isSelected:isSelected];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)updateCellSelected:(CollectionViewCell*)cell isSelected:(BOOL)isSelected
{
    if (isSelected)
    {
        if ([cell.imgView.subviews count] == 0)
        {
            UIView *bgView = [[UIView alloc] initWithFrame:cell.bounds];
            [bgView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.375]];
            
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(33.0, 33.0, 25.0, 25.0)];
            [imgView setImage:[UIImage imageNamed:@"TICK.png"]];
            [bgView addSubview:imgView];
            
            [cell.imgView addSubview:bgView];
        }
    }
    else
    {
        if ([cell.imgView.subviews count] == 1)
        {
            [cell.imgView.subviews[0] removeFromSuperview];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = (CollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self updateCellSelected:cell isSelected:YES];
    
    NSMutableDictionary *dict = (NSMutableDictionary*)[self.items objectAtIndex:indexPath.row];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:KeySel];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = (CollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self updateCellSelected:cell isSelected:NO];
    
    NSMutableDictionary *dict = (NSMutableDictionary*)[self.items objectAtIndex:indexPath.row];
    [dict setObject:[NSNumber numberWithBool:NO] forKey:KeySel];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellSize;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

@end
