#import "JHUIViewControllerDecoupler.h"

@implementation JHUIViewControllerDecoupler

+ (UIViewController *)jh_controllerFromString:(NSString *)string
                                     paramter:(NSDictionary *)dictionary
{
    // vc from string.
    UIViewController *vc = [NSClassFromString(string) new];
    
    // if vc is nil.
    if (vc == nil) {
        return [self jh_notice_vc:string];
    }
    
    // just KVC it.
    for (NSString *key in dictionary.count > 0 ? dictionary.allKeys : @[]) {
        [vc setValue:dictionary[key] forKey:key];
    }
    
    return vc;
}

+ (UIViewController *)jh_notice_vc:(NSString *)string
{
    return nil;
}

@end

@interface UIViewController (JHUIViewControllerDecoupler)

@end

@implementation UIViewController (JHUIViewControllerDecoupler)

- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    NSLog(@"[<%@ %p> %s]: this class is not key value coding-compliant for the key: %@",NSStringFromClass([self class]),self,__FUNCTION__,key);
}

@end

