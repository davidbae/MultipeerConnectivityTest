//
//  DBUSessionContainer.m
//  DBUMCAdvertiser
//
//  Created by David Bae on 2014. 1. 4..
//  Copyright (c) 2014년 David Bae. All rights reserved.
//
@import MultipeerConnectivity;

#import "DBUSessionContainer.h"
#import "DBUTranscript.h"

#define LOGMESSAGE(__STR__) [self.delegate logMessage:__STR__];
#define UPDATESTATUS        [self.delegate updateStatus:self.session browser:self.browser advertiser:self.advertiser];
#define SERVICE_TYPE @"dbu_imgtran"

@interface DBUSessionContainer()
{
    MCPeerID *_myPeerID;
    NSString *_serviceType;
    
    NSMutableDictionary *_foundPeersDictionary;
    NSArray *_invitationArray;
    
    void (^_invitationHandler)(BOOL, MCSession *);
}
//
@property (retain, nonatomic) MCNearbyServiceBrowser *browser;

// Framework UI class for handling incoming invitations
@property (retain, nonatomic) MCAdvertiserAssistant *advertiserAssistant;
@property (retain, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@end


@implementation DBUSessionContainer


static DBUSessionContainer *sharedInstance = nil;
// Get the shared instance and create it if necessary.
+ (DBUSessionContainer *)sharedInstance {
    if (nil != sharedInstance) {
        return sharedInstance;
    }
    
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        sharedInstance = [[DBUSessionContainer alloc] initWithDisplayName:[UIDevice currentDevice].name serviceType:SERVICE_TYPE];
    });
    
    return sharedInstance;
}

