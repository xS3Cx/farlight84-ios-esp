#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface JHUIViewControllerDecoupler : NSObject

+ (UIViewController *)jh_controllerFromString:(NSString *)string paramter:(NSDictionary *)dictionary;

@end
