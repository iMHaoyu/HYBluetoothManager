//
//  DetailViewController.m
//  HYBluetoothManager
//
//  Created by 徐浩宇 on 2018/12/17.
//  Copyright © 2018 徐浩宇. All rights reserved.
//

#import "DetailViewController.h"
#import "HYBluetooth.h"
#import "PeripheralInfo.h"
#import "HYPeripheralCell.h"
#import "NotificationVC.h"

@interface DetailViewController ()<CBPeripheralDelegate,UITableViewDelegate,UITableViewDataSource> {
    HYBluetooth *_bluetooth;
}

@property (nonatomic, weak) UITableView *mainTableView;
@property (nonatomic, weak) UIButton *closeBtn;
@property (nonatomic, strong) UILabel *nameLabel;
@property __block NSMutableArray *services;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self mainTableView];
    [self closeBtn];
    self.nameLabel.text = self.currentConnectedPer.name;
    self.services = [[NSMutableArray alloc]init];
    _bluetooth = [HYBluetooth hy_shareBluetooth];
    
    //扫描服务的回调
    __weak typeof(self) weakSelf = self;
    _bluetooth.discoverServicesBlock = ^(CBPeripheral * _Nonnull peripheral, NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        for (CBService *service in peripheral.services) {
            [strongSelf insertSectionToTableView:service];
            [strongSelf->_bluetooth hy_discoverCharacteristicsforService:service peripheral:peripheral];
        }
    };
    
    //扫描特征的回调
    _bluetooth.discoverCharacteristicsBlock = ^(CBPeripheral * _Nonnull peripheral, CBService * _Nonnull service, NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf insertRowToTableView:service];
        for (CBCharacteristic *characteristic in service.characteristics) {
            [strongSelf->_bluetooth hy_discoverDescriptorsForCharacteristic:characteristic peripheral:peripheral];
            [peripheral readValueForCharacteristic:characteristic];
            NSLog(@"characteristic.properties => %lu",(unsigned long)characteristic.properties);
        }
    };

    //扫描特征的描述符回调
    _bluetooth.discoverDescriptorsForCharacteristicBlock = ^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        int a = 0;
        for (CBDescriptor *ds in characteristic.descriptors) {
            NSLog(@"CBDescriptor:%d  %@",a,ds.value);
            a++;
        }
        [strongSelf.mainTableView reloadData];
    };
    // Do any additional setup after loading the view.
}

#pragma mark - ⬅️⬅️⬅️⬅️ TableView 插入方法 ➡️➡️➡️➡️
#pragma mark -
- (void)insertSectionToTableView:(CBService *)service{
    
    PeripheralInfo *info = [[PeripheralInfo alloc]init];
    [info setServiceUUID:service.UUID];
    [self.services addObject:info];
}

- (void)insertRowToTableView:(CBService *)service{
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    int sect = -1;
    for (int i=0;i<self.services.count;i++) {
        PeripheralInfo *info = [self.services objectAtIndex:i];
        if (info.serviceUUID == service.UUID) {
            sect = i;
        }
    }
    if (sect != -1) {
        PeripheralInfo *info =[self.services objectAtIndex:sect];
        for (int row=0;row<service.characteristics.count;row++) {
            CBCharacteristic *c = service.characteristics[row];
            [info.characteristics addObject:c];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:sect];
            [indexPaths addObject:indexPath];
        } 
    }
    
    
}

#pragma mark - ⬅️⬅️⬅️⬅️ UITableViewDelegate,UITableViewDataSource ➡️➡️➡️➡️
#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.services.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    PeripheralInfo *info = [self.services objectAtIndex:section];
    return [info.characteristics count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CBCharacteristic *characteristic = [[[self.services objectAtIndex:indexPath.section] characteristics]objectAtIndex:indexPath.row];
    HYPeripheralCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HYPeripheralCell class])];
    
    NSArray *peripherals = [characteristic.descriptors valueForKey:@"value"];
    NSString *tempString = [peripherals componentsJoinedByString:@" , "];//分隔符逗号
    cell.nameLabel.text = [NSString stringWithFormat:@"Descriptors: %@",tempString];
    cell.properties.text = [NSString stringWithFormat:@"Properties: %@",[self propertiesCoveToString:characteristic.properties]];
    cell.UUID.text = [NSString stringWithFormat:@"UUID: %@ => UUIDString:(%@)", characteristic.UUID,characteristic.UUID.UUIDString];
    return cell;
}

