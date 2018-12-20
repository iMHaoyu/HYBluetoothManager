//
//  HYBluetooth.m
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/18.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import "HYBluetooth.h"

@interface HYBluetooth ()<CBCentralManagerDelegate,CBPeripheralDelegate> {
    /** 系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设 */
    CBCentralManager *_centralManager;
    
    /** 已经连接的外围设备 */
    NSMutableArray<CBPeripheral *> *_connectedPeripherals;
    /** 已经扫描到的外围设备 */
    NSMutableArray<CBPeripheral *> *_discoverPeripherals;
    /** 需要自动重新连接的外围设备 */
    NSMutableArray<CBPeripheral *> *_reconnectPeripherals;
    
}


@end
@implementation HYBluetooth
/** 单例模式 */
+ (instancetype)hy_shareBluetooth {
    static HYBluetooth *bluetooth = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        bluetooth = [[HYBluetooth alloc]init];
    });
    return bluetooth;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        
        //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        _needDiscoverServices = YES;
        
        _connectedPeripherals = [NSMutableArray array];
        _discoverPeripherals = [NSMutableArray array];
        _reconnectPeripherals = [NSMutableArray array];
        
    }
    return self;
}

#pragma mark - ⬅️⬅️⬅️⬅️ 一、对设备的操作 ➡️➡️➡️➡️
#pragma mark -
/** 扫描周围设备 */
- (void)hy_scanPeripherals {
    [self hy_scanForPeripheralsWithServices:nil options:nil];
}
- (void)hy_scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options {
    [_centralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
}

/** 连接设备 */
- (void)hy_connectPeripheral:(CBPeripheral *)peripheral {
    [self hy_connectPeripheral:peripheral options:nil];
}
- (void)hy_connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options {
    [_centralManager connectPeripheral:peripheral options:options];
}

/** 断开设备连接 */
- (void)hy_cancelPeripheralConnection:(CBPeripheral *)peripheral {
    [_centralManager cancelPeripheralConnection:peripheral];
}

/** 断开所有已连接的设备 */
- (void)hy_cancelAllPeripheralsConnection {
    for (CBPeripheral *peripheral in _connectedPeripherals) {
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

/** 停止扫描 */
- (void)hy_stopScan {
    [_centralManager stopScan];
}

#pragma mark - ⬅️⬅️⬅️⬅️ CBCentralManagerDelegate 的委托方法 ➡️➡️➡️➡️
#pragma mark -
/** 设备的蓝牙状态是否打开，是否可用 */
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@">>>初始的时候,未知的（刚刚创建的时候是未知的）");
            break;
        case CBManagerStateResetting:
            NSLog(@">>>正在重置状态");
            break;
        case CBManagerStateUnsupported:
            NSLog(@">>>设备不支持的状态");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@">>>程序未授权");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@">>>设备蓝牙关闭状态");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@">>>设备蓝牙打开状态");
            break;
            
        default:
            break;
    }
    if (self.centralManagerDidUpdateStateBlock) {
        self.centralManagerDidUpdateStateBlock(central);
    }
}

/** 返回扫描到的蓝牙设备 的委托方法 （一个一个的返回，多次返回） */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    //把扫描到的设备添加到已扫描到的设备的数组中
    [self addDiscoverPeripheral:peripheral];
    
    //扫描到设备的回调
    if (self.didDiscoverPeripheralBlock) {
        self.didDiscoverPeripheralBlock(peripheral, advertisementData, RSSI);
    }
    
}

/** 连接到Peripheral-成功  */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    //设置委托
    [peripheral setDelegate:self];
    //添加已连接设备
    [self addConnectedPeripheral:peripheral];
    
    //已连接设备的回调
    if (self.didConnectedPeripheralBlock) {
        self.didConnectedPeripheralBlock(central,peripheral);
    }
    
    //是否需要扫描服务
    if (self.needDiscoverServices) {
        [peripheral discoverServices:nil];
    }
    
}

