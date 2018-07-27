//
//  ViewController.m
//  QZ_KVO
//
//  Created by qiangzi on 2018/7/26.
//  Copyright © 2018年 cgqCoder.com. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "NSObject+CGQKVO.h"
@interface ViewController ()
@property (nonatomic,strong) Person *person;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *removeBnt;
@property (weak, nonatomic) IBOutlet UIButton *changeBtn;

@property (nonatomic, assign) int number;

@end

@implementation ViewController

/**
 KVO的原理 :
 1: 动态创建子类 NSKVONotifying_A --> KCKVO_A
 2: 子类添加 setter方法 NSKVONotifying_A *pChild.name = @"一晃就老了"
 3: 消息转发 子类(NSKVONotifying_A)--->父类person
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.addBtn.enabled = YES;
    self.removeBnt.enabled = NO;

    self.person = [[Person alloc] init];
}

-(void)btn1Click{
  
}
- (IBAction)addObserver:(id)sender {
    [self.person qz_addObserver:self forKeyPath:@"name" withHandle:^(id observer, id keyPath, id newValue, id oldValue) {
        NSLog(@"%@---%@",oldValue,newValue);
    }];
    self.addBtn.enabled = NO;
    self.removeBnt.enabled = YES;
    NSLog(@"添加观察者成功");
}
- (IBAction)removeObserver:(id)sender {
    [self.person qz_removeObserver:self forKeyPath:@"name"];
    self.addBtn.enabled = YES;
    self.removeBnt.enabled = NO;
    NSLog(@"移除观察者成功");

}
- (IBAction)changeValue:(id)sender {
    self.person.name = [@"张三丰" stringByAppendingString:[NSString stringWithFormat:@"%d",self.number]];
    self.number ++;
}


-(void)dealloc{
    [self.person qz_removeObserver:self forKeyPath:@"name"];
}


@end
