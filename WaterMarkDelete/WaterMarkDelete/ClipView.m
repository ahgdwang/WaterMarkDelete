//
//  ClipView.m
//  WaterMarkDelete
//
//  Created by WangYiming on 2018/4/6.
//  Copyright © 2018年 WangYiming. All rights reserved.
//

#import "ClipView.h"

@implementation ClipView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(id)init{
    self = [super init];
    if (self) {
        self.alpha = 0.5;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}
@end
