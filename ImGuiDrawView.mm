#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#import <thread>
#import <string>

#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#import "Cheat/Pointers.h"
#import "Cheat/Structs.h"
#import "Cheat/Utils.h"

// Dodaj zmienne globalne
static float uiScale = 1.0f;
static float uiWidth = 700;
static float uiHeight = 300;
static int testFNameIndex = 1;

@interface ImGuiDrawView () <MTKViewDelegate>

@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, assign) BOOL espInitialized;

@end

@implementation ImGuiDrawView

// Dodaj zmienne statyczne
static bool isInitialized = false;
static bool MenDeal = true;  // Dodane z powrotem

// Dodaj z powrotem funkcję initial_setup
void initial_setup() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_t NewThreadQueue = dispatch_queue_create("com.bumm.NewThreadQueue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(NewThreadQueue, ^{
            NSLog(@"Loop-Thread started.");
            std::this_thread::sleep_for(std::chrono::seconds(5));
            UpdatePointersLoop();
        });
    });
}

- (instancetype)initWithNibName:(nullable NSString*)nibNameOrNil bundle:(nullable NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        _espInitialized = NO;

        if (!self.device) abort();

        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO(); (void)io;
        
        // Włącz obsługę rysowania
        io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset;
        io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
        
        // Ustaw przezroczyste tło
        self.view.backgroundColor = [UIColor clearColor];
        self.view.opaque = NO;
        
        ImGui::StyleColorsDarkMode();
        
        ImFont* font = io.Fonts->AddFontFromMemoryCompressedTTF((void*)zzz_compressed_data, zzz_compressed_size, 60.0f, NULL, io.Fonts->GetGlyphRangesVietnamese());
        
        ImGui_ImplMetal_Init(_device);
        
        isInitialized = true;
    }
    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{
    [super loadView];
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    MTKView *mtkView = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    mtkView.backgroundColor = [UIColor clearColor];
    mtkView.opaque = NO;
    self.view = mtkView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.opaque = NO;
    self.mtkView.clipsToBounds = YES;
    
    // Dodaj widok na wierzch
    [self.view.window makeKeyAndVisible];
    [self.view.window addSubview:self.view];
}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
    if (!isInitialized) return;
    
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    if (MenDeal) {
        [self.view setUserInteractionEnabled:YES];
    } else {
        [self.view setUserInteractionEnabled:NO];
    }

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Draw"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();

        // Draw ESP first if enabled
        if (g_espConfig.enableESPAllActors && self.espInitialized) {
            @try {
                DrawESP(io);
            } @catch (NSException* e) {
                NSLog(@"Exception in DrawESP: %@", e);
            }
        }

        // Draw menu
        if (MenDeal) {
            ImFont* font = ImGui::GetFont();
            font->Scale = 15.0f / font->FontSize;
                
            CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - 360) / 2;
            CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - 300) / 2;
                
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
            ImGui::SetNextWindowSize(ImVec2(400, 300), ImGuiCond_FirstUseEver);
            
            ImGui::Begin("LAVENDER CHEAT | FARLIGHT 84 | T.ME/CRUEXGG | BY ALEXZERO", &MenDeal);

            // Dodaj zakładki w górnej części okna
            if (ImGui::BeginTabBar("MainTabs")) {
                // Zakładka Main
                if (ImGui::BeginTabItem("Main")) {
                    // Podziel okno na dwie kolumny
                    ImGui::Columns(2);
                    ImGui::SetColumnWidth(0, 150); // Szerokość pierwszej kolumny

                    if (ImGui::Button("Copy Logs", ImVec2(120, 30))) {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        NSString *logsString = [NSString stringWithUTF8String:testLogs.c_str()];
                        [pasteboard setString:logsString];
                    }

                    ImGui::NextColumn();

                    // Prawa kolumna - logi
                    ImGui::BeginChild("Logs", ImVec2(0, 0), true);
                    ImGui::TextWrapped("%s", testLogs.c_str());
                    ImGui::EndChild();

                    ImGui::Columns(1);
                    ImGui::EndTabItem();
                }

                // Zakładka ESP
                if (ImGui::BeginTabItem("ESP")) {
                    // Main ESP toggle
                    ImGui::Checkbox("Enable ESP All Actors", &g_espConfig.enableESPAllActors);
                    if (g_espConfig.enableESPAllActors && !self.espInitialized) {
                        self.espInitialized = YES;
                        NSLog(@"ESP initialized");
                    }
                    
                    ImGui::SameLine();
                    if (ImGui::Button("Reset Settings")) {
                        g_espConfig = ESPConfig(); // Reset to defaults
                    }
                    
                    ImGui::Separator();
                    
                    // Simple ESP Features
                    if (ImGui::CollapsingHeader("ESP Features", ImGuiTreeNodeFlags_DefaultOpen)) {
                        ImGui::Columns(2);
                        
                        ImGui::Checkbox("2D Box", &g_espConfig.enable2DBox);
                        ImGui::Checkbox("Actor Names", &g_espConfig.enableActorNames);
                        
                        ImGui::NextColumn();
                        
                        ImGui::Checkbox("Distance Text", &g_espConfig.enableDistanceText);
                        
                        ImGui::Columns(1);
                    }
                    
                    // Style Settings
                    if (ImGui::CollapsingHeader("Style Settings", ImGuiTreeNodeFlags_DefaultOpen)) {
                        ImGui::Columns(2);
                        
                        ImGui::Text("Box Settings");
                        ImGui::SliderFloat("Box Thickness", &g_espConfig.boxThickness, 0.5f, 3.0f, "%.1f");
                        
                        ImGui::NextColumn();
                        
                        ImGui::Text("Display Settings");
                        ImGui::SliderFloat("Max Distance", &g_espConfig.maxDistance, 50.0f, 500.0f, "%.0f m");
                        ImGui::SliderFloat("Text Scale", &g_espConfig.textScale, 0.5f, 1.5f, "%.1f");
                        
                        ImGui::Columns(1);
                    }
                    
                    // Actor Type Colors
                    if (ImGui::CollapsingHeader("Actor Type Colors", ImGuiTreeNodeFlags_DefaultOpen)) {
                        ImGui::Text("Different colors for different actor types:");
                        ImGui::Separator();
                        
                        ImGui::Columns(2);
                        
                        ImGui::Text("Character Actors (BP_Character)");
                        ImGui::ColorEdit4("Character Color", (float*)&g_espConfig.characterColor);
                        
                        ImGui::Text("Item Actors (BP_Item, BP_Pickup)");
                        ImGui::ColorEdit4("Item Color", (float*)&g_espConfig.itemColor);
                        
                        ImGui::NextColumn();
                        
                        ImGui::Text("Vehicle Actors (BP_Vehicle, BP_Car)");
                        ImGui::ColorEdit4("Vehicle Color", (float*)&g_espConfig.vehicleColor);
                        
                        ImGui::Text("Weapon Actors (BP_Weapon, BP_Gun)");
                        ImGui::ColorEdit4("Weapon Color", (float*)&g_espConfig.weaponColor);
                        
                        ImGui::Columns(1);
                        
                        ImGui::Separator();
                        ImGui::Text("Other BP_ Actors");
                        ImGui::ColorEdit4("Default Color", (float*)&g_espConfig.defaultColor);
                        ImGui::ColorEdit4("Text Color", (float*)&g_espConfig.textColor);
                    }
                    
                    // Info section
                    if (ImGui::CollapsingHeader("Info")) {
                        ImGui::TextWrapped("This ESP shows all actors with 'BP_' prefix:");
                        ImGui::BulletText("Characters (green)");
                        ImGui::BulletText("Items/Pickups (yellow)");
                        ImGui::BulletText("Vehicles (blue)");
                        ImGui::BulletText("Weapons (red)");
                        ImGui::BulletText("Others (white)");
                        
                        ImGui::Separator();
                        ImGui::Text("Note: This will show ALL BP_ actors in the game world.");
                    }
                    
                    ImGui::EndTabItem();
                }

                // Nowa zakładka Debug
                if (ImGui::BeginTabItem("Debug")) {
                    static bool autoScroll = true;
                    static bool showTimestamp = false;
                    
                    // Przyciski kontrolne w jednym rzędzie
                    if (ImGui::Button("Clear Logs")) {
                        espLogs.clear();
                    }
                    ImGui::SameLine();
                    if (ImGui::Button("Copy Logs")) {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        NSString *logsString = [NSString stringWithUTF8String:espLogs.c_str()];
                        [pasteboard setString:logsString];
                    }
                    ImGui::SameLine();
                    ImGui::Checkbox("Auto-scroll", &autoScroll);
                    ImGui::SameLine();
                    ImGui::Checkbox("Show Timestamp", &showTimestamp);
                    
                    // Obszar logów
                    ImGui::BeginChild("Debug Logs", ImVec2(0, 0), true, ImGuiWindowFlags_HorizontalScrollbar);
                    
                    // Wyświetl logi
                    if (showTimestamp) {
                        // Dodaj znacznik czasu do każdej linii
                        std::istringstream logStream(espLogs);
                        std::string line;
                        while (std::getline(logStream, line)) {
                            if (!line.empty()) {
                                auto now = std::chrono::system_clock::now();
                                auto time = std::chrono::system_clock::to_time_t(now);
                                char timestamp[32];
                                strftime(timestamp, sizeof(timestamp), "[%H:%M:%S] ", localtime(&time));
                                ImGui::TextWrapped("%s%s", timestamp, line.c_str());
                            }
                        }
                    } else {
                        ImGui::TextWrapped("%s", espLogs.c_str());
                    }
                    
                    // Auto-scroll
                    if (autoScroll && ImGui::GetScrollY() >= ImGui::GetScrollMaxY()) {
                        ImGui::SetScrollHereY(1.0f);
                    }
                    
                    ImGui::EndChild();
                    ImGui::EndTabItem();
                }
                
                ImGui::EndTabBar();
            }

            ImGui::End();

            initial_setup();
        }

        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)dealloc {
    self.espInitialized = NO;
    g_espEnabled = false;
}

@end

