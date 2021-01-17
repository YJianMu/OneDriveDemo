//
//  FileTableViewController.m
//  GraphTutorial
//
//  Created by 严建民 on 2021/1/17.
//  Copyright © 2021 Jason Johnston. All rights reserved.
//

#import "FileTableViewController.h"
#import "GraphManager.h"

//#import <MSGraphClientModels/MSGraphClientModels.h>

@interface FileTableViewController ()

@property (nonatomic, strong) NSMutableArray<MSGraphDriveItem *> * dataArr;

@property (nonatomic, strong) NSString * folderId;
@property (nonatomic, strong) NSString * folderName;

@end

@implementation FileTableViewController

- (instancetype)initWithFolderId:(nullable NSString *)folderId folderName:(nonnull NSString *)folderName{
    
    if (self = [super init]) {
        _folderId = folderId;
        _folderName = folderName;
    }
    return self;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出登陆" style:(UIBarButtonItemStylePlain) target:self action:@selector(logOut)];
    
    self.title = self.folderName;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"kCell"];
    
    [GraphManager.defaultManager getFolderItme:self.folderId completionBlock:^(NSArray<MSGraphDriveItem *> * _Nullable item, NSError * _Nullable error) {
        
        self.dataArr = item.mutableCopy;
        
        [self.tableView reloadData];
        
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"kCell"];
    
    MSGraphDriveItem * item = self.dataArr[indexPath.row];
    
    if (item.file) {
        
        cell.textLabel.text = item.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %lld B", item.lastModifiedDateTime, item.size];
        
    }else if (item.folder) {
        
        cell.textLabel.text = item.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  文件夹", item.lastModifiedDateTime];
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MSGraphDriveItem * item = self.dataArr[indexPath.row];
    
    if (item.folder) {
        
        FileTableViewController * vc = [[FileTableViewController alloc] initWithFolderId:item.entityId folderName:item.name];
        [self.navigationController pushViewController:vc animated:YES];
        
    }else if (item.file) {
        
        [GraphManager.defaultManager downloadFile:item.entityId completionBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
            [data writeToFile:[@"/Users/yanjianmin/Desktop" stringByAppendingPathComponent:item.name] atomically:YES];
        }];
        
    }
}


- (void)logOut{
    
    [GraphManager.defaultManager logOut];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

@end
