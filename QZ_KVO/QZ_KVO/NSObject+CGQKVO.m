//
//  NSObject+CGQKVO.m
//  CGQKVO
//
//  Created by qiangzi on 2018/7/26.
//  Copyright © 2018年 cgqCoder.com. All rights reserved.
//

#import "NSObject+CGQKVO.h"
static NSString *const QZKVOPrefix = @"QZKVO_";
static NSString *const QZKVOAssicationKey = @"QZKVOAssicationKey";


@interface QZ_Info : NSObject

@property (nonatomic, weak) id observer;
@property (nonatomic,copy) NSString *keyPath;
@property (nonatomic,copy) QZKVOBlock handle;

-(instancetype)initWhit:(id)observer keyPath:(NSString *)keyPath handle:(QZKVOBlock)handle;

@end

@implementation QZ_Info
-(instancetype)initWhit:(id)observer keyPath:(NSString *)keyPath handle:(QZKVOBlock)handle{
    self = [super init];
    if (self) {
        _observer = observer;
        _keyPath = keyPath;
        _handle = handle;
    }
    return self;
}
@end


@implementation NSObject (CGQKVO)

- (void)qz_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath withHandle:(QZKVOBlock)handle{
    
    //检查是否是实例变量（实例变量就抛出异常）
    //1.获取当前类
    Class superClass = object_getClass(self);
    //2.检查是否有setter方法
    SEL setterSeletor = NSSelectorFromString(setterFormGetter(keyPath));
    Method setterMethod = class_getInstanceMethod(superClass, setterSeletor);
    
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"这个key:%@,没有setter:方法",keyPath] userInfo:nil];
    }
    
    //动态创建子类创建子类
    NSString *superClassName = NSStringFromClass(superClass);
    
    Class childClass;
    if (![superClassName hasPrefix:QZKVOPrefix]) {
        childClass = [self createClassFromSuperClass:superClassName];
        
        //把动态创建的子类指向父类
        //isa_swizzling:
        object_setClass(self, childClass);
    }
    
    //为子类添加setter方法
    /**
     class_addMethod(<#Class  _Nullable __unsafe_unretained cls#>, <#SEL  _Nonnull name#>, <#IMP  _Nonnull imp#>, <#const char * _Nullable types#>)
     1.class -->  给谁添加
     2.SEL   -->  方法编号
     3.IMP   -->  函数指针，指向函数实现
     4.types -->  返回值，参数
     */
    const char *types = method_getTypeEncoding(setterMethod);
    class_addMethod(childClass, setterSeletor, (IMP)QZKVO_Setter, types);
    
    
    QZ_Info *info = [[QZ_Info alloc] initWhit:observer keyPath:keyPath handle:handle];
    
    NSMutableArray *Arr = objc_getAssociatedObject(self, &QZKVOAssicationKey);
    if (!Arr) {
        Arr = [[NSMutableArray alloc] initWithCapacity:1];
        objc_setAssociatedObject(self, &QZKVOAssicationKey, Arr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [Arr addObject:info];
    
}


-(void)qz_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    
    NSMutableArray *Arr = objc_getAssociatedObject(self, &QZKVOAssicationKey);
    QZ_Info *tmp;
    for (QZ_Info *info in Arr) {
        if ([info.keyPath isEqualToString:keyPath]) {
            tmp = info;
            break;
        }
    }
    if (tmp) {
        [Arr removeObject:tmp];
    }
}


/**
 通过父类创建子类
 
 @param superClassName 父类类名
 @return 子类
 */
- (Class)createClassFromSuperClass:(NSString *)superClassName{
    
    //获取父类
    Class superClass = object_getClass(self);
    //创建新类
    //1.获取子类类名
    NSString *childClassName = [QZKVOPrefix stringByAppendingString:NSStringFromClass(superClass)];
    //2.检查是否创建过该子类
    Class childClass = NSClassFromString(childClassName);
    //创建过就直接返回改类
    if (childClass) return childClass;
    
    //没创建过就开始创建
    /**
     1.superClass --> 父类
     2.childClassName --> 创建的类名
     3.size_t extraBytes -->开辟的内存空间
     */
    childClass = objc_allocateClassPair(superClass, childClassName.UTF8String, 0);
    
    /**
     添加子类动态添加的class方法
     class_addMethod(Class  _Nullable __unsafe_unretained cls, SEL  _Nonnull name, IMP  _Nonnull imp, const char * _Nullable types)
     1.class --> 给谁添加
     2.SEL   --> 方法编号
     3.IMP   --> 函数指针，指向函数的实现
     4.types --> 返回值/参数
     */
    Method childClassMethod = class_getInstanceMethod(superClass, @selector(class));//获取父类的class方法
    const char *types = method_getTypeEncoding(childClassMethod);
    class_addMethod(childClass, @selector(class),(IMP)QZKVO_Class, types);
    
    //注册
    objc_registerClassPair(childClass);
    
    return childClass;
    
}

#pragma mark - 函数区域

static void QZKVO_Setter(id self, SEL _cmd, id newValue){
    
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterFormSetter(setterName);
    
    if (!getterName) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%@没有getter:%@方法",self,getterName] userInfo:nil];
    }
    
    //取出旧值
    id oldValue = [self valueForKey:getterName];
    //即将改变getterName值
    [self willChangeValueForKey:getterName];
    
    //消息转发 子类-->父类
    /**
     objc_msgSendSuper(void * struct objc_super *super, SEL op, ... *)
     1.super --> void * struct objc_super 结构体
     2.op    --> SEL方法编号
     */
    
    void (*qzkvo_megSendSuper)(void *, SEL, id) = (void*)objc_msgSendSuper;
    
    struct objc_super qz_objcSuper = {
        /// Specifies an instance of a class.
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };
    
    qzkvo_megSendSuper(&qz_objcSuper, _cmd, newValue);
    
    //已经改变getterName值
    [self didChangeValueForKey:getterName];
    
    NSArray *Arr = objc_getAssociatedObject(self, &QZKVOAssicationKey);
    
    for (QZ_Info *info in Arr) {
        if ([info.keyPath isEqualToString:getterName]) {
            info.handle(info.observer, info.keyPath, newValue, oldValue);
        }
    }
    
    
}


static Class QZKVO_Class(id self){
    return class_getSuperclass(object_getClass(self));
}

static NSString *setterFormGetter(NSString * getter){
    
    if (getter.length == 0) {
        return nil;
    }
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *lastString = [getter substringFromIndex:1];
    
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,lastString];
}

static NSString *getterFormSetter(NSString * setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    NSRange range = NSMakeRange(3, setter.length-4);
    NSString *getterStr = [setter substringWithRange:range];
    NSString *firstString = [[getterStr substringToIndex:1] lowercaseString];
    return [getterStr stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}

@end
