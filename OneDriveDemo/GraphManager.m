//
//  GraphManager.m
//  GraphTutorial
//
//  Copyright (c) Microsoft. All rights reserved.
//  Licensed under the MIT license. See LICENSE.txt in the project root for license information.
//

#import "GraphManager.h"

@interface GraphManager()<MSAuthenticationProvider>

/// 身份授权相关
@property (nonatomic, strong) NSString* appId;
@property (nonatomic, strong) NSArray<NSString*>* graphScopes;
@property (nonatomic, strong) MSALPublicClientApplication* publicClient;


/// 信息请求相关
@property (nonatomic, strong) MSHTTPClient * graphClient;


@end

@implementation GraphManager

+ (instancetype)defaultManager {
    static GraphManager *singleInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        singleInstance = [[self alloc] init];
    });
    
    return singleInstance;
}


- (instancetype)init {
    if (self = [super init]) {
        
        //前往Azure Active Directory admin center 创建应用
        // https://aad.portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps
        self.appId = @"appId";
        //需要在Azure Active Directory admin center 添加api权限
        self.graphScopes = @[@"User.Read", @"Files.ReadWrite.All"];
        
        //创建 MSAL client
        self.publicClient = [[MSALPublicClientApplication alloc] initWithClientId:self.appId error:nil];
        
        
        //创建Graph client
        self.graphClient = [MSClientFactory createHTTPClientWithAuthenticationProvider:self];
        
    }
    return self;
}



/// 登陆获取token
/// @param parentView parentView description
/// @param completionBlock completionBlock description
- (void)getTokenInteractivelyWithParentView:(UIViewController *)parentView andCompletionBlock:(void(^)(NSString * _Nullable token, NSError * _Nullable error))completionBlock {
    
    //    MSALWebviewParameters* webParameters = [[MSALWebviewParameters alloc] initWithParentViewController:parentView];
    MSALWebviewParameters* webParameters = [[MSALWebviewParameters alloc] initWithAuthPresentationViewController:parentView];
    MSALInteractiveTokenParameters* interactiveParameters =
    [[MSALInteractiveTokenParameters alloc]initWithScopes:self.graphScopes webviewParameters:webParameters];
    
    // 调用acquireToken打开浏览器，这样用户就可以登录了
    [self.publicClient acquireTokenWithParameters:interactiveParameters completionBlock:^(MSALResult * _Nullable result, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Check error
            if (error) {
                completionBlock(nil, error);
                return;
            }
            
            // Check result
            if (!result) {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"No result was returned" forKey:NSDebugDescriptionErrorKey];
                completionBlock(nil, [NSError errorWithDomain:@"AuthenticationManager" code:0 userInfo:details]);
                return;
            }
            
            NSLog(@"Got token interactively: %@", result.accessToken);
            completionBlock(result.accessToken, nil);
        });
    }];
}

/// 获取toke
/// @param authProviderOptions authProviderOptions description
/// @param completion completion description
- (void)getAccessTokenForProviderOptions:(id<MSAuthenticationProviderOptions>)authProviderOptions andCompletion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    [self getTokenSilentlyWithCompletionBlock:completion];
}

/// 静默登陆获取token
/// @param completionBlock completionBlock description
- (void)getTokenSilentlyWithCompletionBlock:(void (^)(NSString * _Nullable, NSError * _Nullable))completionBlock {
    // Check if there is an account in the cache
    NSError* msalError;
    MSALAccount* account = [self.publicClient allAccounts:&msalError].firstObject;
    
    if (msalError || !account) {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Could not retrieve account from cache" forKey:NSDebugDescriptionErrorKey];
        completionBlock(nil, [NSError errorWithDomain:@"AuthenticationManager" code:0 userInfo:details]);
        return;
    }
    
    MSALSilentTokenParameters* silentParameters = [[MSALSilentTokenParameters alloc] initWithScopes:self.graphScopes account:account];
    
    //尝试静默获取token
    [self.publicClient acquireTokenSilentWithParameters:silentParameters completionBlock:^(MSALResult * _Nullable result, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Check error
            if (error) {
                completionBlock(nil, error);
                return;
            }
            
            // Check result
            if (!result) {
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"No result was returned" forKey:NSDebugDescriptionErrorKey];
                completionBlock(nil, [NSError errorWithDomain:@"AuthenticationManager" code:0 userInfo:details]);
                return;
            }
            
            NSLog(@"Got token silently: %@", result.accessToken);
            completionBlock(result.accessToken, nil);
        });
    }];
    
}


