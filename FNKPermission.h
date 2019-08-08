//
//  FNKPermission.h
//  FNKPermission
//
//  Created by LWW on 2019/8/8.
//  Copyright © 2019 FNK. All rights reserved.
//

#import <Foundation/Foundation.h>
/***
 [[FNKPermission shareInstance] permissonType:  withHandle:^(BOOL granted, id data) {
  }];
 */

//权限类型
typedef enum : NSUInteger{
    PermissionTypeCamera,           //相机权限
    PermissionTypeMic,              //麦克风权限
    PermissionTypePhoto,            //相册权限
    PermissionTypeLocationWhen,     //获取地理位置When
    PermissionTypeCalendar,         //日历
    PermissionTypeContacts,         //联系人
    PermissionTypeBlue,             //蓝牙
    PermissionTypeRemaine,          //提醒
    PermissionTypeHealth,           //健康
    PermissionTypeMediaLibrary      //多媒体
}PermissionType;

typedef void (^FNKPermissionCallBack) (BOOL granted, id  data);

NS_ASSUME_NONNULL_BEGIN

@interface FNKPermission : NSObject

/*
 * 提示
 */
@property(nonatomic,strong)NSString *tip;

/*
 * 单例
 */
+ (instancetype)shareInstance;

/*
 * 获取权限
 * @param  type       类型
 * @param  block      回调
 */
- (void)permissonType:(PermissionType)type withHandle:(FNKPermissionCallBack)block;


@end


NS_ASSUME_NONNULL_END
