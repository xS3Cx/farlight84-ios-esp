
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface JHPP : NSObject

+ (UIViewController *)currentViewController;

+ (void)pushVC:(UIViewController *)vc from:(id)responder;
+ (void)pushVC:(UIViewController *)vc from:(id)responder animated:(BOOL)animated;
+ (void)pushVC:(NSString *)vcString paramter:(NSDictionary *)dic from:(id)responder;
+ (void)pushVC:(NSString *)vcString paramter:(NSDictionary *)dic from:(id)responder animated:(BOOL)animated;
+ (void)presentVC:(UIViewController *)vc from:(id)responder;
+ (void)presentVC:(UIViewController *)vc from:(id)responder animated:(BOOL)animated;
+ (void)presentVC:(UIViewController *)vc from:(id)responder navigation:(BOOL)navigation;
+ (void)presentVC:(UIViewController *)vc from:(id)responder navigation:(BOOL)navigation animated:(BOOL)animated;
+ (void)presentVC:(NSString *)vcString paramter:(NSDictionary *)dic from:(id)responder;
+ (void)presentVC:(NSString *)vcString paramter:(NSDictionary *)dic from:(id)responder animated:(BOOL)animated;
+ (void)presentVC:(NSString *)vcString paramter:(NSDictionary *)dic from:(id)responder navigation:(BOOL)navigation;
+ (void)presentVC:(NSString *)vcString paramter:(NSDictionary *)dic from:(id)responder navigation:(BOOL)navigation animated:(BOOL)animated;

@end
