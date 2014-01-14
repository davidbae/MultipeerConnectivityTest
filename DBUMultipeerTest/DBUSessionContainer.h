//
//  DBUSessionContainer.h
//  DBUMCAdvertiser
//
//  Created by David Bae on 2014. 1. 4..
//  Copyright (c) 2014년 David Bae. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DBUSessionContainerDelegate;

@interface DBUSessionContainer : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, UIAlertViewDelegate, MCNearbyServiceBrowserDelegate>

@property (readonly, nonatomic) MCSession *session;
@property (assign, nonatomic) id<DBUSessionContainerDelegate> delegate;

// Designated initializer
- (id)initWithDisplayName:(NSString *)displayName serviceType:(NSString *)serviceType;
// Method for sending text messages to all connected remote peers.  Returna a message type transcript

- (MCPeerID *)peerID;

- (NSData *)sendMessage:(NSString *)message;
// Method for sending image resources to all connected remote peers.  Returns an progress type transcript for monitoring tranfer
- (NSData *)sendImage:(NSURL *)imageUrl;

- (void) startBrowser;
- (void) stopBrowser;
- (void) startBrowsingForPeers;
- (void) stopBrowsingForPeers;
- (void) inviteFoundPeers;

- (void) startAdvertiser;
- (void) stopAdvertiser;
- (void) startAdvertisingPeer;
- (void) stopAdvertisingPeer;

- (void) startSession;
- (void) stopSession;
- (void) disconnect;

- (void) info;
@end

// Delegate protocol for updating UI when we receive data or resources from peers.
@protocol DBUSessionContainerDelegate <NSObject>

// Method used to signal to UI an initial message, incoming image resource has been received
//- (void)receivedTranscript:(Transcript *)transcript;
// Method used to signal to UI an image resource transfer (send or receive) has completed
//- (void)updateTranscript:(Transcript *)transcript;

- (void) receivedMessage:(NSString *)message;
- (void) logMessage:(NSString *)message;

- (void) updateStatus:(MCSession *)session browser:(MCNearbyServiceBrowser*)browser advertiser:(MCNearbyServiceAdvertiser*)advertiser;
- (void)updateFoundPeers:(NSArray *)peers;
@end
