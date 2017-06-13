//
//  ScreenshotsController.m
//  OSIA
//
//  Created by dkhamsing on 11/16/16.
//  Copyright © 2016 dkhamsing. All rights reserved.
//

#import "ScreenshotsController.h"

@interface ScreenshotCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *imageView;

@property (nonatomic, strong, readonly) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSString *urlString;

@end

@implementation ScreenshotCell

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    
    [self setup];
    
    return self;
}

- (void)setUrlString:(NSString *)urlString;
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self.spinner stopAnimating];
        
        if (error)
            NSLog(@"error: %@", error);                    
        else
            self.imageView.image = [UIImage imageWithData:data];
    }];
    [task resume];
}

- (void)setup;
{
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _spinner = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
    
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.spinner];
    
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.spinner.autoresizingMask = self.imageView.autoresizingMask;
    [self.spinner startAnimating];
}

@end

@interface ScreenshotsController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@end

@implementation ScreenshotsController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.leftButton  = [[UIButton alloc] init];
    self.rightButton = [[UIButton alloc] init];

    [self setup];
}

- (void)viewWillLayoutSubviews;
{
    [super viewWillLayoutSubviews];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    [self render];
}

#pragma mark Private

- (void)render;
{
    self.title = self.appName;
    
    {
        UILabel *t = [UILabel new];
        t.numberOfLines = 2;
        
        NSString *title = [NSString stringWithFormat:@"%@\n%@ screenshot%@",
                           self.appName,
                           @(self.screenshots.count),
                           self.screenshots.count==1?@"":@"s"
                           ];
        
        t.text = title;
        t.textAlignment = NSTextAlignmentCenter;
        
        [t sizeToFit];
        
        self.navigationItem.titleView = t;
    }
    
    [self.collectionView reloadData];
    
    self.leftButton.hidden = self.hideLeftButton;
    
    [self.rightButton setTitle:self.sourceTitle forState:UIControlStateNormal];
}

static NSString * const kCollectionId = @"kCollectionId";

- (void)setup;
{
    if (@available(iOS 11, *))
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.pagingEnabled = YES;
        [self.collectionView registerClass:[ScreenshotCell class] forCellWithReuseIdentifier:kCollectionId];
    }
    
    {
        [self.leftButton  setTitle:@"App Store"  forState:UIControlStateNormal];
        [self.leftButton  addTarget:self action:@selector(actionLeft)  forControlEvents:UIControlEventTouchUpInside];
        [self.rightButton addTarget:self action:@selector(actionRight) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // layout
    UIView *container = [[UIView alloc] init];
    
    {
        UIView *empty = [[UIView alloc] init];
        
        [@[empty, self.collectionView, container] enumerateObjectsUsingBlock:^(UIView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.view addSubview:obj];
            obj.translatesAutoresizingMaskIntoConstraints = NO;
        }];
        
        NSDictionary *views = @{ @"container": container,
                                 @"col": self.collectionView,
                                 @"empty": empty
                                };
        NSDictionary *metrics = @{ @"h": @50 };
        NSArray *formats = @[
                             @"|-[col]-|",
                             @"|[container]|",
                             @"|[empty]|",
                             
                             @"V:|-[empty(h)]-[col][container(h)]|"
                             ];
        [formats enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:obj options:kNilOptions metrics:metrics views:views];
            [self.view addConstraints:constraints];
        }];
    }
    
    {
        NSDictionary *views = @{
                                @"left":self.leftButton,
                                @"right":self.rightButton
                                };
        NSDictionary *metrics = nil;
        [views.allValues enumerateObjectsUsingBlock:^(UIView * obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [container addSubview:obj];
            obj.translatesAutoresizingMaskIntoConstraints = NO;
        }];        
        NSArray *formats = @[
                             @"|[left][right(left)]|",
                             @"V:|[left]|",
                             @"V:|[right]|"
                             ];
        [formats enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:obj options:kNilOptions metrics:metrics views:views];
            [container addConstraints:constraints];
        }];
    }
}

- (void)actionLeft;
{
    if (self.didSelectAppStore)
        self.didSelectAppStore();
}

- (void)actionRight;
{
    if (self.didSelectSource)
        self.didSelectSource();
}

#pragma mark Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return self.screenshots.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    ScreenshotCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionId forIndexPath:indexPath];
    cell.urlString = self.screenshots[indexPath.row];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    CGSize size = self.collectionView.bounds.size;
    
    return size;
}

@end
