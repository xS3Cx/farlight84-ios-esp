#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "JHPP.h"
#import "JHDragView.h"
#import "ImGuiLoad.h"
#import "ImGuiDrawView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PubgLoad : NSObject

+ (void)load;
+ (void)applicationDidBecomeActive:(NSNotification *)notification;
+ (void)initializeButton;

@end

NS_ASSUME_NONNULL_END