/// 退出登陆
- (void)logOut {
    
    NSError* msalError;
    NSArray* accounts = [self.publicClient allAccounts:&msalError];
    
    if (msalError) {
        NSLog(@"Error getting accounts from cache: %@", msalError.debugDescription);
        return;
    }
    
    for (id account in accounts) {
        [self.publicClient removeAccount:account error:nil];
    }
    
}



/// 获取用户信息
/// @param completionBlock completionBlock description
- (void)getUserInfoWithCompletionBlock:(void(^)(MSGraphUser* _Nullable user, NSError* _Nullable error))completionBlock {
    // GET /me
    NSString* meUrlString = [NSString stringWithFormat:@"%@/me", MSGraphBaseURL];
    NSURL* meUrl = [[NSURL alloc] initWithString:meUrlString];
    NSMutableURLRequest* meRequest = [[NSMutableURLRequest alloc] initWithURL:meUrl];
    
    MSURLSessionDataTask* meDataTask =
    [[MSURLSessionDataTask alloc] initWithRequest:meRequest client:self.graphClient completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completionBlock(nil, error);
                return;
            }
            
            // Deserialize the response as a user
            NSError* graphError;
            MSGraphUser* user = [[MSGraphUser alloc] initWithData:data error:&graphError];
            
            if (graphError) {
                completionBlock(nil, graphError);
            } else {
                completionBlock(user, nil);
            }
        });
    }];
    
    // Execute the request
    [meDataTask execute];
}


/// 获取文件夹内容列表，
/// @param folderId 文件夹id，未空时获取根目录内容列表
/// @param completionBlock completionBlock description
- (void)getFolderItme:(nullable NSString *)folderId completionBlock:(void(^)(NSArray<MSGraphDriveItem*>* _Nullable item, NSError* _Nullable error))completionBlock {
    
    NSString * path;
    if (folderId) {
        path = [NSString stringWithFormat:@"%@/me/drive/items/%@/children?%@",
                MSGraphBaseURL,
                folderId,
                @"$orderby=createdDateTime+DESC"];//按createdDateTime倒序排序
    }else{
        path = [NSString stringWithFormat:@"%@/me/drive/root/children?%@",
                MSGraphBaseURL,
                @"$orderby=lastModifiedDateTime+DESC"];//按lastModifiedDateTime倒序排序
    }
    
    NSURL * url = [NSURL URLWithString:path];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"GET"];
    
    MSURLSessionDataTask *meDataTask = [self.graphClient dataTaskWithRequest:urlRequest completionHandler: ^(NSData *data, NSURLResponse *response, NSError *nserror) {
        
        if (nserror) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, nserror);
            });
            return;
        }
        
        MSCollection* collection = [[MSCollection alloc] initWithData:data error:&nserror];
        if (nserror) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, nserror);
            });
            return;
        }
        
        NSMutableArray * items = [NSMutableArray array];
        for (id value in collection.value) {
            MSGraphDriveItem *item = [[MSGraphDriveItem alloc] initWithDictionary:value];
            [items addObject:item];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(items, nil);
        });
        
    }];
    
    [meDataTask execute];
    
}


/// 下载文件
/// @param fileId fileId description
/// @param completionBlock completionBlock description
- (void)downloadFile:(NSString *)fileId completionBlock:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completionBlock {
    
    NSString * path = [NSString stringWithFormat:@"%@/me/drive/items/%@/content", MSGraphBaseURL, fileId];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    [urlRequest setHTTPMethod:@"GET"];
    
    MSURLSessionDataTask *meDataTask = [self.graphClient dataTaskWithRequest:urlRequest completionHandler: ^(NSData *data, NSURLResponse *response, NSError *nserror) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(data, nserror);
        });
        
    }];
    
    [meDataTask execute];
}

@end
