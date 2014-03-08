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
#import "DBUTranscript.h"

@interface DBUViewController () <DBUSessionContainerDelegate>
{
    DBUSessionContainer *_sessionContainer;
    NSMutableArray *_transcripts;
    NSMutableDictionary *_transcriptIndex;
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

@property (strong, nonatomic) IBOutlet UITextField *textField;



@end

@implementation DBUViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    _sessionContainer = [[DBUSessionContainer alloc] initWithDisplayName:[UIDevice currentDevice].name serviceType:@"dbutest"];
    _sessionContainer.delegate = self;
    
    self.textField.delegate = self;
    
    _transcripts = [[NSMutableArray alloc] init];
    _transcriptIndex = [[NSMutableDictionary alloc] init];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_sessionContainer info];
    
    // Listen for will show/hide notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Stop listening for keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void) insertTranscript:(DBUTranscript *)transcript
{
    [_transcripts addObject:transcript];
    if( nil != transcript.progress )
    {
        //진행 중인 것에 대해서는 중간에 업데이트를 해줘야 하므로, Dictionary에 이름으로 저장해 둔다.
        NSNumber *index = [[NSNumber alloc] initWithFloat:(_transcripts.count-1)];
        [_transcriptIndex setObject:index forKey:transcript.imageName];
    }
    //TableView에 표현한다면, 여기에 추가 row를 입력하는 부분이 있어야 한다.
    
    //Log
    
    if (transcript.data) {
        NSString *message = [[NSString alloc] initWithData:transcript.data encoding: NSUTF8StringEncoding];
        switch (transcript.direction) {
            case TRANSCRIPT_DIRECTION_LOCAL:
                break;
            case TRANSCRIPT_DIRECTION_SEND:
                [self addLog:[NSString stringWithFormat:@"<<<[%@] %@",transcript.peerID.displayName,message]];
                break;
            case TRANSCRIPT_DIRECTION_RECEIVE:
                [self addLog:[NSString stringWithFormat:@">>>[%@] %@",transcript.peerID.displayName,message]];
                break;
            default:
                break;
        }
    }else if (transcript.imageURL){
        switch (transcript.direction) {
            case TRANSCRIPT_DIRECTION_LOCAL:
                break;
            case TRANSCRIPT_DIRECTION_SEND:
                [self addLog:[NSString stringWithFormat:@"<<<[%@] sent image:%@",transcript.peerID.displayName, transcript.imageURL]];
                break;
            case TRANSCRIPT_DIRECTION_RECEIVE:
                [self addLog:[NSString stringWithFormat:@">>>[%@] received image:%@",transcript.peerID.displayName, transcript.imageURL]];
                break;
            default:
                break;
        }
    }else if(transcript.progress){
        switch (transcript.direction) {
            case TRANSCRIPT_DIRECTION_LOCAL:
                break;
            case TRANSCRIPT_DIRECTION_SEND:
                [self addLog:[NSString stringWithFormat:@"<<<[%@] sending image:%@",transcript.peerID.displayName, transcript.imageName]];
                break;
            case TRANSCRIPT_DIRECTION_RECEIVE:
                [self addLog:[NSString stringWithFormat:@">>>[%@] receiving image:%@",transcript.peerID.displayName, transcript.imageName]];
                break;
            default:
                break;
        }
    }else{
        
    }
}
- (void) sendMessage:(NSString *)message
{
    DBUTranscript *transcript = [_sessionContainer sendMessage:message];
    [self insertTranscript:transcript];
}
#pragma mark - UI Function
// Action method when user presses "send"
- (IBAction)send:(id)sender
{
    // Dismiss the keyboard.  Message will be actually sent when the keyboard resigns.
    [self.textField resignFirstResponder];
    //textField의 textFieldDidEndEditing에서 전송을 하도록 한다.
}
// Action method when user presses the "camera" photo icon.
- (IBAction)takePicture:(id)sender
{
    // Preset an action sheet which enables the user to take a new picture or select and existing one.
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"  destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
    
    // Show the action sheet
    [sheet showFromToolbar:self.navigationController.toolbar];
}

#pragma mark - UITouch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.textField resignFirstResponder];
}

#pragma mark - DBUSessionContainerDelegate

