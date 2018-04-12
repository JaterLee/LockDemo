//
//  AppDelegate+Example.m
//  LockDemo
//
//  Created by Jater on 2018/4/11.
//  Copyright © 2018年 Jater. All rights reserved.
//

#import "AppDelegate+Example.h"
#import <libkern/OSSpinLockDeprecated.h>
#import <os/lock.h>

@implementation AppDelegate (Example)

- (void)exampleForNSLock {
    NSLock *lock = [[NSLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lock];
        NSLog(@"线程1");
        sleep(2);
        [lock unlock];
        NSLog(@"线程1 解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        [lock lock];
        NSLog(@"线程2");
        [lock unlock];
    });
    
    /*
     out
     2016-08-19 14:23:09.659 ThreadLockControlDemo[1754:129663] 线程1
     2016-08-19 14:23:11.663 ThreadLockControlDemo[1754:129663] 线程1解锁成功
     2016-08-19 14:23:11.665 ThreadLockControlDemo[1754:129659] 线程2
     
     线程1中 lock 锁上了, 所以线程2中的 lock 加锁失败, 阻塞线程2,但是2s 后线程1中 lock 解锁,线程2就立即加锁成功,执行线程2中的后续代码
     
     互斥锁会使得线程阻塞, 阻塞的过程又分两个阶段, 第一阶段是会先空转, 可以理解成跑一个 while 循环, 不断地去申请加锁,在空转一定时间之后, 线程会进入 waiting 状态, 此时线程就不占用 cpu 资源了, 等锁可用的时候,这个线程会立即被唤醒
     
     如果讲上面线程1的 sleep(2) 改成 sleep(10) 输出的结果为
     
     2016-08-19 14:25:16.226 ThreadLockControlDemo[1773:131824] 线程1
     2016-08-19 14:25:26.231 ThreadLockControlDemo[1773:131831] 线程2
     2016-08-19 14:25:26.231 ThreadLockControlDemo[1773:131824] 线程1解锁成功
     
     从上面的两个输出结果可以看出, 线程2 lock 的第一秒,是一直在轮询请求加锁, 因为轮询有时间间隔, 所以线程2的输出晚于线程1 解锁成功, 但是线程2 lock 的第九秒, 是当锁可用的时候,立即被唤醒,所以线程2 的输出遭遇线程1解锁成功. 多做几次实验 发现轮询1秒之后 线程会进入 waiting状态
     */
    
    NSLock *lock2 = [[NSLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock2 lock];
        NSLog(@"线程1");
        sleep(10);
        [lock2 unlock];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        if ([lock2 tryLock]) {
            NSLog(@"线程2");
            [lock2 unlock];
        } else {
            NSLog(@"尝试加锁失败");
        }
    });
    
    /*
     2016-08-19 11:42:54.433 ThreadLockControlDemo[1256:56857] 线程1
     2016-08-19 11:42:55.434 ThreadLockControlDemo[1256:56861] 尝试加锁失败
     
     有上面的结果可得知, tryLock 并不会阻塞线程. [lock trylock] 能加锁返回 YES, 不能加锁返回 NO, 然后都会执行后续代码
     
     如果将[lock trylock]替换成 [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:10]
     
     的话, 则会返回YES, 输出线程2, lockBeforeDate: 方法会在所指定 date 之前尝试加锁, 会阻塞线程, 如果在指定时间之前都不能加锁, 则返回 NO, 指定时间之前能加锁, 则返回 YES
     
     如果是三个线程 那么一个线程在加锁的时候 其余请求锁的线程将形成一个等待队列 按先进先出原则 这个结果可以通过修改线程优先级进行测试得出
     */
}

