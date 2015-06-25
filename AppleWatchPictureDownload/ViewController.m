//
//  ViewController.m
//  AppleWatchPictureDownload
//
//  Created by 李亮 on 15/6/4.
//  Copyright (c) 2015年 李亮. All rights reserved.
//

#define KCOLUMN_NUM 3
#define KROW_NUM 5
#define KMARGIN 10


#define KTOTAL_WIDTH self.gridView.bounds.size.width
#define KTOTAL_HEIGHT self.gridView.bounds.size.height

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *gridView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pause;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancel;

@property (strong, nonatomic) dispatch_queue_t dispatchQueue;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toogle;

@property (strong, nonatomic) NSArray *imageUrls;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

//初始化界面
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self makeGrid];
}

//urls
-(NSArray *)imageUrls
{
    if (!_imageUrls) {
        _imageUrls = @[
            @"http://img4.cache.netease.com/photo/0009/2015-03-02/AJMKBR2A5FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBQVM5FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBQT15FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBQO65FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBQIU5FVH0009.jpg",
            @"http://img6.cache.netease.com/photo/0009/2015-03-02/AJMKBQFV5FVH0009.jpg",
            @"http://img5.cache.netease.com/photo/0009/2015-03-02/AJMKBQDB5FVH0009.jpg",
            @"http://img4.cache.netease.com/photo/0009/2015-03-02/AJMKBQAM5FVH0009.jpg",
            @"http://img2.cache.netease.com/photo/0009/2015-03-02/AJMKBQ7N5FVH0009.jpg",
            @"http://img4.cache.netease.com/photo/0009/2015-03-02/AJMKBQ4N5FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBQ2M5FVH0009.jpg",
            @"http://img5.cache.netease.com/photo/0009/2015-03-02/AJMKBQ0J5FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBPT25FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBPR05FVH0009.jpg",
            @"http://img4.cache.netease.com/photo/0009/2015-03-02/AJMKBPOU5FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBPMB5FVH0009.jpg",
            @"http://img3.cache.netease.com/photo/0009/2015-03-02/AJMKBPJ55FVH0009.jpg"
            ];
    }
    return _imageUrls;
}

//创建显示界面
-(void)makeGrid
{
    int totalGridCount = KCOLUMN_NUM * KROW_NUM;
    CGFloat width = (KTOTAL_WIDTH - (KCOLUMN_NUM + 1 ) * KMARGIN ) / KCOLUMN_NUM;
    CGFloat height = (KTOTAL_HEIGHT - (KROW_NUM + 1) * KMARGIN ) / KROW_NUM;
    
    for (int i = 0; i < totalGridCount; i++) {
        int column = i %  KCOLUMN_NUM;
        int row = i / KCOLUMN_NUM;
        CGFloat x = KMARGIN + column * (width + KMARGIN);
        CGFloat y = KMARGIN + row * (height + KMARGIN);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        [self.gridView addSubview:imageView];
        imageView.backgroundColor = [UIColor greenColor];
    }
}

//每次重新下载之前，调用此方法，重新初始化
-(void)clearImage
{
    //注意，dispatch_resume的调用次数，不能大于dispatch_suspend的调用次数，否则崩溃，此处代码用来保证dispatch_resume和dispatch_suspend成对出现
    if ([self.toogle.title isEqualToString:@"operation"] && [self.pause.title isEqualToString:@"resume"]) {
        dispatch_resume(self.dispatchQueue);
    }
    self.pause.title = @"pause";
    
    for (UIImageView *imageView in self.gridView.subviews) {
        imageView.image = nil;
        imageView.backgroundColor = [UIColor greenColor];
    }
}

//下载图片的方法
-(UIImage*)downloadImageWithIndex:(int)index
{
    NSString *imageName = self.imageUrls[index];
    
    UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageName]]];
    
    return image;
}


#pragma mark - 队列调度

//使用dispatch同步串行下载
-(void)syncSerialUseDispatch
{
    dispatch_queue_t serialQueue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    self.dispatchQueue = serialQueue;
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0 ; i < self.gridView.subviews.count; i++) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView * imageView = self.gridView.subviews[i];
                imageView.backgroundColor = [UIColor blackColor];
            });
            
            dispatch_sync(serialQueue, ^{
                UIImage *image = [self downloadImageWithIndex:i];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView * imageView = self.gridView.subviews[i];
                    imageView.image = image;
                });
            });
        }
        
    });
}

//使用operation串行下载
-(void)serialUseOperation
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
    self.operationQueue = queue;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i <self.gridView.subviews.count; i++) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView * imageView = self.gridView.subviews[i];
                imageView.backgroundColor = [UIColor blackColor];
            });
            
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                UIImage *image = [self downloadImageWithIndex:i];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView * imageView = self.gridView.subviews[i];
                    imageView.image = image;
                });
            }];
            
            [queue addOperation:operation];
        }
        
    });
}

