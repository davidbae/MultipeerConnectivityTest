//
//  DBUTranscript.h
//  DBUMultipeerTest
//
//  Created by David Bae on 2014. 1. 19..
//  Copyright (c) 2014년 David Bae. All rights reserved.
//

#import <Foundation/Foundation.h>

// Enumeration of transcript directions
typedef enum {
    TRANSCRIPT_DIRECTION_SEND = 0,
    TRANSCRIPT_DIRECTION_RECEIVE,
    TRANSCRIPT_DIRECTION_LOCAL // for admin messages. i.e. "<name> connected"
} TranscriptDirection;

@interface DBUTranscript : NSObject

@property (readonly, nonatomic) TranscriptDirection direction;
@property (nonatomic, readonly) MCPeerID *peerID;
@property (nonatomic, readonly) NSData* data;

@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, readonly) NSURL *imageURL;
@property (nonatomic, readonly) NSProgress *progress;

// Initializer used for sent/received text messages
- (id)initWithPeerID:(MCPeerID *)peerID data:(NSData *)data direction:(TranscriptDirection)direction;
// Initializer used for sent/received image resources
- (id)initWithPeerID:(MCPeerID *)peerID imageUrl:(NSURL *)imageUrl direction:(TranscriptDirection)direction;
// Initialized used for sending/receiving image resources.  This tracks their progress
- (id)initWithPeerID:(MCPeerID *)peerID imageName:(NSString *)imageName progress:(NSProgress *)progress direction:(TranscriptDirection)direction;

@end
