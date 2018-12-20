//
//  RootVC.m
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/18.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import "RootVC.h"
#import "HYBluetooth.h"
#import "DetailViewController.h"

@interface RootVC ()<UITableViewDelegate,UITableViewDataSource>{
    HYBluetooth *_bluetooth;
    CBPeripheral *_currentConnectedPer;
}
@property (weak, nonatomic) UITableView *tableView;
@property (copy, nonatomic) NSMutableArray *dataSourceMutArray;
@end

@implementation RootVC

- (NSMutableArray *)dataSourceMutArray {
    if (!_dataSourceMutArray) {
        _dataSourceMutArray = [NSMutableArray array];
    }
    return _dataSourceMutArray;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *temp = [[UITableView alloc]initWithFrame:self.view.bounds];
        temp.delegate = self;
        temp.dataSource = self;
        [self.view addSubview:temp];
        _tableView = temp;
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self tableView];
    
    _currentConnectedPer = nil;
    _bluetooth = [HYBluetooth hy_shareBluetooth];
    
    //蓝牙网关初始化和回调方法设置
    [self bluetoothCallBack];
    // Do any additional setup after loading the view.
}

//蓝牙网关初始化和回调方法设置
-(void)bluetoothCallBack {
    
    //设备蓝牙状态回调
    __weak typeof(self) weakSelf = self;
    _bluetooth.centralManagerDidUpdateStateBlock = ^(CBCentralManager * _Nonnull centralManager) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //扫描设备
        [strongSelf->_bluetooth hy_scanPeripherals];
    };
    
    //扫描到的设备回调
    __block typeof(self.dataSourceMutArray) dataSource = self.dataSourceMutArray;
    _bluetooth.didDiscoverPeripheralBlock = ^(CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nonnull advertisementData, NSNumber * _Nonnull RSSI) {
        
        NSLog(@">>> 扫描中");
        NSArray *peripherals = [dataSource valueForKey:@"Peripheral"];
        if(![peripherals containsObject:peripheral]) {
            
            NSDictionary *tempDic = @{@"Peripheral":peripheral,
                                      @"Name":peripheral.name?peripheral.name:@"未知设备",
                                      @"RSSI":RSSI,
                                      @"AdvertisementData":advertisementData};
            
            [dataSource addObject:tempDic];
            [weakSelf.tableView reloadData];
        }
    };
    
    //已连接到设备的回调
    _bluetooth.didConnectedPeripheralBlock = ^(CBCentralManager * _Nonnull central, CBPeripheral * _Nonnull peripheral) {
        NSLog(@">>> 已连接");
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf->_currentConnectedPer = peripheral;
        [strongSelf->_bluetooth hy_stopScan];
        DetailViewController *detail = [[DetailViewController alloc]init];
        detail.currentConnectedPer = peripheral;
        [strongSelf presentViewController:detail animated:YES completion:nil];
    };
    
    //连接失败的回调
    _bluetooth.failToConnectPeripheralBlock = ^(CBCentralManager * _Nonnull central, CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        NSLog(@">>> 连接失败");
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf->_currentConnectedPer = nil;
    };
    
    
}

#pragma mark - ⬅️⬅️⬅️⬅️ TableView Delegate & DataSource ➡️➡️➡️➡️
#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSourceMutArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([UITableViewCell class])];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *tempDic = self.dataSourceMutArray[indexPath.row];
    CBPeripheral *peripheral = tempDic[@"Peripheral"];
    if (peripheral.state != CBPeripheralStateDisconnected) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.userInteractionEnabled = NO;
    }else {
        cell.textLabel.textColor = [UIColor darkTextColor];
        cell.userInteractionEnabled = YES;
    }
    cell.textLabel.text = tempDic[@"Name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",tempDic[@"RSSI"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@">>> 开始连接中...");
    NSDictionary *templDic = self.dataSourceMutArray[indexPath.row];
    CBPeripheral *peripheral = templDic[@"Peripheral"];
    [_bluetooth hy_connectPeripheral:peripheral];
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