//使用dispatch同步并行下载
-(void)syncConcurrentUseDispatch
{
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.dispatchQueue = concurrentQueue;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (int i = 0 ; i < self.gridView.subviews.count; i++) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView * imageView = self.gridView.subviews[i];
                imageView.backgroundColor = [UIColor blackColor];
            });
            
            dispatch_sync(concurrentQueue, ^{
                UIImage *image = [self downloadImageWithIndex:i];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView * imageView = self.gridView.subviews[i];
                    imageView.image = image;
                });
            });
        }
        
    });
}

//使用operation并行下载
-(void)concurrentUseOperatoin
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //[queue setMaxConcurrentOperationCount:1];
    self.operationQueue = queue;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 0; i <self.gridView.subviews.count; i++) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView * imageView = self.gridView.subviews[i];
                imageView.backgroundColor = [UIColor blackColor];
            });
            
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                UIImage *image = [self downloadImageWithIndex:i];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView * imageView = self.gridView.subviews[i];
                    imageView.image = image;
                });
            }];
            
            [queue addOperation:operation];
        }
    });
    
}


//使用dispatch异步串行下载
-(void)asyncSerialUseDispatch
{
    dispatch_queue_t serialQueue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    self.dispatchQueue = serialQueue;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 0 ; i < self.gridView.subviews.count; i++) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView * imageView = self.gridView.subviews[i];
                imageView.backgroundColor = [UIColor blackColor];
            });
            
            dispatch_async(serialQueue, ^{
                UIImage *image = [self downloadImageWithIndex:i];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView * imageView = self.gridView.subviews[i];
                    imageView.image = image;
                });
            });
        }
    });
}


//使用dispatch异步并行下载
-(void)asyncConcurrentUseDispatch
{
    dispatch_queue_t queue = dispatch_queue_create("serial", DISPATCH_QUEUE_CONCURRENT);
    self.dispatchQueue = queue;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 0 ; i < self.gridView.subviews.count; i++) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView * imageView = self.gridView.subviews[i];
                imageView.backgroundColor = [UIColor blackColor];
            });
            
            dispatch_async(queue, ^{
                UIImage *image = [self downloadImageWithIndex:i];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView * imageView = self.gridView.subviews[i];
                    imageView.image = image;
                });
            });
        }
    });
}



#pragma mark - IBAction

//同步串行进行下载
- (IBAction)syncSerial:(id)sender {
    
    [self clearImage];
    if ([self.toogle.title isEqualToString:@"operation"]) {
        [self syncSerialUseDispatch];
    }else
    {
        [self serialUseOperation];
    }
    
}


//同步并行进行下载
- (IBAction)syncConcurrent:(id)sender {
    
    [self clearImage];
    
    if ([self.toogle.title isEqualToString:@"operation"]) {
        [self syncConcurrentUseDispatch];
    }else
    {
        [self concurrentUseOperatoin];
    }
}


//异步串行进行下载
- (IBAction)asyncSerial:(id)sender {
    
    [self clearImage];
    if ([self.toogle.title isEqualToString:@"operation"]) {
        [self asyncSerialUseDispatch];
    }else
    {
        [self serialUseOperation];
    }
}

//异步并行进行下载
- (IBAction)asyncConcurrent:(id)sender {
    
    [self clearImage];
    
    if ([self.toogle.title isEqualToString:@"operation"]) {
        [self asyncConcurrentUseDispatch];
    }else
    {
        [self concurrentUseOperatoin];
    }
}


//下面几个Action根据BarButtonItem的title判断：
//  当前是使用dispatch还是operation；
//  队列当前状态是suspend还是resumed；

//根据title 在dispatch和operation中切换，用来使用不同的技术进行测试
- (IBAction)toogleTechnology:(id)sender {
    UIBarButtonItem *item = (UIBarButtonItem*)sender;
    if ([item.title isEqualToString:@"dispatch"]) {
        item.title = @"operation";
    }else
    {
        item.title = @"dispatch";
    }
    self.pause.title = @"pause";
}
//根据title 进行暂停和恢复
- (IBAction)pause:(id)sender {
    if ([self.pause.title isEqualToString:@"pause"]) {
        if ([self.toogle.title isEqualToString:@"operation"]) {
            if (self.dispatchQueue) {
                dispatch_suspend(self.dispatchQueue);
                self.pause.title = @"resume";
            }
        }else
        {
            [self.operationQueue setSuspended:YES];
            self.pause.title = @"resume";
        }
    }else
    {
        if ([self.toogle.title isEqualToString:@"operation"]) {
            if (self.dispatchQueue) {
                dispatch_resume(self.dispatchQueue);
                self.pause.title = @"pause";
            }
        }else
        {
            [self.operationQueue setSuspended:NO];
            self.pause.title = @"pause";
        }
    }
}

//对opertaion进行cancel操作
- (IBAction)cancel:(id)sender {
    if ([self.toogle.title isEqualToString:@"dispatch"]) {
        [self.operationQueue cancelAllOperations];
    }
}


#pragma mark - status bar

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}



@end
