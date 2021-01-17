//
//  ViewController.m
//  OneDriveDemo
//
//  Created by 严建民 on 2021/1/17.
//  Copyright © 2021 YJianMu. All rights reserved.
//

#import "ViewController.h"
#import "GraphManager.h"
#import "FileTableViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)login:(id)sender {
    
    [GraphManager.defaultManager getTokenSilentlyWithCompletionBlock:^(NSString * _Nonnull token, NSError * _Nonnull error) {
        
        if (token) {
            FileTableViewController * vc = [[FileTableViewController alloc] initWithFolderId:nil folderName:@"全部文件"];
            [self.navigationController pushViewController:vc animated:YES];
        }else{
            
            [GraphManager.defaultManager getTokenInteractivelyWithParentView:self andCompletionBlock:^(NSString * _Nullable token, NSError * _Nullable error) {
                
                if (error) {
                    
                }else{
                    
                    FileTableViewController * vc = [[FileTableViewController alloc] initWithFolderId:nil folderName:@"全部文件"];
                    [self.navigationController pushViewController:vc animated:YES];
                    
                }
                
            }];
        }
        
    }];
    
}

@end
