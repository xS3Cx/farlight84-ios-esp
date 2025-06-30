#import "PubgLoad.h"

@interface PubgLoad()

@property (nonatomic, strong) ImGuiDrawView *vna;
@property (nonatomic, strong) UIButton *iconButton;
@property (nonatomic) CGPoint initialCenter;

@end

@implementation PubgLoad

static PubgLoad *extraInfo;
UIWindow *mainWindow;

+ (void)load {
    [super load];
    
    // Rejestracja do powiadomień o zmianie stanu aplikacji
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

+ (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"Application became active");
    
    // Opóźnij inicjalizację o 1 sekundę po aktywacji aplikacji
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self initializeButton];
    });
}

+ (void)initializeButton {
    NSLog(@"Initializing button");
    
    // Znajdź główne okno
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            mainWindow = window;
            break;
        }
    }
    
    if (!mainWindow) {
        mainWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    
    if (mainWindow) {
        NSLog(@"Main window found, creating button");
        if (!extraInfo) {
            extraInfo = [PubgLoad new];
            [extraInfo setupIconButton];
        }
    } else {
        NSLog(@"No window found!");
    }
}

- (void)setupIconButton {
    NSLog(@"Setting up icon button");
    
    // Stwórz przycisk
    self.iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Ustaw pozycję w prawym górnym rogu
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    self.iconButton.frame = CGRectMake(screenWidth - 80, screenHeight / 4, 60, 60);
    
    // Podstawowa konfiguracja
    self.iconButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    self.iconButton.layer.cornerRadius = 30;
    self.iconButton.layer.borderWidth = 3.0;
    self.iconButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    // Konfiguracja tekstu
    [self.iconButton setTitle:@"MOD" forState:UIControlStateNormal];
    [self.iconButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.iconButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    
    // Dodaj akcje
    [self.iconButton addTarget:self action:@selector(tapIconView) forControlEvents:UIControlEventTouchUpInside];
    
    // Dodaj gest przeciągania
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.iconButton addGestureRecognizer:panGesture];
    
    // Dodaj przycisk do okna
    if (mainWindow) {
        NSLog(@"Adding button to window");
        [mainWindow addSubview:self.iconButton];
        [mainWindow bringSubviewToFront:self.iconButton];
        
        // Animuj pojawienie się
        self.iconButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
        [UIView animateWithDuration:0.5 
                              delay:0.0 
             usingSpringWithDamping:0.5 
              initialSpringVelocity:0.5 
                            options:UIViewAnimationOptionCurveEaseInOut 
                         animations:^{
            self.iconButton.transform = CGAffineTransformIdentity;
            self.iconButton.alpha = 1.0;
        } completion:nil];
    } else {
        NSLog(@"Window is nil when trying to add button!");
    }
    
    // Sprawdź widoczność po krótkim czasie
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self checkButtonVisibility];
    });
}

- (void)loadImageFromURL:(NSString *)urlString completion:(void (^)(UIImage *image))completion {
    NSLog(@"Starting image download from: %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *downloadImageTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error downloading image: %@", error.localizedDescription);
            completion(nil);
            return;
        }
        
        if (data) {
            UIImage *downloadedImage = [UIImage imageWithData:data];
            if (downloadedImage) {
                NSLog(@"Image downloaded successfully");
                completion(downloadedImage);
            } else {
                NSLog(@"Failed to create image from downloaded data");
                completion(nil);
            }
        } else {
            NSLog(@"No data received");
            completion(nil);
        }
    }];
    [downloadImageTask resume];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    UIView *piece = [gestureRecognizer view];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) self.initialCenter = piece.center;
    
    CGPoint translation = [gestureRecognizer translationInView:piece.superview];
    if (gestureRecognizer.state != UIGestureRecognizerStateCancelled) {
        piece.center = CGPointMake(self.initialCenter.x + translation.x, self.initialCenter.y + translation.y);
    } else piece.center = self.initialCenter;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) self.initialCenter = CGPointZero;
}

- (void)tapIconView {
    NSLog(@"tapIconView called");
    if (!_vna) {
        ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
        _vna = vc;
        
        // Dodaj widok do głównego okna
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows firstObject];
        }
        
        [window addSubview:_vna.view];
        [window bringSubviewToFront:_vna.view];
    }

    static BOOL toggle = NO;
    toggle = !toggle;
    [ImGuiDrawView showChange:toggle];
    
    // Aktualizuj widoczność
    _vna.view.hidden = !toggle;
}

- (void)checkButtonVisibility {
    if (self.iconButton.superview == nil) {
        NSLog(@"Button has no superview!");
        if (mainWindow) {
            NSLog(@"Re-adding button to window");
            [mainWindow addSubview:self.iconButton];
            [mainWindow bringSubviewToFront:self.iconButton];
        }
    } else {
        NSLog(@"Button is properly added to view hierarchy");
    }
}

@end