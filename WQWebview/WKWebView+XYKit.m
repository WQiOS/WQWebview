//
//  WKWebView+XYKit.m
//  JingJiRiBao
//
//  Created by 海洋唐 on 2017/6/21.
//  Copyright © 2017年 海洋唐. All rights reserved.
//

#import "WKWebView+XYKit.h"
#import "XYKit_ConfigurationDefine.h"
#import "WeakScriptMessageDelegate.h"


@implementation WKWebView (XYKit)
#pragma mark - hook
/**
 添加 WKWebView 的代理，例如：
 XYKit_WeakSelf
 [self.webView xy_web_initWithDelegate:weak_self.webView uIDelegate:weak_self.webView];
 
 @param navigationDelegate navigationDelegate
 @param uIDelegate uIDelegate
 */
- (void)xy_web_initWithDelegate:(id<WKNavigationDelegate>)navigationDelegate
                     uIDelegate:(id<WKUIDelegate>)uIDelegate
{
    self.navigationDelegate = navigationDelegate;
    self.UIDelegate = uIDelegate;
    
    [self xy_web_addNoti];
}

- (void)xy_web_dealloc
{
    [self xy_removeNoti];
}

- (void)xy_removeNoti
{
    [self removeObserver:self forKeyPath:@"title"];
    [self removeObserver:self forKeyPath:@"estimatedProgress"];
    [self removeObserver:self forKeyPath:@"URL"];
}

#pragma mark - 添加对WKWebView属性的监听
- (void)xy_web_addNoti
{
    // 获取页面标题
    [self addObserver:self
           forKeyPath:@"title"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    // 当前页面载入进度
    [self addObserver:self
           forKeyPath:@"estimatedProgress"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    // 监听 URL，当之前的 URL 不为空，而新的 URL 为空时则表示进程被终止
    [self addObserver:self
           forKeyPath:@"URL"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"title"])
    {
        if (self.xy_web_getTitleBlock)
        {
            self.xy_web_getTitleBlock(self.title);
        }
        if (self.xy_web_getCurrentUrlBlock)
        {
            self.xy_web_getCurrentUrlBlock(self.URL);
        }
    }
    else if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        // estimatedProgress：加载进度，范围：0.0f ~ 1.0f
        if (self.xy_web_isLoadingBlock)
        {
            self.xy_web_isLoadingBlock(self.loading, self.estimatedProgress);
        }
    }
    else if ([keyPath isEqualToString:@"URL"])
    {
        NSURL *newUrl = [change objectForKey:NSKeyValueChangeNewKey];
        NSURL *oldUrl = [change objectForKey:NSKeyValueChangeOldKey];
        if (![newUrl isKindOfClass:[NSURL class]] && [oldUrl isKindOfClass:[NSURL class]]) {
            [self reload];
        };
    }
    
    // 加载完成
    if (!self.loading)
    {
        if (self.xy_web_isLoadingBlock)
        {
            self.xy_web_isLoadingBlock(self.loading, 1.0F);
        }
    }
}

#ifndef NSFoundationVersionNumber_iOS_9_0
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView NS_AVAILABLE(10_11, 9_0){
    
    [webView reload];
}
#else

#endif

#pragma mark - custom Mothed
- (BOOL)xy_externalAppRequiredToOpenURL:(NSURL *)url
{
    // 若需要限制只允许某些前缀的scheme通过请求，则取消下述注释，并在数组内添加自己需要放行的前缀
//        NSSet *validSchemes = [NSSet setWithArray:@[@"http", @"https",@"file"]];
//        return ![validSchemes containsObject:url.scheme];
    
    
    // 在这里可以做通用协议「老党政的那一套」
//        NSURL *responseUrl = navigationAction.request.URL;
//        NSString *urlStr = [responseUrl absoluteString];
//        if ([[responseUrl scheme] isEqualToString:baseUrlScheme]) {
//            if ([urlStr containsString:baseShareUrlPath]) {
//                //点击立即分享
//                decisionHandler(WKNavigationActionPolicyCancel);
//            } else if([responseUrl.path containsString:baseCloseUrlPath]){
//                //点击关闭
//                [_webView removeFromSuperview];
//                decisionHandler(WKNavigationActionPolicyCancel);
//            } else if([responseUrl.path containsString:baseGetUrlPath]){
//                //点击立即。。。
//                decisionHandler(WKNavigationActionPolicyAllow);
//            } else {
//                decisionHandler(WKNavigationActionPolicyAllow);
//            }
//        } else {
//            decisionHandler(WKNavigationActionPolicyAllow);
//        }
    
    return !url;
}

