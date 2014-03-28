//
//  ViewController.h
//  SocketTest
//
//  Created by Jeffrey Klarfeld on 2/24/14.
//  Copyright (c) 2014 Jeffrey Klarfeld. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"
#import <dispatch/dispatch.h>
#import <PebbleKit/PebbleKit.h>

@interface ViewController : UIViewController <NSNetServiceBrowserDelegate, NSNetServiceDelegate, PBWatchDelegate, PBPebbleCentralDelegate, PBDataLoggingServiceDelegate>

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UITextView *MessageBox;
@property (strong, atomic) dispatch_queue_t socketQueue;

- (IBAction)Connect:(UIButton *)sender;
- (IBAction)readFromSocket:(UIButton *)sender;
@end