- (id)initWithDisplayName:(NSString *)displayName serviceType:(NSString *)serviceType
{
    if (self = [super init]) {
        // Create the peer ID with user input display name.  This display name will be seen by other browsing peers
        _myPeerID = [[MCPeerID alloc] initWithDisplayName:displayName];
        // Create the session that peers will be invited/join into.  You can provide an optinal security identity for custom authentication.  Also you can set the encryption preference for the session.
        _serviceType = serviceType;
        
        [self startSession];
        //[self startAdvertisingPeer];
        
        _foundPeersDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}
// On dealloc we should clean up the session by disconnecting from it.
- (void)dealloc
{
    [self stopAdvertisingPeer];
    [self stopSession];
}

- (MCPeerID *)peerID
{
    return _session.myPeerID;
}

// Instance method for sending a string bassed text message to all remote peers
- (DBUTranscript *)sendMessage:(NSString *)message
{
    // Convert the string into a UTF8 encoded data
    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    // Send text message to all connected peers
    return [self sendData:messageData];
}
- (DBUTranscript *) sendData:(NSData *)data
{
    // Send data to all connected peers
    NSError *error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    // Check the error return to know if there was an issue sending data to peers.  Note any peers in the 'toPeers' array argument are not connected this will fail.
    if (error) {
        //NSLog(@"Error sending message to peers [%@]", error);
        [self.delegate logMessage:[NSString stringWithFormat:@"<<< Error: %@", error]];
        return nil;
    }
    else {
        // Create a new send transcript
        //NSLog(@"message sent: %@ to peer:%@", data, self.session.connectedPeers);
        [self.delegate logMessage:[NSString stringWithFormat:@"<<< %@ sent to\n%@", data, self.session.connectedPeers]];
        
        DBUTranscript *transcript = [[DBUTranscript alloc] initWithPeerID:_session.myPeerID data:data direction:TRANSCRIPT_DIRECTION_SEND];
        return transcript;
    }
}

// Method for sending image resources to all connected remote peers.  Returns an progress type transcript for monitoring tranfer
- (DBUTranscript *)sendImage:(NSURL *)imageUrl
{
    NSProgress *progress;
    // Loop on connected peers and send the image to each
    for (MCPeerID *peerID in _session.connectedPeers)
    {
        //        imageUrl = [NSURL URLWithString:@"http://images.apple.com/home/images/promo_logic_pro.jpg"];
        // Send the resource to the remote peer.  The completion handler block will be called at the end of sending or if any errors occur
        progress = [self.session sendResourceAtURL:imageUrl withName:[imageUrl lastPathComponent] toPeer:peerID withCompletionHandler:^(NSError *error) {
            // Implement this block to know when the sending resource transfer completes and if there is an error.
            if (error) {
                NSLog(@"Send resource to peer [%@] completed with Error [%@]", peerID.displayName, error);
            }
            else {
                // Create an image transcript for this received image resource
                //Transcript *transcript = [[Transcript alloc] initWithPeerID:_session.myPeerID imageUrl:imageUrl direction:TRANSCRIPT_DIRECTION_SEND];
                //[self.delegate updateTranscript:transcript];
                DBUTranscript *transcript = [[DBUTranscript alloc] initWithPeerID:peerID imageUrl:imageUrl direction:TRANSCRIPT_DIRECTION_SEND];
                [self.delegate updateTranscript:transcript];
            }
        }];
        NSLog(@"sendImage to %@, %@", peerID.displayName, [imageUrl lastPathComponent]);
    }
    // Create an outgoing progress transcript.  For simplicity we will monitor a single NSProgress.  However users can measure each NSProgress returned individually as needed
    //Transcript *transcript = [[Transcript alloc] initWithPeerID:_session.myPeerID imageName:[imageUrl lastPathComponent] progress:progress direction:TRANSCRIPT_DIRECTION_SEND];
    DBUTranscript *transcript = [[DBUTranscript alloc] initWithPeerID:_session.myPeerID imageName:[imageUrl lastPathComponent] progress:progress direction:TRANSCRIPT_DIRECTION_SEND];
    return transcript;
}

- (void) startSession
{
    if (!_session)
    {
        _session = [[MCSession alloc] initWithPeer:_myPeerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        if (_session) {
            [self.delegate logMessage:@"Session created"];
        }
        // Set ourselves as the MCSessionDelegate
        _session.delegate = self;
    }else{
        [self.delegate logMessage:@"Session already exist"];
    }
    
    UPDATESTATUS
}
- (void) stopSession
{
    if (_session)
    {
        [_session disconnect];
        _session.delegate = nil;
        _session = nil;
        [self.delegate logMessage:@"Session disconnect and destroy"];
    }else{
        [self.delegate logMessage:@"Session is nil"];
    }
    
    UPDATESTATUS
}
- (void) disconnect
{
    if (_session) {
        [_session disconnect];
        [self.delegate logMessage:@"Session disconnect"];
    }else{
        [self.delegate logMessage:@"Session is nil"];
    }
}
- (void)startBrowser
{
    if(!_browser) // 없으면 만든다.
    {
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_myPeerID serviceType:_serviceType];
        _browser.delegate = self;
        //[_browser startBrowsingForPeers];
        NSLog(@"Browser startBrowsingForPeers: \n%@", _browser);
        [self.delegate logMessage:[NSString stringWithFormat:@"Browser start:%@", _browser.myPeerID.displayName]];
    }else{
        [_browser startBrowsingForPeers];
        NSLog(@"Browser already exist. just startBrowsingForPeers: \n%@", _browser);
    }
    UPDATESTATUS
}
-(void)stopBrowser
{
    if(_browser){
        [_browser stopBrowsingForPeers];
        _browser.delegate = nil;
        _browser = nil;
        [self.delegate logMessage:@"Stop Browsing and Destroy"];
    }else{
        [self.delegate logMessage:@"Browser is nil"];
    }
    UPDATESTATUS
}
- (void)startBrowsingForPeers
{
    if(_browser)
    {
        [_browser startBrowsingForPeers];
        NSLog(@"Browser startBrowsingForPeers: \n%@", _browser);
        [self.delegate logMessage:[NSString stringWithFormat:@"Browser startBrowsingForPeers:%@", _browser.myPeerID.displayName]];
    }else{
        [self.delegate logMessage:@"Browser is nil"];
    }
    
    UPDATESTATUS
}
- (void)stopBrowsingForPeers
{
    if (_browser) {
        [_foundPeersDictionary removeAllObjects];
        [self.delegate updateFoundPeers:nil];
        [_browser stopBrowsingForPeers];
        [self.delegate logMessage:@"Browser stopBrowsingForPeers"];
    }else{
        [self.delegate logMessage:@"Browser is nil"];
    }
    UPDATESTATUS
}

- (void)inviteFoundPeers
{
    NSArray *connectedPeers = _session.connectedPeers;
    NSArray *foundPeers = [_foundPeersDictionary allKeys];
    for (MCPeerID *peerID in foundPeers) {
        if([connectedPeers containsObject:peerID]){
            NSLog(@"Can't invite: PeerID(%@) is already connected (containsObject)", peerID.displayName);
        }else{
            BOOL peerIsInConnectedPeers = NO;
            for (MCPeerID *peer in connectedPeers) {
                if ([peer.displayName isEqualToString:peerID.displayName]) {
                    peerIsInConnectedPeers = YES;
                }
            }
            if (!peerIsInConnectedPeers)
            {
                [self.delegate logMessage:[NSString stringWithFormat:@"Found Peer %@ and send invitation", peerID.displayName]];
                
            }else{
                [self.delegate logMessage:[NSString stringWithFormat:@"Found Peer %@ but already exist, send invitation", peerID.displayName]];
            }
            [_browser invitePeer:peerID
                       toSession:_session
                     withContext:[@"invitation" dataUsingEncoding:NSUTF8StringEncoding]
                         timeout:0];
        }
    }
}
- (void) startAdvertiser
{
    if (!_advertiser)
    {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"DBUMCAdvertiser", @"app", _myPeerID.displayName, @"displayName", nil];
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_myPeerID discoveryInfo:info serviceType:_serviceType];
        _advertiser.delegate = self;
        NSString *log = [NSString stringWithFormat:@"Advertiser created: %@,%@",  _advertiser.myPeerID.displayName, _advertiser.serviceType];
        LOGMESSAGE(log);
    }else{
        LOGMESSAGE(@"Advertiser is already existed");
    }
    UPDATESTATUS;
}
- (void) stopAdvertiser
{
    if (_advertiser) {
        [_advertiser stopAdvertisingPeer];
        _advertiser.delegate = nil;
        _advertiser = nil;
        LOGMESSAGE(@"Adveriser stopAdvertisingPeer and destory");
    }else{
        LOGMESSAGE(@"Advertiser is nil");
    }
    
    UPDATESTATUS
}
- (void) startAdvertisingPeer
{
    if (_advertiser)
    {
        [_advertiser startAdvertisingPeer];
        NSString *log = [NSString stringWithFormat:@"Advertiser startAdvertisingPeer: %@,%@",  _advertiser.myPeerID.displayName, _advertiser.serviceType];
        LOGMESSAGE(log);
    }else{
        LOGMESSAGE(@"Advertiser is nil");
    }
    
    UPDATESTATUS;
}
- (void) stopAdvertisingPeer
{
    /*
    [_advertiserAssistant stop];
    /*/
    if (_advertiser)
    {
        [_advertiser stopAdvertisingPeer];
        NSLog(@"Advertiser stopAdvertisingPeer");
    }else{
        NSLog(@"Advertiser already stop");
    }
    //*/
    UPDATESTATUS;
}

