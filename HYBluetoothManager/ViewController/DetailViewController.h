//
//  DetailViewController.h
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/17.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@class CBPeripheral;
@interface DetailViewController : UIViewController

@property (nonatomic, strong) CBPeripheral *currentConnectedPer;

@end

NS_ASSUME_NONNULL_END
