//
//  PeripheralInfo.h
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/17.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralInfo : NSObject

@property (nonatomic,strong) CBUUID *serviceUUID;
@property (nonatomic,strong) NSMutableArray<CBCharacteristic *> *characteristics;

@end