- (void)info
{
    NSLog(@"Information:\nsession:%@\nbrowser:%@\nadvertiser:%@", _session, _browser, _advertiser);
    NSString *logStr;
    if(_session){
        NSArray *peers = _session.connectedPeers;
        logStr = [NSString stringWithFormat:@"Peers:\n%@", peers];
    }else{
        logStr = [NSString stringWithFormat:@"Session is nil"];
    }
    LOGMESSAGE(logStr);
    if (_browser) {
        logStr = [NSString stringWithFormat:@"Browser:%@", _browser.serviceType];
    }else{
        logStr = [NSString stringWithFormat:@"Browser is nil"];
    }
    LOGMESSAGE(logStr);
    if (_advertiser) {
        logStr = [NSString stringWithFormat:@"Advertiser:%@", _advertiser.serviceType];
    }else{
        logStr = [NSString stringWithFormat:@"Advertiser is nil"];
    }
    LOGMESSAGE(logStr);
    
    UPDATESTATUS;
}
#pragma mark - MCNearbyServiceBrowserDelegate
- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSString *log;
    if ([[_foundPeersDictionary allKeys] containsObject:peerID])
    {
        log = [NSString stringWithFormat:@"found PeerID(%@) but already found", peerID.displayName];
    }else{
        [_foundPeersDictionary setObject:info forKey:peerID];
        log = [NSString stringWithFormat:@"found PeerID(%@)", peerID.displayName];
    }
    LOGMESSAGE(log);
    
    [self.delegate updateFoundPeers:[_foundPeersDictionary allKeys]];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{   //Advertiser가 stopAdvertisingForPeer를 호출하여 광고를 중단했을 경우 호출되며,
    //연결하려는 client가 더 연결을 하기 어려울 때 호출됨. 추가 적으로 연결하면 안됨.
    NSString *log;
    if([[_foundPeersDictionary allKeys] containsObject:peerID] ){
        log = [NSString stringWithFormat:@"browser lostPeer: %@", peerID.displayName];
        [_foundPeersDictionary removeObjectForKey:peerID];
    }else{
        log = [NSString stringWithFormat:@"browser lostPeer: %@ but not in list", peerID.displayName];
    }
    LOGMESSAGE(log);
    [self.delegate updateFoundPeers:[_foundPeersDictionary allKeys]];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"didNotStartBrowsingForPeers:%@", error.localizedDescription);
}

