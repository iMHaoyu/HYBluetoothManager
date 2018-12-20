//
//  HYBluetooth.h
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/18.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

/****************************************************************
 ****************************************************************
 ****************************************************************
 ******************         中心模式              ****************
 ******************                             *****************
 ******************         中心模式              *****************
 ******************                              *****************
 ******************         中心模式              *****************
 ******************                              *****************
 ******************         中心模式              *****************
 ******************                              *****************
 ******************         中心模式              *****************
 ******************                              *****************
 ****************************************************************
 ****************************************************************
*****************************************************************/
/** ↓↓↓↓↓↓↓↓↓↓↓ Block 的定义 ↓↓↓↓↓↓↓↓↓↓↓ */
/** Block1:设备状态发生改变 */
typedef void(^HYCentralManagerDidUpdateStateBlock)(CBCentralManager *centralManager);
/** Block2:已扫描到蓝牙设备的回调 */
typedef void(^HYDidDiscoverPeripheralBlock)(CBPeripheral *peripheral,NSDictionary<NSString *,id> *advertisementData,NSNumber *RSSI);
/** Block3:已连接到蓝牙设备的回调 */
typedef void(^HYDidConnectedPeripheralBlock)(CBCentralManager *central,CBPeripheral *peripheral);
/** Block4:连接设备失败的回调 */
typedef void(^HYFailToConnectPeripheralBlock)(CBCentralManager *central,CBPeripheral *peripheral,NSError *error);
/** Block5:断开连接设备的回调 */
typedef void(^HYDisconnectPeripheralBlock)(CBCentralManager *central,CBPeripheral *peripheral,NSError *error);
/** Block6:扫描到服务的回调 */
typedef void (^HYDiscoverServicesBlock)(CBPeripheral *peripheral,NSError *error);
/** Block7:扫描到Characteristics的回调 */
typedef void (^HYDiscoverCharacteristicsBlock)(CBPeripheral *peripheral,CBService *service,NSError *error);
/** Block8:读取Characteristics的值的回调 */
typedef void (^HYDidUpdateValueForCharacteristicBlock)(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error);
/** Block9:获取Characteristics的名称 */
typedef void (^HYDiscoverDescriptorsForCharacteristicBlock)(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error);

/** 蓝牙写入的回调 */
typedef void (^HYDidWriteValueForCharacteristicBlock)(CBCharacteristic *characteristic,NSError *error);
///** 扫描到的蓝牙设备数组g有变动（可以d根据这个刷新页面） */
//typedef void (^HYConnectedArrayDidChangeBlock)(id object);





@interface HYBluetooth : NSObject 

/** 单例构造方法 */
+ (instancetype)hy_shareBluetooth;

/** 是否发现Services */
@property (nonatomic, assign) BOOL needDiscoverServices;
/** 是否获取Characteristics */
//@property (nonatomic, assign) BOOL needDiscoverCharacteristics;
/** 是否获取（更新）Characteristics的值 */
//@property (nonatomic, assign) BOOL needReadValueForCharacteristic;

/** 已经连接的外围设备 */
@property (nonatomic, copy, readonly) NSMutableArray<CBPeripheral *> *connectedPeripherals;
/** 已经扫描到的外围设备 */
@property (nonatomic, copy, readonly) NSMutableArray<CBPeripheral *> *discoverPeripherals;
/** 需要自动重新连接的外围设备 */
@property (nonatomic, copy, readonly) NSMutableArray<CBPeripheral *> *reconnectPeripherals;





/** Block1:设备状态发生改变 */
@property (nonatomic, copy) HYCentralManagerDidUpdateStateBlock centralManagerDidUpdateStateBlock;
/** Block2:已扫描到蓝牙设备的回调 */
@property (nonatomic, copy) HYDidDiscoverPeripheralBlock didDiscoverPeripheralBlock;
/** Block3:已连接到蓝牙设备的回调 */
@property (nonatomic, copy) HYDidConnectedPeripheralBlock didConnectedPeripheralBlock;
/** Block4:连接设备失败的回调 */
@property (nonatomic, copy) HYFailToConnectPeripheralBlock failToConnectPeripheralBlock;
/** Block5:断开连接设备的回调 */
@property (nonatomic, copy) HYDisconnectPeripheralBlock disconnectPeripheralBlock;
/** Block6:扫描到服务的回调 */
@property (nonatomic, copy) HYDiscoverServicesBlock discoverServicesBlock;
/** Block7:扫描到Characteristics的回调 */
@property (nonatomic, copy) HYDiscoverCharacteristicsBlock discoverCharacteristicsBlock;
/** Block8:读取Characteristics的值的回调 */
@property (nonatomic, copy) HYDidUpdateValueForCharacteristicBlock didUpdateValueForCharacteristicBlock;
/** Block9:获取Characteristics的名称 */
@property (nonatomic, copy) HYDiscoverDescriptorsForCharacteristicBlock discoverDescriptorsForCharacteristicBlock;

/** 蓝牙写入的回调 */
@property (nonatomic, copy) HYDidWriteValueForCharacteristicBlock didWriteValueForCharacteristicBlock;
///** 扫描到的蓝牙设备数组g有变动（可以d根据这个刷新页面） */
//@property (nonatomic, copy) HYConnectedArrayDidChangeBlock connectedArrayDidChangeBlock;






/** 扫描设备 */
- (void)hy_scanPeripherals;
- (void)hy_scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options;
/** 连接设备 */
- (void)hy_connectPeripheral:(CBPeripheral *)peripheral;
- (void)hy_connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options;
/** 断开设备连接 */
- (void)hy_cancelPeripheralConnection:(CBPeripheral *)peripheral;
/** 断开所有已连接的设备 */
- (void)hy_cancelAllPeripheralsConnection;
/** 停止扫描 */
- (void)hy_stopScan;



/** 扫描特征（characteristics） */
- (void)hy_discoverCharacteristicsforService:(CBService *)service peripheral:(CBPeripheral *)peripheral;
- (void)hy_discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service peripheral:(CBPeripheral *)peripheral;


/** 获取Characteristic的值 ,与下面的区别：用来读取数据不怎么更新的特征值  ----读到数据会进入方法："-(void)peripheral: didUpdateValueForCharacteristic: error:" */
- (void)hy_readValueForCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral;
/** 与上面的区别：获取的数据是经常更新的 */
- (void)hy_setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral;

/** 搜索Characteristic的Descriptors */
- (void)hy_discoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral;
/** 蓝牙写入，第一个参数是已连接的蓝牙设备 ；第二个参数是要写入到哪个特征； 第三个参数是通过此响应记录是否成功写入 */
- (void)hy_writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type peripheral:(CBPeripheral *)peripheral;

@end

NS_ASSUME_NONNULL_END