- (void)exampleForNSConditionLock {
    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:0];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lockWhenCondition:1];
        NSLog(@"线程1");
        sleep(2);
        [lock unlock];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        if ([lock tryLockWhenCondition:0]) {
            NSLog(@"线程2");
            [lock unlockWithCondition:2];
            NSLog(@"线程2解锁成功");
        } else {
            NSLog(@"线程2尝试加锁失败");
        }
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);
        if ([lock tryLockWhenCondition:2]) {
            NSLog(@"线程3");
            [lock unlock];
            NSLog(@"线程3解锁成功");
        } else {
            NSLog(@"线程3尝试加锁失败");
        }
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(3);
        if ([lock tryLockWhenCondition:2]) {
            NSLog(@"线程4");
            [lock unlockWithCondition:1];
            NSLog(@"线程4解锁成功");
        } else {
            NSLog(@"线程4尝试加锁失败");
        }
    });
    
    /*
     out
    2016-08-19 13:51:15.353 ThreadLockControlDemo[1614:110697] 线程2
    2016-08-19 13:51:15.354 ThreadLockControlDemo[1614:110697] 线程2解锁成功
    2016-08-19 13:51:16.353 ThreadLockControlDemo[1614:110689] 线程3
    2016-08-19 13:51:16.353 ThreadLockControlDemo[1614:110689] 线程3解锁成功
    2016-08-19 13:51:17.354 ThreadLockControlDemo[1614:110884] 线程4
    2016-08-19 13:51:17.355 ThreadLockControlDemo[1614:110884] 线程4解锁成功
    2016-08-19 13:51:17.355 ThreadLockControlDemo[1614:110884] 线程1
     
      上面代码先输出了线程2, 因为线程1 的加锁条件不满足, 初始化时候的 Condition 参数为0, 而加锁条件是 Condition 为1, 所以加锁失败. lockWhenCondition 与 lock 方法类似, 加锁失败会阻塞线程, 所有线程1会被阻塞, 而 tryLockWhenCondition 方法就算条件不满足, 也会返回 NO 不会阻塞当前线程
     
     线程2执行了[lock unlockWithCondition:2] 所有 condition 被修改成了2
     
     而线程3 的加锁条件是 Condition 为 2, 所有线程3 才能加锁成功, 线程3 执行了 [lock unlock] 解锁成功且不改变Condition  的值
     
     线程4的条件是2 所以加锁成功 解锁时将 Condition 改为1 这个时候线程1 终于可以加锁成功 解除阻塞
     
     从上面可以得出 NSConditionLock 还可以实现任务之间的依赖
     */
}

- (void)exampleForNSRecursiveLock {
    NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value) {
            [lock lock];
            if (value > 0) {
                NSLog(@"value: %d", value);
                RecursiveBlock(value - 1);
            }
            [lock unlock];
        };
        RecursiveBlock(2);
    });
    
    /*
     2018-04-11 15:34:09.085154+0800 LockDemo[60914:6323993] value: 2
     2018-04-11 15:34:09.085261+0800 LockDemo[60914:6323993] value: 1
     
     如上面的示例, 如果用 nslock 的话 lock 先锁上了 但是未执行解锁的时候 就会进入递归的下一层 而再次请求上锁 阻塞了该线程 线程被阻塞了 自然后面的解锁代码不会执行 而形成死锁 而 NSRecursiveLock 递归锁就是为了解决这个问题
     */
}

- (void)exampleForNSCondition {
    NSCondition *lock = [[NSCondition alloc] init];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lock];
        while (!array.count) {
            [lock wait];
        }
        [array removeAllObjects];
        NSLog(@"array removeAllObjects");
        [lock unlock];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        [lock lock];
        [array addObject:@1];
        NSLog(@"array addObject:@1");
        [lock signal];
        [lock unlock];
    });
    
    /*
     out
     2018-04-11 16:19:07.782934+0800 LockDemo[61892:6353980] array addObject:@1
     2018-04-11 16:19:07.783147+0800 LockDemo[61892:6353993] array removeAllObjects
     
     也就是使用 NSCondition 的模型为:
     
     锁定条件对象
     
     测试是否可以安全的履行接下来的任务
     
     如果布尔值是假 调用条件对象的 wait 或者 waitUntilDateL 方法来阻塞线程, 在从这些方法返回, 则转到步骤2重新测试你的布尔值.(继续等待信号和重新测试,直到可以安全的履行接下来的任务, waitUntilDate:方法有个等待时间限制,指定的时间到了,则返回 NO 继续运行接下来的任务)
     
     如果布尔值为真 执行接下来的任务
     
     当任务完成时 解锁条件对象
     
     而步骤3说的等待的信号, 既线程2执行[lock signal] 发送的信号
     
     其中 signal 和 broadcast 方法的区别在于, signal 只是一个信号量, 只能唤醒一个等待的线程, 想唤醒多个就得多次调用, 而 broadcast 可以唤醒所有在等待的线程 如果没有等待的线程 这个两个方法都没有作用
     */
}

