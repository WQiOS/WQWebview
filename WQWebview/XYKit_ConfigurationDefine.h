//
//  XYKit_ConfigurationDefine.h
//  JingJiRiBao
//
//  Created by 海洋唐 on 2017/6/21.
//  Copyright © 2017年 海洋唐. All rights reserved.
//

#ifndef XYKit_ConfigurationDefine_h
#define XYKit_ConfigurationDefine_h


//#ifndef __OPTIMIZE__
//#define NSLog(...) NSLog(__VA_ARGS__)
//#else
//#define NSLog(...){}
//#endif

#pragma mark - weak / strong
#define XYKit_WeakSelf        @XYKit_Weakify(self);
#define XYKit_StrongSelf      @XYKit_Strongify(self);

/*！
 * 强弱引用转换，用于解决代码块（block）与强引用self之间的循环引用问题
 * 调用方式: `@XYKit_Weakify`实现弱引用转换，`@XYKit_Strongify`实现强引用转换
 *
 * 示例：
 * @XYKit_Weakify
 * [obj block:^{
 * @strongify_self
 * self.property = something;
 * }];
 */
#ifndef XYKit_Weakify
#if DEBUG
#if __has_feature(objc_arc)
#define XYKit_Weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define XYKit_Weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define XYKit_Weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define XYKit_Weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

/*！
 * 强弱引用转换，用于解决代码块（block）与强引用对象之间的循环引用问题
 * 调用方式: `@XYKit_Weakify(object)`实现弱引用转换，`@XYKit_Strongify(object)`实现强引用转换
 *
 * 示例：
 * @XYKit_Weakify(object)
 * [obj block:^{
 * @XYKit_Strongify(object)
 * strong_object = something;
 * }];
 */
#ifndef XYKit_Strongify
#if DEBUG
#if __has_feature(objc_arc)
#define XYKit_Strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define XYKit_Strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define XYKit_Strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define XYKit_Strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

/*! 获取sharedApplication */
#define XYKit_SharedApplication    [UIApplication sharedApplication]

// 操作系统版本号
#define XYKit_IOS_VERSION ([[[UIDevice currentDevice] systemVersion] floatValue])

#pragma mark - runtime
#import <objc/runtime.h>
/*! runtime set */
#define XYKit_Objc_setObj(key, value) objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

/*! runtime setCopy */
#define XYKit_Objc_setObjCOPY(key, value) objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_COPY)

/*! runtime get */
#define XYKit_Objc_getObj objc_getAssociatedObject(self, _cmd)

/*! runtime exchangeMethod */
#define XYKit_Objc_exchangeMethodAToB(originalSelector,swizzledSelector) { \
Method originalMethod = class_getInstanceMethod(self, originalSelector); \
Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector); \
if (class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) { \
class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod)); \
} else { \
method_exchangeImplementations(originalMethod, swizzledMethod); \
} \
}


#define XYKit_Color_Translucent    [UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:0.5f]

#define XYKit_ImageName(imageName) [UIImage imageNamed:imageName]

/*! 用safari打开URL */
#define XYKit_OpenUrl(urlStr)      [XYKit_SharedApplication openURL:[NSURL URLWithString:urlStr]]

#endif /* XYKit_ConfigurationDefine_h */