#pragma mark - MCNearbyServiceAdvertiserDelegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"didNotStartAdvertisingPeer: %@", [error description]);
}
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"didReceiveInvitationFromPeer:%@", peerID.displayName);
    if( context )
    {
        NSLog(@"                 context:%@", [NSString stringWithCString:[context bytes] encoding:NSUTF8StringEncoding]);
    }
    if(_session){
        [self.delegate logMessage:[NSString stringWithFormat:@"Invitation received from %@", peerID.displayName]];
        
        if (!_invitationArray) {
            _invitationArray = [NSArray arrayWithObject:[invitationHandler copy]];
        }
        _invitationHandler = invitationHandler;
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Invitation"
                                  message:[NSString stringWithFormat:@"from %@", peerID.displayName]
                                  delegate:self
                                  cancelButtonTitle:@"NO"
                                  otherButtonTitles:@"YES", nil];
        [alertView show];
        alertView.tag = 2;
        
        NSLog(@"                     accepts: YES");
    }else{
        invitationHandler(NO, _session);
        NSLog(@"                     accepts: NO");
    }
    NSLog(@"                     session:%@", _session);
    
    //[self stopAdvertisingPeer]; //연결 된 후에 중단한다.
}
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // retrieve the invitationHandler
    // get user decision
    BOOL accept = (buttonIndex != alertView.cancelButtonIndex) ? YES : NO;
    // respond
    void (^invitationHandler)(BOOL, MCSession *) = [_invitationArray objectAtIndex:0];
    NSLog(@"invitationHandler:%@", invitationHandler);
    //invitationHandler(accept, _session);
    _invitationHandler(accept, _session);
    [self.delegate logMessage:[NSString stringWithFormat:@"invitationHandler(%@)", (accept)?@"YES":@"NO"]];
}

#pragma mark - MCSessionDelegate