- (void)exampleForSynchronized {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (self) {
            sleep(2);
            NSLog(@"线程1");
        }
        NSLog(@"线程1解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        @synchronized(self) {
            NSLog(@"线程2");
        }
    });
    
    /*
     2018-04-11 16:38:09.943952+0800 LockDemo[61998:6367336] 线程1
     2018-04-11 16:38:09.944126+0800 LockDemo[61998:6367336] 线程1解锁成功
     2018-04-11 16:38:09.944142+0800 LockDemo[61998:6367335] 线程2
     
     @synchronized(object) 指令使用的 object 为该锁的唯一标识,只有当标识相同时, 才满足互斥, 所有如果线程2中的 @synchronized(self) 改为 @synchronized(self.view), 则线程2就不会被阻塞, @synchronized指令实现锁的优点就是我们不需要在代码中显示的创建锁对象,便可以实现锁的机制, 但作为一种预防措施, @synchronized 块会隐式的添加一个异常处理例程来保护代码, 该处理例程会在异常抛出的时候自动的释放互斥锁, @synchronized 还有一个好出就是不用担心忘记解锁了
     
     如果在 @sychronized(object{})内部 object 被释放或者被设为 nil,从我做的测试结果来看, 的确没有问题,但是如果 object 一开始就是 nil, 则失去锁的功能. 不过虽然 nil 不行, 但是 @synchronized([NSNull null]) 是完全 可以的
     */
}

- (void)exampleForDispatchSemaphore {
    NSLog(@"11111");
    dispatch_semaphore_t signal = dispatch_semaphore_create(0);
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(signal, overTime);
        sleep(2);
        NSLog(@"线程1");
        dispatch_semaphore_signal(signal);
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程2");
        dispatch_semaphore_signal(signal);
    });
    
    /*
     dispatch_semaphore 和 NSCondition 类似, 都是一种基于信号的同步方式, 但 NSCondition 信号只能发送, 不能保存 (如果没有线程在等待, 则发送的信号会失效). 而 dispatch_semaphore 的核心是 dispatch_semaphore_t 类型的信号量
     
     dispatch_semaphore_create(1) 方法可以创建一个 dispatch_semaphore_t 类型的信号量, 设定信号量的初始值为 1, 注意, 这里的传入的参数必须大于或等于0, 否则 dispatch_semaphore_create 会返回 NULL
     
     dispatch_semaphore_wait(signal, overTime); 方法会判断 signal 的信号值是否大于0. 大于0不会阻塞线程, 消耗掉一个信号, 执行后续任务. 如果信号值为 0 , 该线程会和 NSCondition 一样直接进入 waiting 状态, 等待其他线程发送信号唤醒线程去执行后续任务, 或者当 overtime 时限到了, 也会执行后续任务
     
     dispatch_semaphore_signal(signal); 发送信号, 如果没有等待的线程接收信号, 则使 signal 信号值加- (做到对信号的保存)
     
     从上面的示例代码可以看到, 一个 dispatch_semaphore_wait(signal, overTime); 方法会去对应一个 dispatch_semaphore_signal(signal); 看起来像 NSLock 的 lock 和 unlock, 其实可以这样理解, 区别只在于有信号量这个参数, lock unlock 只能同一时间, 一个线程访问被保护的临界区, 而如果 dispatch_semaphore 的信号量初始值为 x, 则可以有 x 个线程同时访问被保护的临界区
     
     */
}

- (void)exampleForOSSpinLock {
    if (@available(iOS 10.0, *)) {
        __block os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            os_unfair_lock_lock(&lock);
            NSLog(@"线程1");
            sleep(10);
            os_unfair_lock_unlock(&lock);
            NSLog(@"线程1解锁成功");
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            os_unfair_lock_lock(&lock);
            NSLog(@"线程2");
            os_unfair_lock_unlock(&lock);
        });
    };
    
    /*
     Thread 3: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)
     发生 死锁!
     代码 {
     __block os_unfair_lock_t lock = &(OS_UNFAIR_LOCK_INIT);
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
     os_unfair_lock_lock(lock); <--- 发生 crash, 具体原因不是很清楚, os_unfair_lock 和 os_unfair_lock_t 区别是 前者为 Structure 后者为 Type Alias 这个后面研究下
     .....
     })
     }
     
     2018-04-12 11:07:36.421153+0800 LockDemo[65043:6878621] 线程1
     2018-04-12 11:07:36.538 LockDemo[65043:6878467]  INFO: Reveal Server started (Protocol Version 25).
     2018-04-12 11:07:46.425484+0800 LockDemo[65043:6878621] 线程1解锁成功
     2018-04-12 11:07:46.425505+0800 LockDemo[65043:6878631] 线程2
     
     拿上面的输出结果和上文 NSLock 的输出结果做对比,会发现 sleep(10)的情况,OSSpinLock 和 哦是_unfair_lock 中的线程2并没有和线程1解锁成功在一个时间输出, 而 NSLock 这里是同一时间输出, 而是有点时间间隔,所以 OSSpinLock 和 os_unfair_lock 一直在做着轮询,而不是想 NSLock 一样先轮询,再 waiting 等唤醒
     */
}

- (void)exampleForPthreadMutex {
    
}
@end
