//
//  HYPeripheralCell.h
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/19.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYPeripheralCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *properties;
@property (weak, nonatomic) IBOutlet UILabel *UUID;

@end

NS_ASSUME_NONNULL_END