#pragma mark - WKScriptMessageHandler
/**
 *  JS 调用 OC 时 webview 会调用此方法
 *
 *  @param userContentController  webview中配置的userContentController 信息
 *  @param message                JS执行传递的消息
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    // 这里可以通过 name 处理多组交互
    // body 只支持 NSNumber, NSString, NSDate, NSArray,NSDictionary 和 NSNull 类型
    if (self.xy_web_userContentControllerDidReceiveScriptMessageBlock)
    {
        self.xy_web_userContentControllerDidReceiveScriptMessageBlock(userContentController, message);
    }
}

#pragma mark - WKUIDelegate
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark = WKNavigationDelegate
#pragma mark 在发送请求之前，决定是否跳转，如果不添加这个，那么 wkwebview 跳转不了 AppStore 和 打电话
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *hostname = navigationAction.request.URL.host.lowercaseString;
    NSLog(@"%@",hostname);
    NSURL *url = navigationAction.request.URL;
    UIApplication *application = [UIApplication sharedApplication];
    // APPStore
    if ([url.absoluteString containsString:@"itunes.apple.com"])
    {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    // 调用电话
    if ([url.scheme isEqualToString:@"tel"])
    {
        if ([application canOpenURL:url])
        {
            [application openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    // 发短信
    if ([url.scheme isEqualToString:@"sms"]) {
        if ([application canOpenURL:url])
        {
            [application openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    // 发邮件
    if ([url.scheme isEqualToString:@"mailto"]) {
        if ([application canOpenURL:url])
        {
            [application openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    // ------- 这个是给经济日报用的--- 不用的话可以删除
    NSString *urlStr = [NSString stringWithFormat:@"%@",navigationAction.request.URL];
    if ([urlStr rangeOfString:@"xhpfm://image"].location != NSNotFound){ // 还会有点击图片出现这种问题的稿件「PS：直接倒过来的数据」
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    // ------- 这个是给经济日报用的--- end
    
    // 参数 WKNavigationAction 中有两个属性：sourceFrame 和 targetFrame，分别代表这个 action 的出处和目标，类型是 WKFrameInfo 。WKFrameInfo有一个 mainFrame 的属性，标记frame是在主frame里显示还是新开一个frame显示
//    WKFrameInfo *frameInfo = navigationAction.targetFrame;
//    BOOL isMainframe = [frameInfo isMainFrame];
    
    if (![self xy_externalAppRequiredToOpenURL:url])
    {
        if (!navigationAction.targetFrame)
        {
            [self xy_web_loadURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    else if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    else if (self.xy_web_decidePolicyForNavigationActionBlock)
    {
        self.xy_web_decidePolicyForNavigationActionBlock(webView, navigationAction);
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - 在响应完成时，调用的方法。如果设置为不允许响应，web内 容就不会传过来
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

#pragma mark - 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    
}

#pragma mark - WKNavigationDelegate
// 开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if (self.xy_web_didStartBlock)
    {
        self.xy_web_didStartBlock(webView, navigation);
    }
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    if (self.xy_web_didCommitBlock)
    {
        self.xy_web_didCommitBlock(webView, navigation);
    }
}

// 页面加载完成之后调用
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    // webView 高度自适应
    [self xy_web_stringByEvaluateJavaScript:@"document.body.offsetHeight" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        // 获取页面高度，并重置 webview 的 frame
        self.xy_web_currentHeight = [result doubleValue];
        NSLog(@"html 的高度：%f", self.xy_web_currentHeight);
        
        //        CGRect frame = webView.frame;
        //        frame.size.height = self.xy_web_currentHeight;
        //        webView.frame = frame;
    }];
    
    if (self.xy_web_didFinishBlock)
    {
        self.xy_web_didFinishBlock(webView, navigation);
    }
    
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
{
    if (self.xy_web_didFailBlock)
    {
        self.xy_web_didFailBlock(webView, navigation);
    }
}

#pragma mark - Public method
/**
 *  返回上一级页面
 */
- (void)xy_web_goBack
{
    if (self.canGoBack)
    {
        [self goBack];
    }
}

/**
 *  进入下一级页面
 */
- (void)xy_web_goForward
{
    if (self.canGoForward)
    {
        [self goForward];
    }
}

/**
 *  刷新 webView
 */
- (void)xy_web_reload
{
    [self reload];
}

/**
 *  加载一个 webview
 *
 *  @param request 请求的 NSURL URLRequest
 */
- (void)xy_web_loadRequest:(NSURLRequest *)request
{
    [self loadRequest:request];
}

/**
 *  加载一个 webview
 *
 *  @param URL 请求的 URL
 */
- (void)xy_web_loadURL:(NSURL *)URL
{
    [self xy_web_loadRequest:[NSURLRequest requestWithURL:URL]];
}

/**
 *  加载一个 webview
 *
 *  @param URLString 请求的 URLString
 */
- (void)xy_web_loadURLString:(NSString *)URLString
{
    [self xy_web_loadURL:[NSURL URLWithString:URLString]];
}

/**
 *  加载本地网页
 *
 *  @param htmlName 请求的本地 HTML 文件名
 */
