//
//  ViewController.m
//  SocketTest
//
//  Created by Jeffrey Klarfeld on 2/24/14.
//  Copyright (c) 2014 Jeffrey Klarfeld. All rights reserved.
//

#import "ViewController.h"
#import <arpa/inet.h>
#import "GCDAsyncSocket.h"

@interface ViewController ()

@property (strong, nonatomic) NSNetServiceBrowser   *netBrowser;
@property (strong, nonatomic) NSNetService          *netService;
@property (strong, nonatomic) NSMutableArray        *serverAddresses;
@property (strong, nonatomic) GCDAsyncSocket        *socket;

@end

@implementation ViewController

bool connected = NO;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initEverything];
}

- (void)initEverything
{
    _netBrowser = [[NSNetServiceBrowser alloc] init];
    [_netBrowser setDelegate:self];
    
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                         delegateQueue:dispatch_get_main_queue()
                                           socketQueue:_socketQueue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)Connect:(UIButton *)sender
{
    if (connected)
    {
        [self disconnect];
    }
    else
    {
        [self connectToBonjour];
    }
}

- (IBAction)readFromSocket:(UIButton *)sender
{
    [_socket readDataWithTimeout:-1 tag:0];
}

- (void)disconnect
{
    connected = NO;
}

- (void)connectToBonjour
{
    [_statusLabel setText:@"Connecting..."];
    connected = NO;
    
    [_netBrowser searchForServicesOfType:@"_OctoMeow-Server._tcp" inDomain:@"local."];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServ didNotSearch:(NSDictionary *)errorDict
{
    NSLog(@"netServiceBrowser: %@ didn't search: %@", netServ, errorDict);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServBrowser
           didFindService:(NSNetService *)netServ
               moreComing:(BOOL)moreComing
{
    NSLog(@"didFindService: %@, and moreComing=%d", netServ, moreComing);
    [_statusLabel setText:@"A Server was found!"];
    
    
    if (_netService == nil)
    {
        NSLog(@"Resolving...");
        [_statusLabel setText:@"Resolving..."];
        _netService = netServ;
        [_netService setDelegate:self];
        [_netService resolveWithTimeout:5.0];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	NSLog(@"DidRemoveService: %@", [netService name]);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
	NSLog(@"DidStopSearch");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"netServiceDidResolveAddress: %@", sender);
    NSString *stringToSet = [NSString stringWithFormat:@"%@%@ on port %ld", [sender domain], [sender name], (long)[sender port]];
    
    for (NSData *address in [sender addresses])
    {
        //NSString *parsedAddress = [[NSString alloc] initWithData:address encoding:NSUTF8StringEncoding];
        
        struct sockaddr_in *socketAddress = (struct sockaddr_in *) [address bytes];
        NSLog(@"Service name: %@ , ip: %s , port %li", [sender name], inet_ntoa(socketAddress->sin_addr), (long)[sender port]);
    }
    
    [_statusLabel setText:stringToSet];
    
    [self connectToSocketWithAddresses:[sender addresses]];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	NSLog(@"DidNotResolve");
}

- (void)connectToSocketWithAddresses:(NSArray *)addresses
{
    for (NSData *address in addresses)
    {
        if (!connected)
        {
            NSError *connectError;
            
            if (![_socket connectToAddress:address error:&connectError])
            //if (![_socket connectToHost:@"10.0.1.16" onPort:9000 error:&connectError])
            {
                NSLog(@"Error connecting: %@", connectError);
            }
            else
            {
                connected = YES;
            }
        }
    }
}

#pragma mark -Socket Delegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"Connected!");
    
    [_statusLabel setText:@"Connected!"];
    
    NSString *hello = @"Hello from SocketTest!";
    NSData *writeData = [hello dataUsingEncoding:NSUTF8StringEncoding];
    
    [_socket writeData:writeData withTimeout:-1.0 tag:0];
    NSData *term = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
    //[_socket readDataToData:term withTimeout:-1 tag:0];
    [_socket readDataWithTimeout:-1 tag:0];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [_MessageBox setText:msg];
    NSLog(@"Read . tag = %ld, msg = %@",tag,msg);
    [_socket readDataWithTimeout:-1 tag:0];
    
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"send . tag = %ld",tag);
    //[_socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1.0 tag:0];
    [_socket readDataWithTimeout:-1 tag:0];
}


/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Disconnected .");
    [_statusLabel setText:@"Disconnected"];
    
}

@end
