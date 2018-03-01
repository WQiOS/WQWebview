//
//  WeakScriptMessageDelegate.h
//  JingJiRiBao
//
//  Created by 海洋唐 on 2017/7/10.
//  Copyright © 2017年 海洋唐. All rights reserved.
//

// ---- 解决无法释放的问题 -----
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface WeakScriptMessageDelegate : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end
