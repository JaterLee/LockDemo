//
//  AppDelegate.m
//  LockDemo
//
//  Created by Jater on 2018/4/10.
//  Copyright © 2018年 Jater. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDelegate+Example.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /*
     iOS 中的八大锁
     */
    
    /*
     NSLock
     
     NSLock 遵循 NSLocking 协议, lock 方法是加锁, unlock 是解锁, tryLock 是尝试加锁, 如果失败的话返回 NO, lockBeforeDate: 是指定 Date 之前尝试加锁, 如果在指定时间之前都不能加锁, 则返回 NO
     */
//    [self exampleForNSLock];
    
    /*
     NSConditionLock
     
     NSConditionLock 和 NSLock 类似, 都遵循 NSLocking 协议, 方法都类似, 只是多了一个 condition 属性, 以及每个操作都多了一个关于 condition 属性的方法, 例如 tryLock, tryLockWhenCondition, NSConditionLock 可以称为条件锁, 只有 condition 参数与初始化时候的 condition 相等, lock 才能正确进行加锁操作, 而 unlockWithCondition: 并不是当 Condition 符合条件时蔡解锁, 而是解锁之后, 修改 Condition 的值
     */
//    [self exampleForNSConditionLock];
    
    /*
     NSRecursiveLock
     
     NSRecursiveLock 是递归锁, 它和 NSLock 区别在于, NSRecursive 可以在一个线程中重复加锁
     NSRecursiveLock 会记录上锁和解锁的次数 当二者平衡的时候 才会释放锁 其他线程才可以上锁成功
     */
    
//    [self exampleForNSRecursiveLock];
    
    /*
     NSCondition
     
     NSCondition 的对象实际上作为一个锁和一个线程检查器, 锁上之后其他线程也能上锁, 而之后可以根据条件决定是否继续运行线程, 即线程是否要进入 waiting 状态, 经测试 NSCondition 并不会想上文的那些锁一样 先轮询,而是直接进入 waiting 状态 当其他线程中的该锁执行 signal 或者 broadcast 方法时 线程被唤醒 继续运行之后的方法
     */
    
//    [self exampleForNSCondition];
    
    /*
     @synchronized
     */
    
//    [self exampleForSynchronized];
    
    /*
     dispatch_semaphore
     
     dispatch_semaphore 是 GCD 用来同步的一种方式, 与他相关的只有三个函数, 一个是创建信号量, 一个是等待信号, 一个是发送信号
     */
//    [self exampleForDispatchSemaphore];
    
    /*
     OSSpinLock
     一种自旋锁,也只有加锁, 解锁, 尝试加锁三个方法. 和 NSLock 不同的是 NSlock 请求加锁失败的话, 会先轮询, 但一秒过后便会使线程进入 waiting 状态,等待唤醒. 而 OSSpinLock 会一直轮询,等待时会消耗大量 CPU 资源, 不适用于较长时间的任务
     
     'OSSpinLock' is deprecated: first deprecated in iOS 10.0 - Use os_unfair_lock() from <os/lock.h> instead
     
     os_unfair_lock
     苹果官方推荐的替换 OSSpinLock 的方案, 但是它在 iOS10.0以上的系统才可以调用
     */
//    [self exampleForOSSpinLock];
    
    /*
     pthread_mutex
     
     pthread pthread_mutex 是 C 语言下多线程加互斥锁的方式,
     */
    [self exampleForPthreadMutex];
    
    return YES;
}

@end
