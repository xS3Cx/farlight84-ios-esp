#ifndef POINTERS_H
#define POINTERS_H

#import <Foundation/Foundation.h>
#import <string>
#import <sstream>
#import <iomanip>
#import <chrono>
#import <thread>

#import "Utils.h"
#import "Offsets.h"
#import "IMGUI/imgui.h"

extern uintptr_t BaseAddress;
extern uintptr_t OwningGameInstance;
extern uintptr_t PersistentLevel;
extern uintptr_t LocalPlayer;
extern std::string testLogs;

// Zmienne globalne
extern uintptr_t ActorArray;
extern int32_t ActorCount;
extern bool g_espEnabled;

// Dodaj deklarację
extern std::string espLogs;  // Bufor na logi ESP

// Funkcje do debugowania
std::string DebugStructOffsets();
void DebugFNameEntry(std::stringstream& logs, int32_t Index);
void TestActorName(std::stringstream& logs, uintptr_t Actor);
void DebugActorArray(std::stringstream& logs);
void DebugActorArrayDetailed(std::stringstream& logs);
void DebugActorArrayOffset(std::stringstream& logs);

// Funkcje pomocnicze
uintptr_t GetActorArray();
int32_t GetActorArrayCount();

uintptr_t GetRootComponent(uintptr_t Actor);
Vector3 GetActorPosition(uintptr_t RootComponent);

uintptr_t GetLocalPlayer();
uintptr_t GetLocalPlayerCameraManager();


void UpdatePointersLoop();

void ScanForActorArray(std::stringstream& logs);
void ScanForActorArrayPattern(std::stringstream& logs);

// Add this declaration
void DrawESP(ImGuiIO& io);

// Struktura konfiguracji ESP - uproszczona wersja
struct ESPConfig {
    // Simple ESP features - tylko podstawowe funkcje
    bool enableESPAllActors = false;
    bool enable2DBox = true;
    bool enableActorNames = true;
    bool enableDistanceText = true;
    
    // Style settings
    float boxThickness = 1.0f;
    float maxDistance = 200.0f;
    float textScale = 0.7f;
    
    // Kolory dla różnych typów aktorów
    ImVec4 characterColor = ImVec4(0.0f, 1.0f, 0.0f, 0.8f);      // Zielony dla postaci
    ImVec4 itemColor = ImVec4(1.0f, 1.0f, 0.0f, 0.8f);           // Żółty dla przedmiotów
    ImVec4 vehicleColor = ImVec4(0.0f, 0.7f, 1.0f, 0.8f);        // Niebieski dla pojazdów
    ImVec4 weaponColor = ImVec4(1.0f, 0.0f, 0.0f, 0.8f);         // Czerwony dla broni
    ImVec4 defaultColor = ImVec4(1.0f, 1.0f, 1.0f, 0.6f);        // Biały dla innych
    ImVec4 textColor = ImVec4(1.0f, 1.0f, 1.0f, 0.9f);
};

// Structure for UE4 FString
struct FString {
    wchar_t* Data;
    int32_t Count;
    int32_t Max;
};

// Helper function to get player name from actor
NSString* GetPlayerNameFromActor(uintptr_t ActorPtr);

// Usuń poprzednią definicję ActorBounds i dodaj nową:
struct ActorBounds {
    Vector3 Origin;    // Pozycja środka
    Vector3 BoxExtent; // Wymiary (połowa szerokości, długości, wysokości)
};

// Zmień definicję na deklarację
uintptr_t GetLocalPlayerState(); // Tylko deklaracja

extern ESPConfig g_espConfig;

#endif /* POINTERS_H */