static CGFloat tempH = 30.f;
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, 100, tempH)];
    PeripheralInfo *info = [self.services objectAtIndex:section];
    title.text = [NSString stringWithFormat:@" UUID: %@ => (UUIDString: %@)",info.serviceUUID,info.serviceUUID.UUIDString];
    title.font = [UIFont systemFontOfSize:13];
    [title setTextColor:[UIColor whiteColor]];
    [title setBackgroundColor:[UIColor darkGrayColor]];
    return title;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return tempH;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
     CBCharacteristic *characteristic = [[[self.services objectAtIndex:indexPath.section] characteristics]objectAtIndex:indexPath.row];

    if (characteristic.properties == CBCharacteristicPropertyNotify) {
        //用来读取数据不怎么更新的特征值
        //[_bluetooth hy_readValueForCharacteristic:characteristic peripheral:self.currentConnectedPer];
        //获取的数据是经常更新的
        [_bluetooth hy_setNotifyValue:YES forCharacteristic:characteristic peripheral:self.currentConnectedPer];
        NotificationVC *tempVC = [[NotificationVC alloc]init];
        tempVC.currentConnectedPer = self.currentConnectedPer;
        tempVC.currentCharacteristic = characteristic;
        [self presentViewController:tempVC animated:YES completion:nil];
    }


}

#pragma mark - ⬅️⬅️⬅️⬅️ 其他方法 ➡️➡️➡️➡️
#pragma mark -

- (NSString *)propertiesCoveToString:(CBCharacteristicProperties)p {

    NSString *retStr = @"Null";
    switch (p) {
        case CBCharacteristicPropertyBroadcast:
            retStr = @"Broadcast";
            break;
        case CBCharacteristicPropertyRead:
            retStr = @"Read";
            break;
        case CBCharacteristicPropertyWriteWithoutResponse:
            retStr = @"WriteWithoutResponse";
            break;
        case CBCharacteristicPropertyWrite:
            retStr = @"Write";
            break;
        case CBCharacteristicPropertyNotify:
            retStr = @"Notify";
            break;
        case CBCharacteristicPropertyIndicate:
            retStr = @"Indicate";
            break;
        case CBCharacteristicPropertyAuthenticatedSignedWrites:
            retStr = @"AuthenticatedSignedWrites";
            break;
        case CBCharacteristicPropertyExtendedProperties:
            retStr = @"ExtendedProperties";
            break;
        case CBCharacteristicPropertyNotifyEncryptionRequired:
            retStr = @"NotifyEncryptionRequired";
            break;
        case CBCharacteristicPropertyIndicateEncryptionRequired:
            retStr = @"IndicateEncryptionRequired";
            break;
    }
    return retStr;
}

- (void)closeBtnClicked:(UIButton *)sender {
    [_bluetooth hy_scanPeripherals];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ⬅️⬅️⬅️⬅️ Getter & setter  ➡️➡️➡️➡️
#pragma mark -
- (UITableView *)mainTableView {
    if (!_mainTableView) {
        UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 75.f;
        tableView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:tableView];
        _mainTableView = tableView;
        
        UIView *temp = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 60)];
        _mainTableView.tableHeaderView = temp;
        
        UILabel *tempLabel = [[UILabel alloc]initWithFrame:CGRectMake(60, 0, self.view.frame.size.width-60, 60)];
        tempLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel = tempLabel;
        tempLabel.font = [UIFont systemFontOfSize:17];
        [temp addSubview:tempLabel];
        
        [_mainTableView registerNib:[UINib nibWithNibName:NSStringFromClass([HYPeripheralCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([HYPeripheralCell class])];
    }
    return _mainTableView;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        UIButton *temp = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 40, 40)];
        temp.layer.cornerRadius = 20;
        temp.backgroundColor = [UIColor redColor];
        [temp setTitle:@"X" forState:normal];
        [temp setTitleColor:[UIColor whiteColor] forState:normal];
        [temp addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:temp];
        [self.view bringSubviewToFront:temp];
        _closeBtn = temp;
    }
    return _closeBtn;
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
