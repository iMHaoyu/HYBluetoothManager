//
//  NotificationVC.m
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/19.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import "NotificationVC.h"
#import "HYBluetooth.h"

#import "NSData+UTF8.h"

@interface NotificationVC ()<UITableViewDelegate,UITableViewDataSource>{
    HYBluetooth *_bluetooth;
}

@property (weak, nonatomic) IBOutlet UITableView *mainTableView;
@property (copy, nonatomic) NSMutableArray *dataSourceMutArray;
@end

@implementation NotificationVC
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    _bluetooth = [HYBluetooth hy_shareBluetooth];
    
    __weak typeof(self) weakSelf = self;
    _bluetooth.didUpdateValueForCharacteristicBlock = ^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        //data转string
        NSString *retStr = [strongSelf transformCharateristicValueFromData:characteristic.value];
        NSLog(@"characteristic.value: -> %@  %@",characteristic.value,retStr);
        NSInteger index = strongSelf.dataSourceMutArray.count;
        
        [strongSelf.dataSourceMutArray addObject:retStr?retStr:@""];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        //插入并滚动到该行
        [strongSelf.mainTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [strongSelf.mainTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];

    };
    // Do any additional setup after loading the view from its nib.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSourceMutArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    cell.textLabel.text = self.dataSourceMutArray[indexPath.row];
    return cell;
}

#pragma mark - ⬅️⬅️⬅️⬅️ 其他方法 ➡️➡️➡️➡️
#pragma mark -
/** data转string */
- (NSString *)transformCharateristicValueFromData:(NSData *)dataValue{
    if (!dataValue || [dataValue length] == 0) {
        return @"";
    }
    NSMutableString *destStr = [[NSMutableString alloc]initWithCapacity:[dataValue length]];
    
    [dataValue enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        unsigned char *dataBytes = (unsigned char *)bytes;
        for (int i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x",(dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [destStr appendString:hexStr];
            }else{
                [destStr appendFormat:@"0%@",hexStr];
            }
        }
    }];
    return destStr;
}

#pragma mark - ⬅️⬅️⬅️⬅️ 按钮点击事件 ➡️➡️➡️➡️
#pragma mark -
- (IBAction)backBtnClicked:(UIButton *)sender {
    [_bluetooth hy_setNotifyValue:NO forCharacteristic:self.currentCharacteristic peripheral:self.currentConnectedPer];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ⬅️⬅️⬅️⬅️ Getter & Setter ➡️➡️➡️➡️
#pragma mark -
- (NSMutableArray *)dataSourceMutArray {
    if (!_dataSourceMutArray) {
        _dataSourceMutArray = [NSMutableArray array];
    }
    return _dataSourceMutArray;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
