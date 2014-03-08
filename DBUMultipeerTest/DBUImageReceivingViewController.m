//
//  DBUImageReceivingViewController.m
//  DBUMultipeerTest
//
//  Created by David Bae on 2014. 1. 18..
//  Copyright (c) 2014년 David Bae. All rights reserved.
//

#import "DBUImageReceivingViewController.h"

static NSString * const kProgressCancelledKeyPath          = @"cancelled";
static NSString * const kProgressCompletedUnitCountKeyPath = @"completedUnitCount";


@interface DBUImageReceivingViewController ()
{
    NSProgress *_progress;
}

@property (strong, nonatomic) IBOutlet UILabel *imageName;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation DBUImageReceivingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setProgress:(NSProgress *)progress
{
    if (_progress) {
        // stop KVO
        [_progress removeObserver:self forKeyPath:kProgressCancelledKeyPath];
        [_progress removeObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath];
        _progress = nil;
    }
    
    _progress = progress;
    
    [_progress addObserver:self forKeyPath:kProgressCancelledKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    [_progress addObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath options:NSKeyValueObservingOptionNew context:NULL];

}
- (void)dealloc
{
    // stop KVO
    [_progress removeObserver:self forKeyPath:kProgressCancelledKeyPath];
    [_progress removeObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath];
    _progress = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSProgress *progress = object;
    
    // Check which KVO key change has fired
    if ([keyPath isEqualToString:kProgressCancelledKeyPath]) {
        // Notify the delegate that the progress was cancelled
        //[self.delegate observerDidCancel:self];
        NSLog(@"progress canceled");

    }
    else if ([keyPath isEqualToString:kProgressCompletedUnitCountKeyPath]) {
        // Notify the delegate of our progress change
        //[self.delegate observerDidChange:self];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the progress bar with the latest completion %
            _progressView.progress = _progress.fractionCompleted;
            NSLog(@"progress changed completedUnitCount[%lld]", _progress.completedUnitCount);
        });

        if (progress.completedUnitCount == progress.totalUnitCount) {
            // Progress completed, notify delegate
            //[self.delegate observerDidComplete:self];
            NSLog(@"progress complete");
        }
    }
}
@end
