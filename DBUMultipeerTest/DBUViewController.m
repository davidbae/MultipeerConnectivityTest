//
//  DBUViewController.m
//  DBUMultipeerTest
//
//  Created by David Bae on 2014. 1. 8..
//  Copyright (c) 2014년 David Bae. All rights reserved.
//
@import MultipeerConnectivity;

#import "DBUViewController.h"
#import "DBUSessionContainer.h"

@interface DBUViewController () <DBUSessionContainerDelegate>
{
    DBUSessionContainer *_sessionContainer;
}

@property (strong, nonatomic) IBOutlet UIButton *browserButton;
@property (strong, nonatomic) IBOutlet UIButton *startBrowsingButton;
@property (strong, nonatomic) IBOutlet UIButton *stopBrowsingButton;
@property (strong, nonatomic) IBOutlet UIButton *inviteButton;
@property (strong, nonatomic) IBOutlet UITextView *foundPeersTextView;

@property (strong, nonatomic) IBOutlet UIButton *sessionButton;
@property (strong, nonatomic) IBOutlet UIButton *disconnectSessionButton;
@property (strong, nonatomic) IBOutlet UIButton *sendDataButton;

@property (strong, nonatomic) IBOutlet UIButton *advertiserButton;
@property (strong, nonatomic) IBOutlet UIButton *startAdvertisingButton;
@property (strong, nonatomic) IBOutlet UIButton *stopAdvertisingButton;

@property (strong, nonatomic) IBOutlet UIButton *infoButton;

@property (strong, nonatomic) IBOutlet UITextView *textView;
@end

@implementation DBUViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    _sessionContainer = [[DBUSessionContainer alloc] initWithDisplayName:[UIDevice currentDevice].name serviceType:@"dbutest"];
    _sessionContainer.delegate = self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_sessionContainer info];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) addLog:(NSString *)newLog
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = [NSString stringWithFormat:@"%@\n%@", newLog, self.textView.text];
    });
    //self.textView.text = [NSString stringWithFormat:@"- %@\n%@", newLog, self.textView.text];
    NSLog(@"%@", newLog);
}
- (void) addMessage:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = [NSString stringWithFormat:@"-%@\n%@", msg, self.textView.text];
    });
    //self.textView.text = [NSString stringWithFormat:@"- %@\n%@", newLog, self.textView.text];
    NSLog(@"%@", msg);
}


- (IBAction)createSession:(UIButton *)sender
{
    if ([sender.titleLabel.text isEqualToString:@"Create"]) {
        [_sessionContainer startSession];
    }else{
        [_sessionContainer stopSession];
    }
    
}
- (IBAction)disconnectSession:(UIButton *)sender
{
    [_sessionContainer disconnect];
}
- (IBAction)sendData:(UIButton *)sender
{
    [_sessionContainer sendMessage:[UIDevice currentDevice].name];
}

- (IBAction)createBrowser:(UIButton *)sender
{
    if ([sender.titleLabel.text isEqualToString:@"Create"]) {
        [_sessionContainer startBrowser];
    }else{
        [_sessionContainer stopBrowser];
    }
}
- (IBAction)startBrowser:(id)sender
{
    [_sessionContainer startBrowsingForPeers];
}
- (IBAction)stopBrowser:(id)sender
{
    [_sessionContainer stopBrowsingForPeers];
}
- (IBAction)invite:(id)sender
{
    [_sessionContainer inviteFoundPeers];
}

- (IBAction)createAdvertiser:(UIButton *)sender
{
    if ([sender.titleLabel.text isEqualToString:@"Create"]) {
        [_sessionContainer startAdvertiser];
    }else{
        [_sessionContainer stopAdvertiser];
    }
}
- (IBAction)startAdvertiser:(id)sender
{
    [_sessionContainer startAdvertisingPeer];
}
- (IBAction)stopAdvertiser:(id)sender
{
    [_sessionContainer stopAdvertisingPeer];
}

- (IBAction)info:(id)sender
{
    [_sessionContainer info];
}


#pragma mark - DBUSessionContainerDelegate

- (void)receivedMessage:(NSString *)message
{
    [self addMessage:message];
}
- (void)logMessage:(NSString *)message
{
    [self addLog:[@"        " stringByAppendingString:message]];
}
- (void)updateStatus:(MCSession *)session browser:(MCNearbyServiceBrowser *)browser advertiser:(MCNearbyServiceAdvertiser *)advertiser
{
    if (session) {
        [_sessionButton setTitle:@"Destroy" forState:UIControlStateNormal];
        _disconnectSessionButton.enabled = YES;
        _sendDataButton.enabled = YES;
    }else{
        [_sessionButton setTitle:@"Create" forState:UIControlStateNormal];
        _disconnectSessionButton.enabled = NO;
        _sendDataButton.enabled = NO;
    }
    
    if (browser) {
        [_browserButton setTitle:@"Destroy" forState:UIControlStateNormal];
        _startBrowsingButton.enabled = YES;
        _stopBrowsingButton.enabled = YES;
        _inviteButton.enabled = YES;
    }else{
        [_browserButton setTitle:@"Create" forState:UIControlStateNormal];
        _startBrowsingButton.enabled = NO;
        _stopBrowsingButton.enabled = NO;
        _inviteButton.enabled = NO;
    }
    
    if (advertiser) {
        [_advertiserButton setTitle:@"Destroy" forState:UIControlStateNormal];
        _startAdvertisingButton.enabled = YES;
        _stopAdvertisingButton.enabled = YES;
    }else{
        [_advertiserButton setTitle:@"Create" forState:UIControlStateNormal];
        _startAdvertisingButton.enabled = NO;
        _stopAdvertisingButton.enabled = NO;
    }
}
- (void)updateFoundPeers:(NSArray *)peers
{
    [self.foundPeersTextView setText:@""];
    for (MCPeerID *peer in peers)
    {
        if ([self.foundPeersTextView.text isEqualToString:@""])
        {
            self.foundPeersTextView.text = [NSString stringWithFormat:@"- %@", peer.displayName];
        }else{
            self.foundPeersTextView.text = [NSString stringWithFormat:@"%@\n- %@", self.foundPeersTextView.text, peer.displayName];
        }
    }
}

@end
