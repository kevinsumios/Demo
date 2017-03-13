//
//  PeripheralController.m
//  Demo
//
//  Created by Kevin Sum on 14/3/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

#import "PeripheralController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define NOTIFY_MTU      20

@interface PeripheralController () <CBPeripheralManagerDelegate>

@property (strong,nonatomic)CBPeripheralManager *myPeripheralManager;
@property (strong, nonatomic)CBMutableService *service;
@property (strong ,nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (strong, nonatomic) IBOutlet UIImageView *myImge;//要发送的图片

@property (strong ,nonatomic) UIImagePickerController *imagePickerController;
@property (strong ,nonatomic) NSData *dataToSend;//要发送的图片数据（二进制格式）
@property (readwrite ,nonatomic) NSUInteger sendDataIndex;//发送数据位置索引（表示现在发送到第几个字节了）
@property (readwrite, nonatomic) NSUInteger persentageSent;
@property (strong, nonatomic) IBOutlet UILabel *processLabel;

@end

@implementation PeripheralController

static NSString *kCharacteresticUUID = @"1F1BD174-ADFF-4592-B726-EC68587BE730";
static NSString *kServiceUUID = @"03320B3D-06AE-4DA3-A6AD-8BC4F3E8E6F5";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.myPeripheralManager stopAdvertising];
    [super viewWillDisappear:YES];
    
}

- (IBAction)send:(id)sender {
    self.myPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {//检查外设的状态
        case CBManagerStatePoweredOn:
            NSLog(@"Bluetooth power is on. Start operation.");
            [self setupService];
            break;
        case CBManagerStateResetting:
            NSLog(@"Bluetooth is resetting. Please standby.");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"Your device doesn't support BLE.");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"The use of bluetooth is not authorized by user!");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Please turn on your bluetooth.");
            break;
        case CBManagerStateUnknown:
            NSLog(@"Bluetooth state is unknown.Standby for update.");
            break;
        default:
            break;
    }
    
}

-(void)setupService{
    self.transferCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:kCharacteresticUUID] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotifyEncryptionRequired value:nil permissions:CBAttributePermissionsReadEncryptionRequired];
    
    self.service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:kServiceUUID] primary:YES];
    
    self.service.characteristics = @[self.transferCharacteristic];
    
    [self.myPeripheralManager addService:self.service];
    
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (error) {
        NSLog(@"Error occured while adding up service!");
        return;
    }
    [self.myPeripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[self.service.UUID]}];
    
}

-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    if (error) {
        NSLog(@"Error occured while advertising!");
        return;
    }
    
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"DID subscribe to central.");
    
    //stop advertising
    if ([self.myPeripheralManager isAdvertising]) {
        [self.myPeripheralManager stopAdvertising];
    }
    
    //prepare the data
    NSData *imageData = UIImageJPEGRepresentation(self.myImge.image, 0.6);//这句代码将JPEG图片转化为二进制数据。其中第二个参数表示压缩率。
    self.dataToSend = imageData;
    
    self.sendDataIndex = 0;//将已传送数据索引值清0
    
    //start sending
    [self startSending];
    
}

-(void)startSending{
    
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    if (sendingEOM) {
        //send it
        BOOL didSend = [self.myPeripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        if (didSend) {
            sendingEOM = NO;
            NSLog(@"EOM sent");
//            [self.hudView hide:YES];
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    if (self.sendDataIndex >= self.dataToSend.length) {//no. then done
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    while (didSend) {
        //make the next chunk
        
        //set the amount of data
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        if (amountToSend >= NOTIFY_MTU) {
            amountToSend = NOTIFY_MTU;
        }
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes + self.sendDataIndex length:amountToSend];
        
        
        //send it
        didSend = [self.myPeripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        // It did send, so update our index and sent percentage
        self.sendDataIndex += amountToSend;
        self.persentageSent = self.sendDataIndex * 100 / self.dataToSend.length;
        self.processLabel.text = [NSString stringWithFormat:@"Stand by.Sent:%lu%%",(unsigned long)self.persentageSent];
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            sendingEOM = YES;
            //going to send an eom
            BOOL eomSent = YES;
            eomSent = [self.myPeripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                sendingEOM = NO;
                self.dataToSend = nil;
//                [self.hudView hide:YES];
                NSLog(@"Sent EOM");
            }
            
            //if not sent, then return
            return;
        }
    }
    
}

-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    [self startSending];
    
}

@end
