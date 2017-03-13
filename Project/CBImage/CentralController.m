//
//  CentralController.m
//  Demo
//
//  Created by Kevin Sum on 14/3/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

#import "CentralController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic,strong) CBCentralManager *centralManager;

/**
 *  外设的服务
 */
@property (strong ,nonatomic) CBService *myService;
/**
 *  外设的特征值
 */
@property (strong ,nonatomic) CBCharacteristic *myCharacterestic;
/**
 *  已被发现的外设
 */
@property (strong ,nonatomic) CBPeripheral *discoveredPeripheral;
/**
 *  待接收的图片数据（以二进制形式保存）
 */
@property (strong ,nonatomic) NSMutableData* picData;
/*
 * 完整的、由二进制数据转化来的图片
 */
@property (strong, nonatomic) IBOutlet UIImageView *picture;

@property (strong, nonatomic) IBOutlet UILabel *peripheralNameLabel;

@property (strong, nonatomic) IBOutlet UILabel *PeripheralUUIDLabel;

@property (strong, nonatomic) IBOutlet UILabel *RSSIValueLabel;

@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;

@end

@implementation CentralController

static NSString *kCharacteresticUUID = @"1F1BD174-ADFF-4592-B726-EC68587BE730";
static NSString *kServiceUUID = @"03320B3D-06AE-4DA3-A6AD-8BC4F3E8E6F5";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //初始化centralManager
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    //初始化图片数据
    _picData = [[NSMutableData alloc]init];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.centralManager stopScan];
    NSLog(@"Scan stopped.");
    [super viewWillDisappear:YES];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
            
        case CBManagerStateUnknown:
            NSLog(@"Current state of the central manager is unknown");
            break;
        case CBManagerStateResetting:
            NSLog(@"Momentarily lost connection.");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"The platform does not support Bluetooth low energy.");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"The app is not AUTHORIZED to use Bluetooth low energy.");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Bluetooth is currently powered off.");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@"Power on. About to start scanning...");
            [self beginScanningForPeripherals];
            break;
        default:
            break;
    }
}

/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
-(void)beginScanningForPeripherals{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]] options:nil];
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"Discovered peripheral:%@",peripheral);
    [self.centralManager stopScan];
    NSLog(@"Stop scanning.");
    
    self.discoveredPeripheral = peripheral;
    
    //prepare for connection
    NSLog(@"Going to connect to this peripheral");
    [self.centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@1}];
    
    /*
     NSString *const CBConnectPeripheralOptionNotifyOnConnectionKey;
     NSString *const CBConnectPeripheralOptionNotifyOnDisconnectionKey;
     NSString *const CBConnectPeripheralOptionNotifyOnNotificationKey;
     */
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"Peripheral connected");
    //post the name and UUID on the UI
    self.peripheralNameLabel.text = peripheral.name;
    
    self.PeripheralUUIDLabel.text =[(CBUUID* )peripheral.identifier UUIDString];
    
    //set up timer to read rssi value
//    self.RSSITimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(readPeripheralRSSI) userInfo:nil repeats:YES];
//    [[NSRunLoop mainRunLoop]addTimer:self.RSSITimer forMode:NSRunLoopCommonModes];
    
    
    NSLog(@"Peripheral connected.Now going to discover the service...");
    
    //clean the data
    [self.picData setLength:0];
    peripheral.delegate = self;
    
    //attempt to discover the service
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            NSLog(@"Discovered target service. Now going to discover characteristics");
            //attemt to discover the characteristics
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (error) {
        NSLog(@"Error occured while discovering services!");
        [self cleanup];
    }
    
    
    NSLog(@"Characteristics have been discovered!");
    for (CBCharacteristic *cha in service.characteristics) {
        if ([cha.UUID isEqual:[CBUUID UUIDWithString:kCharacteresticUUID]]) {
            NSLog(@"Target characteristc have been found.\nGoing to subscribe this value.");
            [peripheral setNotifyValue:YES forCharacteristic:cha];            //通过这个方法，设置notifyValue为yes，我们可以订阅某一特定特征值。
            
            
        }
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"Notification updated!");
    if (error) {
        NSLog(@"Error occured! %@",[error localizedDescription]);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteresticUUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {// Notification has started
        NSLog(@"Notification began on %@", characteristic);
    }
    else {// Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *testStr = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    if ([testStr isEqualToString:@"EOM"]) {//transmission complete
        self.picture.image = [UIImage imageWithData:self.picData];
        
        //unsubscribe
        [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        //cancel connection
        [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    }
    
    else//transmission not complete
        [self.picData appendData:characteristic.value];
    
}

-(void)cleanup{
    
    //if not connected, then we do nothing
    if (self.discoveredPeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteresticUUID]]) {
                        
                        //it is notifying, so unsubscribe it.
                        [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                        
                        
                        //all done, finish
                        return;
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    
}


@end
