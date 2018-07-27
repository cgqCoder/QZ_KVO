# QZ_KVO
实现KVO观察者模式，并添加Block回调

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
