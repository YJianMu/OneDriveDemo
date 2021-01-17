//
//  GraphManager.h
//  GraphTutorial
//
//  Copyright (c) Microsoft. All rights reserved.
//  Licensed under the MIT license. See LICENSE.txt in the project root for license information.
//

#import <Foundation/Foundation.h>
#import <MSGraphClientSDK/MSGraphClientSDK.h>
#import <MSGraphClientModels/MSGraphClientModels.h>
#import <MSGraphClientModels/MSCollection.h>
#import <MSAL/MSAL.h>

NS_ASSUME_NONNULL_BEGIN

@interface GraphManager : NSObject

+ (instancetype)defaultManager;

/// 登陆获取token
/// @param parentView parentView description
/// @param completionBlock completionBlock description
- (void)getTokenInteractivelyWithParentView:(UIViewController *)parentView andCompletionBlock:(void(^)(NSString * _Nullable token, NSError * _Nullable error))completionBlock;

/// 获取toke
/// @param authProviderOptions authProviderOptions description
/// @param completion completion description
- (void)getAccessTokenForProviderOptions:(id<MSAuthenticationProviderOptions>)authProviderOptions andCompletion:(void (^)(NSString * _Nonnull, NSError * _Nonnull))completion;

/// 静默登陆获取token
/// @param completionBlock completionBlock description
- (void)getTokenSilentlyWithCompletionBlock:(void (^)(NSString * _Nonnull, NSError * _Nonnull))completionBlock;

/// 退出登陆
- (void)logOut;


- (void)getUserInfoWithCompletionBlock:(void(^)(MSGraphUser* _Nullable user, NSError* _Nullable error))completionBlock;


/// 获取文件夹内容列表，
/// @param folderId 文件夹id，未空时获取根目录内容列表
/// @param completionBlock completionBlock description
- (void)getFolderItme:(nullable NSString *)folderId completionBlock:(void(^)(NSArray<MSGraphDriveItem*>* _Nullable item, NSError* _Nullable error))completionBlock;
/// 下载文件
/// @param fileId fileId description
/// @param completionBlock completionBlock description
- (void)downloadFile:(NSString *)fileId completionBlock:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completionBlock;


@end

NS_ASSUME_NONNULL_END
