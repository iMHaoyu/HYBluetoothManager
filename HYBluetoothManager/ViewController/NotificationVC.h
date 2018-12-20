//
//  NotificationVC.h
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/19.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CBPeripheral,CBCharacteristic;
@interface NotificationVC : UIViewController 
@property (nonatomic, strong) CBPeripheral *currentConnectedPer;
@property (nonatomic, strong) CBCharacteristic *currentCharacteristic;
@end

NS_ASSUME_NONNULL_END
