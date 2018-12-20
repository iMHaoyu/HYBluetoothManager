//
//  PeripheralInfo.m
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/17.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import "PeripheralInfo.h"

@implementation PeripheralInfo

-(instancetype)init{
    self = [super init];
    if (self) {
        _characteristics = [[NSMutableArray alloc]init];
    }
    return self;
}

@end
