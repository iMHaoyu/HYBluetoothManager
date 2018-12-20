//
//  NSData+UTF8.h
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/19.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (UTF8)

- (NSString *)utf8String;

@end

NS_ASSUME_NONNULL_END
