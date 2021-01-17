//
//  FileTableViewController.h
//  GraphTutorial
//
//  Created by 严建民 on 2021/1/17.
//  Copyright © 2021 Jason Johnston. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileTableViewController : UITableViewController

- (instancetype)initWithFolderId:(nullable NSString *)folderId folderName:(nonnull NSString *)folderName;

@end

NS_ASSUME_NONNULL_END