- (void)xy_web_loadHTMLFileName:(NSString *)htmlName
{
    /*! 一定要记得这一步，要不然本地的图片加载不出来 */
    NSString *basePath = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:basePath];
    
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:htmlName
                                                         ofType:@"html"];
    NSString *HTMLString = [NSString stringWithContentsOfFile:htmlPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    [self loadHTMLString:HTMLString baseURL:baseURL];
}

/**
 *  加载本地 htmlString
 *
 *  @param htmlString 请求的本地 htmlString
 */
- (void)xy_web_loadHTMLString:(NSString *)htmlString
{
    /*! 一定要记得这一步，要不然本地的图片加载不出来 */
    NSString *basePath = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:basePath];
    
    [self loadHTMLString:htmlString baseURL:baseURL];
}

/**
 *  加载 js 字符串
 *
 *  @param javaScriptString js 字符串
 */
- (void)xy_web_stringByEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler
{
    [self evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}


/**
 添加 js 调用 OC，addScriptMessageHandler:name:有两个参数，第一个参数是 userContentController的代理对象，第二个参数是 JS 里发送 postMessage 的对象。添加一个脚本消息的处理器,同时需要在 JS 中添加，window.webkit.messageHandlers.<name>.postMessage(<messageBody>)才能起作用。
 
 @param nameArray JS 里发送 postMessage 的对象数组，可同时添加多个对象
 */
- (void)xy_web_addScriptMessageHandlerWithNameArray:(NSArray *)nameArray
{
    if ([nameArray isKindOfClass:[NSArray class]] && nameArray.count > 0)
    {
        [nameArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.configuration.userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:obj];
        }];
    }
}

#pragma mark - setter / getter

+ (void)load
{
    
}

- (void)setXy_web_currentHeight:(CGFloat)xy_web_currentHeight
{
    XYKit_Objc_setObj(@selector(xy_web_currentHeight), @(xy_web_currentHeight));
}

- (CGFloat)xy_web_currentHeight
{
    return [XYKit_Objc_getObj floatValue];
}

- (BOOL)xy_web_canGoBack
{
    return [self canGoBack];
}

- (BOOL)xy_web_canGoForward
{
    return [self canGoForward];
}

- (void)setXy_web_didStartBlock:(XYKit_webView_didStartProvisionalNavigationBlock)xy_web_didStartBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_didStartBlock), xy_web_didStartBlock);
}

- (XYKit_webView_didStartProvisionalNavigationBlock)xy_web_didStartBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_didCommitBlock:(XYKit_webView_didCommitNavigationBlock)xy_web_didCommitBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_didCommitBlock), xy_web_didCommitBlock);
}

- (XYKit_webView_didCommitNavigationBlock)xy_web_didCommitBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_didFinishBlock:(XYKit_webView_didFinishNavigationBlock)xy_web_didFinishBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_didFinishBlock), xy_web_didFinishBlock);
}

- (XYKit_webView_didFinishNavigationBlock)xy_web_didFinishBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_didFailBlock:(XYKit_webView_didFailProvisionalNavigationBlock)xy_web_didFailBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_didFailBlock), xy_web_didFailBlock);
}

- (XYKit_webView_didFailProvisionalNavigationBlock)xy_web_didFailBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_isLoadingBlock:(XYKit_webView_isLoadingBlock)xy_web_isLoadingBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_isLoadingBlock), xy_web_isLoadingBlock);
}

- (XYKit_webView_isLoadingBlock)xy_web_isLoadingBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_getTitleBlock:(XYKit_webView_getTitleBlock)xy_web_getTitleBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_getTitleBlock), xy_web_getTitleBlock);
}

- (XYKit_webView_getTitleBlock)xy_web_getTitleBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_userContentControllerDidReceiveScriptMessageBlock:(XYKit_webView_userContentControllerDidReceiveScriptMessageBlock)xy_web_userContentControllerDidReceiveScriptMessageBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_userContentControllerDidReceiveScriptMessageBlock), xy_web_userContentControllerDidReceiveScriptMessageBlock);
}

- (XYKit_webView_userContentControllerDidReceiveScriptMessageBlock)xy_web_userContentControllerDidReceiveScriptMessageBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_decidePolicyForNavigationActionBlock:(XYKit_webView_decidePolicyForNavigationActionBlock)xy_web_decidePolicyForNavigationActionBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_decidePolicyForNavigationActionBlock), xy_web_decidePolicyForNavigationActionBlock);
}

- (XYKit_webView_decidePolicyForNavigationActionBlock)xy_web_decidePolicyForNavigationActionBlock
{
    return XYKit_Objc_getObj;
}

- (void)setXy_web_getCurrentUrlBlock:(XYKit_webView_getCurrentUrlBlock)xy_web_getCurrentUrlBlock
{
    XYKit_Objc_setObjCOPY(@selector(xy_web_getCurrentUrlBlock), xy_web_getCurrentUrlBlock);
}

- (XYKit_webView_getCurrentUrlBlock)xy_web_getCurrentUrlBlock
{
    return XYKit_Objc_getObj;
}


@end