/** 连接到Peripheral-失败 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    //连接失败的回调
    if (self.failToConnectPeripheralBlock) {
        self.failToConnectPeripheralBlock(central,peripheral,error);
    }
}

/** Peripherals断开连接 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (error) {
        NSLog(@">>> didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
    
    //从已连接的设备数组中删除该设备
    [self deleteConnectedPeripheral:peripheral];
    
    //断开连接的回调
    if (self.disconnectPeripheralBlock) {
        self.disconnectPeripheralBlock(central,peripheral,error);
    }
    
    //检查并重新连接需要重连的设备
    if ([_reconnectPeripherals containsObject:peripheral]) {
        [self hy_connectPeripheral:peripheral];
    }
}

#pragma mark - ⬅️⬅️⬅️⬅️ 二、对设备的操作 ➡️➡️➡️➡️
#pragma mark -

/** 扫描特征（characteristics */
- (void)hy_discoverCharacteristicsforService:(CBService *)service peripheral:(CBPeripheral *)peripheral {
    //forService:peripheral.services
    [self hy_discoverCharacteristics:nil forService:service peripheral:peripheral];
}
- (void)hy_discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service peripheral:(CBPeripheral *)peripheral {
    //forService:peripheral.services
    [peripheral discoverCharacteristics:characteristicUUIDs forService:service];
}

/** 获取Characteristic的值,读到数据会进入方法：- (void)peripheral: didUpdateValueForCharacteristic: error: */
- (void)hy_readValueForCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral {
    //service.characteristics
    [peripheral readValueForCharacteristic:characteristic];
}
- (void)hy_setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral {
    [peripheral setNotifyValue:enabled forCharacteristic:characteristic];
}

/** 搜索Characteristic的Descriptors */
- (void)hy_discoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral {
    //service.characteristics
    [peripheral discoverDescriptorsForCharacteristic:characteristic];
}

/** 蓝牙写入，第一个参数是已连接的蓝牙设备 ；第二个参数是要写入到哪个特征； 第三个参数是通过此响应记录是否成功写入 */
- (void)hy_writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type peripheral:(CBPeripheral *)peripheral {
    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}



#pragma mark - ⬅️⬅️⬅️⬅️ CBPeripheralDelegate 的委托方法 ➡️➡️➡️➡️
#pragma mark -
/** 扫描到服务 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@">>>didDiscoverServices for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
    
    //扫描到服务的回调
    if (self.discoverServicesBlock) {
        self.discoverServicesBlock(peripheral,error);
    }
    
}

/** 扫描到服务的特征（Characteristics） */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@">>>error didDiscoverCharacteristicsForService for %@ with error: %@", service.UUID, [error localizedDescription]);
    }
    
    if (self.discoverCharacteristicsBlock) {
        self.discoverCharacteristicsBlock(peripheral,service,error);
    }
}

/** 获取的charateristic的值 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@">>>error didUpdateValueForCharacteristic %@ with error: %@", characteristic.UUID, [error localizedDescription]);
    }
    //!注意，characteristic.value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    if (self.didUpdateValueForCharacteristicBlock) {
        self.didUpdateValueForCharacteristicBlock(peripheral, characteristic, error);
    }
}

/** 发现Characteristics的Descriptors */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@">>>error Discovered DescriptorsForCharacteristic for %@ with error: %@", characteristic.UUID, [error localizedDescription]);
    }
    if (self.discoverDescriptorsForCharacteristicBlock) {
        self.discoverDescriptorsForCharacteristicBlock(peripheral, characteristic, error);
    }
}

#pragma mark - ⬅️⬅️⬅️⬅️ 私有方法 (Private Methods) ➡️➡️➡️➡️
#pragma mark - 设备list管理
/** 添加扫描到的蓝牙设备 */
- (void)addDiscoverPeripheral:(CBPeripheral *)peripheral {
    //判断是否包含该设备
    if (![_discoverPeripherals containsObject:peripheral]) {
        [_discoverPeripherals addObject:peripheral];
    }
}

/** 把连接的设备添加到已连接设备的数组中 */
- (void)addConnectedPeripheral:(CBPeripheral *)peripheral {
    //判断是否包含该设备
    if (![_connectedPeripherals containsObject:peripheral]) {
        [_connectedPeripherals addObject:peripheral];
    }
}
/** 把连接的设备添加到已连接设备的数组中 */
- (void)deleteConnectedPeripheral:(CBPeripheral *)peripheral {
    //判断是否包含该设备
    if ([_connectedPeripherals containsObject:peripheral]) {
        [_connectedPeripherals removeObject:peripheral];
    }
}

#pragma mark - ⬅️⬅️⬅️⬅️ Getter & Setter ➡️➡️➡️➡️
#pragma mark -
- (NSMutableArray<CBPeripheral *> *)connectedPeripherals {
    return _connectedPeripherals;
}
- (NSMutableArray<CBPeripheral *> *)discoverPeripherals {
    return _discoverPeripherals;
}
- (NSMutableArray<CBPeripheral *> *)reconnectPeripherals {
    return _reconnectPeripherals;
}

@end