- (NSString *)stringForPeerConnectionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"MCSessionStateConnected";
        case MCSessionStateConnecting:
            return @"MCSessionStateConnecting";
        case MCSessionStateNotConnected:
            return @"MCSessionStateNotConnected";
        default:
            break;
    }
    return @"NoneState";
}
- (void)session:(MCSession *)session
           peer:(MCPeerID *)peerID
 didChangeState:(MCSessionState)state
{
    NSLog(@"Peer [%@] changed state to %@", peerID.displayName, [self stringForPeerConnectionState:state]);
    NSLog(@"       Session: %@", session);
    
    switch (state) {
        case MCSessionStateConnected:{
            
            NSArray *peers = _session.connectedPeers;
            if(![peers containsObject:peerID]){
                [_session connectPeer:peerID withNearbyConnectionData:nil];
                [self.delegate logMessage:[NSString stringWithFormat:@"Peer(%@) is connected but not in connectedPeers(%@)\n connectPeer", peerID.displayName, peers]];
            }else{
                //[self stopAdvertisingPeer];
                [self.delegate logMessage:[NSString stringWithFormat:@"Peer(%@) is connected", peerID.displayName]];
            }
            break;
        }
        case MCSessionStateConnecting:
            break;
        case MCSessionStateNotConnected:
            //self.sendDataButton.enabled = NO;
            [self.delegate logMessage:[NSString stringWithFormat:@"Peer(%@) is Not connected", peerID.displayName]];
            break;
        default:
            break;
    }
}

- (void)session:(MCSession *)session
 didReceiveData:(NSData *)data
       fromPeer:(MCPeerID *)peerID
{
    NSLog(@"didReceiveData: %@ from peerID:%@", [data description], peerID.displayName);

    // Decode the incoming data to a UTF8 encoded string
    //NSString *receivedMessage = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    //[self.delegate receivedMessage:[NSString stringWithFormat:@">>>[%@]%@",peerID.displayName,receivedMessage]];
    
    DBUTranscript *transcript = [[DBUTranscript alloc] initWithPeerID:peerID data:data direction:TRANSCRIPT_DIRECTION_RECEIVE];
    [self.delegate receivedTranscript:transcript];
    
    //데이터를 받았는데, 연결된 peer가 아닐 경우..
    NSArray *peers = _session.connectedPeers;
    if(![peers containsObject:peerID])
    {
        //연결해봐도 연결이 안됨.
        //[_session connectPeer:peerID withNearbyConnectionData:nil];
    }
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress
{
    NSLog(@"didStartReceivingResourceWithName: %@ fromPeer:%@", resourceName, peerID.displayName);
    //[self.delegate receivingResourceWithName:resourceName fromPeer:peerID withProgress:progress];
    
    DBUTranscript *transcript = [[DBUTranscript alloc] initWithPeerID:peerID imageName:resourceName progress:progress direction:TRANSCRIPT_DIRECTION_RECEIVE];
    
    [self.delegate receivedTranscript:transcript];
}
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream
       withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID
{
    NSLog(@"didREceiveStream: %@, fromPeer:%@", streamName, peerID.displayName);
}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"didFinishReceivingResourceWithName: %@, %@", resourceName, peerID.displayName);
    //[self.delegate receivedResouceWithName:resourceName fromPeer:peerID atURL:localURL withError:error];
    if (error) {
        NSLog(@"Error [%@] receiving resource from peer %@ ", [error localizedDescription], peerID.displayName);
    }else{
        
        // No error so this is a completed transfer.  The resources is located in a temporary location and should be copied to a permenant locatation immediately.
        // Write to documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *copyPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], resourceName];
        if (![[NSFileManager defaultManager] copyItemAtPath:[localURL path] toPath:copyPath error:nil])
        {
            NSLog(@"Error copying resource to documents directory");
        }
        else {
            // Get a URL for the path we just copied the resource to
            NSURL *imageUrl = [NSURL fileURLWithPath:copyPath];
            // Create an image transcript for this received image resource
            DBUTranscript *transcript = [[DBUTranscript alloc] initWithPeerID:peerID imageUrl:imageUrl direction:TRANSCRIPT_DIRECTION_RECEIVE];
            [self.delegate updateTranscript:transcript];
        }
    }
}


- (void) session:(MCSession*)session didReceiveCertificate:(NSArray*)certificate fromPeer:(MCPeerID*)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    if (certificateHandler != nil) {
        certificateHandler(YES);
        NSLog(@"certificateHandler called: %@", certificateHandler);
        [self.delegate logMessage:@"CertificateHandler called"];
    }
}
@end

