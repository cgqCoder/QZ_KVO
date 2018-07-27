//
//  NSObject+CGQKVO.h
//  CGQKVO
//
//  Created by qiangzi on 2018/7/26.
//  Copyright © 2018年 cgqCoder.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/message.h>

typedef void (^QZKVOBlock)(id observer, id keyPath, id newValue, id oldValue);

@interface NSObject (CGQKVO)


/**
 添加观察者
 
 @param observer 观察者对象
 @param keyPath 需要观察的键值
 @param handle 回调block
 */
- (void)qz_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath withHandle:(QZKVOBlock)handle;


/**
 移除观察者

 @param observer 观察值对象
 @param keyPath 观察的键值
 */
-(void)qz_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end