- (void)logMessage:(NSString *)message
{
    [self addLog:[@"        " stringByAppendingString:message]];
    NSLog(@"%@", message);
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

- (void) receivedTranscript:(DBUTranscript *)transcript
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self insertTranscript:transcript];
    });
}
- (void) updateTranscript:(DBUTranscript *)transcript
{
    //imageName으로 된 인덱스를 찾는다.
    // Find the data source index of the progress transcript
    NSNumber *index = [_transcriptIndex objectForKey:transcript.imageName];
    NSUInteger idx = [index unsignedLongValue];

    // Replace the progress transcript with the image transcript
    [_transcripts replaceObjectAtIndex:idx withObject:transcript];
    
    NSLog(@" update: %@, %lld", transcript.imageName, transcript.progress.completedUnitCount);
    switch (transcript.direction) {
        case TRANSCRIPT_DIRECTION_LOCAL:
            break;
        case TRANSCRIPT_DIRECTION_SEND:
            [self addLog:[NSString stringWithFormat:@"<<<[%@] sending image:%@ (%lld)",transcript.peerID.displayName, transcript.imageName, transcript.progress.completedUnitCount]];
            break;
        case TRANSCRIPT_DIRECTION_RECEIVE:
            [self addLog:[NSString stringWithFormat:@">>>[%@] receiving image:%@ (%lld)",transcript.peerID.displayName, transcript.imageName, transcript.progress.completedUnitCount]];            break;
        default:
            break;
    }
    // Reload this particular table view row on the main thread
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
//        [self.tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    });
}

#pragma mark - UIActionSheetDelegate methods

// Override this method to know if user wants to take a new photo or select from the photo library
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    if (imagePicker) {
        // set the delegate and source type, and present the image picker
        imagePicker.delegate = self;
        if (0 == buttonIndex) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        else if (1 == buttonIndex) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        // Problem with camera, alert user
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"Please use a camera enabled device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - UIImagePickerViewControllerDelegate

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// Override this delegate method to get the image that the user has selected and send it view Multipeer Connectivity to the connected peers.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // Don't block the UI when writing the image to documents
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // We only handle a still image
        UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        
        // Save the new image to the documents directory
        NSData *pngData = UIImageJPEGRepresentation(imageToSave, 1.0);
        
        // Create a unique file name
        NSDateFormatter *inFormat = [NSDateFormatter new];
        [inFormat setDateFormat:@"yyMMdd-HHmmss"];
        NSString *imageName = [NSString stringWithFormat:@"image-%@.JPG", [inFormat stringFromDate:[NSDate date]]];
        // Create a file path to our documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [pngData writeToFile:filePath atomically:YES]; // Write the file
        // Get a URL for this file resource
        NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
        
        // Send the resource to the remote peers and get the resulting progress transcript
        //Transcript *transcript = [self.sessionContainer sendImage:imageUrl];
        DBUTranscript *transcript = [_sessionContainer sendImage:imageUrl];
        
        // Add the transcript to the data source and reload
        dispatch_async(dispatch_get_main_queue(), ^{
            [self insertTranscript:transcript];
        });
    });
}

#pragma mark - UITextFieldDelegate methods

// Override to dynamically enable/disable the send button based on user typing
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
//    NSUInteger length = self.textField.text.length - range.length + string.length;
//    if (length > 0) {
//        self.sendMessageButton.enabled = YES;
//    }
//    else {
//        self.sendMessageButton.enabled = NO;
//    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    return YES;
}

// Delegate method called when the message text field is resigned.
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Check if there is any message to send
    if (self.textField.text.length) {
        // Resign the keyboard
        [textField resignFirstResponder];
        
        // Send the message
        //Transcript *transcript = [self.sessionContainer sendMessage:self.messageComposeTextField.text];
        
//        if (transcript) {
//            // Add the transcript to the table view data source and reload
//            [self insertTranscript:transcript];
//        }
//        
//        // Clear the textField and disable the send button
        [self sendMessage:self.textField.text];
        self.textField.text = @"";
//        self.sendMessageButton.enabled = NO;
    }
}

#pragma mark - Toolbar animation helpers

// Helper method for moving the toolbar frame based on user action
- (void)moveToolBarUp:(BOOL)up forKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    
    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    UIToolbar *toolbar = self.navigationController.toolbar;
    [toolbar setFrame:CGRectMake(toolbar.frame.origin.x, toolbar.frame.origin.y + (keyboardFrame.size.height * (up ? -1 : 1)), toolbar.frame.size.width, toolbar.frame.size.height)];
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    // move the toolbar frame up as keyboard animates into view
    [self moveToolBarUp:YES forKeyboardNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // move the toolbar frame down as keyboard animates into view
    [self moveToolBarUp:NO forKeyboardNotification:notification];
}


@end
