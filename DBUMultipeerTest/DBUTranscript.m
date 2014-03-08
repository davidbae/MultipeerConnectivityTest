//
//  DBUTranscript.m
//  DBUMultipeerTest
//
//  Created by David Bae on 2014. 1. 19..
//  Copyright (c) 2014년 David Bae. All rights reserved.
//
@import MultipeerConnectivity;

#import "DBUTranscript.h"

// KVO path strings for observing changes to properties of NSProgress
static NSString * const kProgressCancelledKeyPath          = @"cancelled";
static NSString * const kProgressCompletedUnitCountKeyPath = @"completedUnitCount";

@implementation DBUTranscript

// Designated initializer with all properties
- (id)initWithPeerID:(MCPeerID *)peerID data:(NSData *)data imageName:(NSString *)imageName imageUrl:(NSURL *)imageUrl progress:(NSProgress *)progress direction:(TranscriptDirection)direction
{
    if (self = [super init]) {
        _peerID = peerID;
        _data = data;
        _direction = direction;
        _imageURL = imageUrl;
        _progress = progress;
        _imageName = imageName;
    }
    
    if (_progress) {
        // Add KVO observer for the cancelled and completed unit count properties of NSProgress
        [_progress addObserver:self forKeyPath:kProgressCancelledKeyPath options:NSKeyValueObservingOptionNew context:NULL];
        [_progress addObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    // stop KVO
    [_progress removeObserver:self forKeyPath:kProgressCancelledKeyPath];
    [_progress removeObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath];
    _progress = nil;
}

// Initializer used for sent/received text messages
- (id)initWithPeerID:(MCPeerID *)peerID data:(NSData *)data direction:(TranscriptDirection)direction
{
    return [self initWithPeerID:peerID data:data imageName:nil imageUrl:nil progress:nil direction:direction];
}

// Initializer used for sent/received images resources
- (id)initWithPeerID:(MCPeerID *)peerID imageUrl:(NSURL *)imageUrl direction:(TranscriptDirection)direction
{
    return [self initWithPeerID:peerID data:nil imageName:[imageUrl lastPathComponent] imageUrl:imageUrl progress:nil direction:direction];
}

- (id)initWithPeerID:(MCPeerID *)peerID imageName:(NSString *)imageName progress:(NSProgress *)progress direction:(TranscriptDirection)direction
{
    return [self initWithPeerID:peerID data:nil imageName:imageName imageUrl:nil progress:progress direction:direction];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSProgress *progress = object;
    
    // Check which KVO key change has fired
    if ([keyPath isEqualToString:kProgressCancelledKeyPath]) {
        // Notify the delegate that the progress was cancelled
        //[self.delegate observerDidCancel:self];
        NSLog(@"progress observerDidCancel:%@", keyPath);
    }
    else if ([keyPath isEqualToString:kProgressCompletedUnitCountKeyPath]) {
        // Notify the delegate of our progress change
        //[self.delegate observerDidChange:self];
        NSLog(@"progress observerDidChange: %0.2f, %lld", (float)(_progress.completedUnitCount*100)/_progress.totalUnitCount, _progress.completedUnitCount);
        if (progress.completedUnitCount == progress.totalUnitCount) {
            // Progress completed, notify delegate
            //[self.delegate observerDidComplete:self];
            NSLog(@"progress observerDidComplete:self: :%lld", _progress.completedUnitCount);
        }
    }
}
@end
