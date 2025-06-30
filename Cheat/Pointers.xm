#import "Pointers.h"
#import <math.h>
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import <vector>
#import <utility>

// Definicje zmiennych globalnych
ESPConfig g_espConfig;
std::string testLogs;
std::string espLogs;

uintptr_t BaseAddress;

uintptr_t OwningGameInstance;
uintptr_t PersistentLevel;

uintptr_t LocalPlayer;
uintptr_t LocalPlayerCameraPOV;

uintptr_t(*ProcessEvent)(uintptr_t Instance, uintptr_t Function, uintptr_t Parameters);

bool g_espEnabled = false;

// Zmień definicję cachedActors aby przechowywała również wskaźnik do aktora
static std::vector<std::tuple<Vector3, float, uintptr_t>> cachedActors; // position, distance, ActorPtr

// Dodaj funkcję do pobierania ViewProjectionMatrix
FMatrix GetViewProjectionMatrix() {
    FMatrix viewProjectionMatrix;
    uintptr_t canvas = GetDebugCanvasObject();
    if (!canvas) return viewProjectionMatrix;
    
    // Odczytaj ViewProjectionMatrix z Canvas + 0x290
    uintptr_t matrixAddress = canvas + 0x290;
    if (IsAddressValid(matrixAddress)) {
        vm_read_buffer(matrixAddress, &viewProjectionMatrix, sizeof(FMatrix));
    }
    return viewProjectionMatrix;
}

bool GetLocalPlayerCameraPOV() {
    std::stringstream debugLog;
    debugLog << "\nGetLocalPlayerCameraPOV Debug:\n";
    
    if (!OwningGameInstance) {
        debugLog << "OwningGameInstance is null!\n";
        testLogs = debugLog.str();
        return false;
    }
    debugLog << "OwningGameInstance: 0x" << std::hex << OwningGameInstance << "\n";

    if (!IsAddressValid(OwningGameInstance + Offsets::SDK::UGameInstanceToLocalPlayers)) {
        debugLog << "Invalid UGameInstanceToLocalPlayers offset!\n";
        testLogs = debugLog.str();
        return false;
    }

    uintptr_t LocalPlayers = *(uintptr_t*)(OwningGameInstance + Offsets::SDK::UGameInstanceToLocalPlayers);
    if (!LocalPlayers) {
        debugLog << "LocalPlayers is null!\n";
        testLogs = debugLog.str();
        return false;
    }
    debugLog << "LocalPlayers: 0x" << std::hex << LocalPlayers << "\n";

    if (!IsAddressValid(LocalPlayers)) {
        debugLog << "Cannot read from LocalPlayers address!\n";
        testLogs = debugLog.str();
        return false;
    }

    uintptr_t ULocalPlayer = *(uintptr_t*)(LocalPlayers);
    if (!ULocalPlayer) {
        debugLog << "ULocalPlayer is null!\n";
        testLogs = debugLog.str();
        return false;
    }
    debugLog << "ULocalPlayer: 0x" << std::hex << ULocalPlayer << "\n";

    if (!IsAddressValid(ULocalPlayer + Offsets::SDK::UPlayerToPlayerController)) {
        debugLog << "Invalid UPlayerToPlayerController offset!\n";
        testLogs = debugLog.str();
        return false;
    }

    uintptr_t PlayerController = *(uintptr_t*)(ULocalPlayer + Offsets::SDK::UPlayerToPlayerController);
    if (!PlayerController) {
        debugLog << "PlayerController is null!\n";
        testLogs = debugLog.str();
        return false;
    }
    debugLog << "PlayerController: 0x" << std::hex << PlayerController << "\n";

    if (!IsAddressValid(PlayerController + Offsets::SDK::APlayerControllerToPlayerCameraManager)) {
        debugLog << "Invalid APlayerControllerToPlayerCameraManager offset!\n";
        testLogs = debugLog.str();
        return false;
    }

    uintptr_t PlayerCameraManager = *(uintptr_t*)(PlayerController + Offsets::SDK::APlayerControllerToPlayerCameraManager);
    if (!PlayerCameraManager) {
        debugLog << "PlayerCameraManager is null!\n";
        testLogs = debugLog.str();
        return false;
    }
    debugLog << "PlayerCameraManager: 0x" << std::hex << PlayerCameraManager << "\n";

    // Sprawdź offsety przed dodaniem
    debugLog << "APlayerCameraManagerToCameraCachePrivate: 0x" << std::hex << Offsets::SDK::APlayerCameraManagerToCameraCachePrivate << "\n";
    debugLog << "FCameraCacheEntryToPOV: 0x" << std::hex << Offsets::SDK::FCameraCacheEntryToPOV << "\n";

    LocalPlayerCameraPOV = PlayerCameraManager + Offsets::SDK::APlayerCameraManagerToCameraCachePrivate + Offsets::SDK::FCameraCacheEntryToPOV;
    debugLog << "Calculated LocalPlayerCameraPOV: 0x" << std::hex << LocalPlayerCameraPOV << "\n";
    
    if (!IsAddressValid(LocalPlayerCameraPOV)) {
        debugLog << "LocalPlayerCameraPOV is invalid!\n";
        testLogs = debugLog.str();
        return false;
    }

    debugLog << "LocalPlayerCameraPOV is valid!\n";
    testLogs = debugLog.str();
    return true;
}

uintptr_t GetLocalPlayerPtr() {
    if (!OwningGameInstance) return 0x0;
    uintptr_t LocalPlayers = *(uintptr_t*)(OwningGameInstance + Offsets::SDK::UGameInstanceToLocalPlayers);
    if (!LocalPlayers) return 0x0;
    uintptr_t ULocalPlayer = *(uintptr_t*)(LocalPlayers);
    if (!ULocalPlayer) return 0x0;
    uintptr_t PlayerController = *(uintptr_t*)(ULocalPlayer + Offsets::SDK::UPlayerToPlayerController);
    if (!PlayerController) return 0x0;
    uintptr_t LocalPlayer = *(uintptr_t*)(PlayerController + Offsets::SDK::APlayerControllerToAcknowledgedPawn);
    if (!LocalPlayer) return 0x0;
    
    return LocalPlayer;
}


uintptr_t GetRootComponent(uintptr_t Actor) {
    return *(uintptr_t*)(Actor + Offsets::SDK::AActorToRootComponent);
}


Vector3 GetActorPosition(uintptr_t RootComponent) {
    if (!RootComponent) return Vector3{0, 0, 0};
    return *(Vector3*)(RootComponent + Offsets::SDK::USceneComponentToRelativeLocation);
}
uintptr_t GetActorArray() {
    if (!PersistentLevel) return 0;
    return *(uintptr_t*)(PersistentLevel + Offsets::Special::ULevelToActorArray);
}

int32_t GetActorArrayCount() {
    uintptr_t Array = GetActorArray();
    if (!Array) return 0;
    return *(int32_t*)(Array + Offsets::Special::TArrayToCount);
}

void UpdatePointersLoop() {
    const int TargetCycleDurationMS = 16; // ~60 FPS
    std::stringstream debugLog;
    std::string currentLog;

    for (;;) {
        std::chrono::time_point<std::chrono::high_resolution_clock> CycleStartTime = std::chrono::high_resolution_clock::now();

        @try {
            debugLog.str("");
            debugLog.clear();
            debugLog << "UpdatePointersLoop Debug Info:\n\n";
            
            // Upewnij się, że mamy BaseAddress
            if (!BaseAddress) {
                BaseAddress = GetBaseAddressOfLibrary("SolarlandClient");
                if (!BaseAddress) {
                    debugLog << "Failed to get BaseAddress!\n";
                    goto LoopEnd;
                }
            }
            
            debugLog << "BaseAddress: 0x" << std::hex << BaseAddress << "\n";

            // Sprawdź GWorld
            uintptr_t GWorldAddr = BaseAddress + Offsets::Globals::GWorld;
            debugLog << "GWorld address would be: 0x" << std::hex << GWorldAddr << "\n";
            
            if (!IsAddressValid(GWorldAddr)) {
                debugLog << "GWorld address invalid!\n";
                goto LoopEnd;
            }
            
            uintptr_t GWorld = *(uintptr_t*)GWorldAddr;
            debugLog << "GWorld value: 0x" << std::hex << GWorld << "\n";
            
            if (!GWorld || !IsAddressValid(GWorld)) {
                debugLog << "GWorld pointer invalid!\n";
                goto LoopEnd;
            }

            // Sprawdź OwningGameInstance
            uintptr_t GameInstanceAddr = GWorld + Offsets::SDK::UWorldToOwningGameInstance;
            if (!IsAddressValid(GameInstanceAddr)) {
                debugLog << "GameInstance address invalid!\n";
                goto LoopEnd;
            }
            
            OwningGameInstance = *(uintptr_t*)GameInstanceAddr;
            debugLog << "OwningGameInstance: 0x" << std::hex << OwningGameInstance << "\n";
            
            if (!OwningGameInstance || !IsAddressValid(OwningGameInstance)) {
                debugLog << "OwningGameInstance pointer invalid!\n";
                goto LoopEnd;
            }

            // Sprawdź PersistentLevel
            uintptr_t LevelAddr = GWorld + Offsets::SDK::UWorldToPersistentLevel;
            if (!IsAddressValid(LevelAddr)) {
                debugLog << "PersistentLevel address invalid!\n";
                goto LoopEnd;
            }
            
            PersistentLevel = *(uintptr_t*)LevelAddr;
            debugLog << "PersistentLevel: 0x" << std::hex << PersistentLevel << "\n";
            
            if (!PersistentLevel || !IsAddressValid(PersistentLevel)) {
                debugLog << "PersistentLevel pointer invalid!\n";
                goto LoopEnd;
            }

            // Aktualizuj LocalPlayer
            LocalPlayer = GetLocalPlayerPtr();
            debugLog << "LocalPlayer: 0x" << std::hex << LocalPlayer << "\n";

            // Remove ESP drawing from here since we're doing it in the render thread

        } @catch (...) {
            debugLog << "Exception in UpdatePointersLoop!\n";
            OwningGameInstance = 0;
            PersistentLevel = 0;
            LocalPlayer = 0;
        }

        LoopEnd:
        if (!OwningGameInstance || !PersistentLevel || !LocalPlayer) {
            debugLog << "\nSome pointers are null:\n"
                    << "OwningGameInstance: 0x" << std::hex << OwningGameInstance << "\n"
                    << "PersistentLevel: 0x" << std::hex << PersistentLevel << "\n"
                    << "LocalPlayer: 0x" << std::hex << LocalPlayer << "\n";
        }

        // Najpierw skopiuj do lokalnego stringa
        currentLog = debugLog.str();
        
        // Potem zaktualizuj testLogs w głównym wątku
        dispatch_async(dispatch_get_main_queue(), ^{
            testLogs = currentLog;
        });

        std::chrono::time_point<std::chrono::high_resolution_clock> CycleEndTime = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> CycleDuration = CycleEndTime - CycleStartTime;
        int CycleDurationMS = static_cast<int>(CycleDuration.count());
        if (CycleDurationMS < TargetCycleDurationMS) {
            std::this_thread::sleep_for(std::chrono::milliseconds(TargetCycleDurationMS - CycleDurationMS));
        }
    }
}

std::string DebugStructOffsets() {
    std::stringstream logs;
    
    BaseAddress = GetBaseAddressOfLibrary("SolarlandClient");
    if (!BaseAddress) {
        logs << "Failed to get base address!\n";
        return logs.str();
    }
    
    logs << "Base Address: 0x" << std::hex << BaseAddress << "\n\n";
    
    // Debug GNames structure
    uintptr_t gnames_ptr = BaseAddress + Offsets::Globals::GNames;
    logs << "GNames at: 0x" << std::hex << gnames_ptr << "\n";
    
    // Pokaż pierwsze 128 bajtów struktury jako int32
    uint8_t buffer[128] = {0};
    if (vm_read_buffer(gnames_ptr, buffer, sizeof(buffer))) {
        logs << "\nGNames structure as int32 values:\n";
        int32_t* values = (int32_t*)buffer;
        for (int i = 0; i < 32; i++) {
            logs << "Offset 0x" << std::hex << (i * 4) << ": " 
                 << std::dec << values[i] << " (0x" << std::hex << values[i] << ")\n";
        }
    }
    
    // Debug TArray structure
    uintptr_t array_ptr = BaseAddress + Offsets::Globals::GUObjectArray;
    logs << "\nTArray at: 0x" << std::hex << array_ptr << "\n";
    
    if (vm_read_buffer(array_ptr, buffer, sizeof(buffer))) {
        logs << "\nTArray structure as int32 values:\n";
        int32_t* values = (int32_t*)buffer;
        for (int i = 0; i < 32; i++) {
            logs << "Offset 0x" << std::hex << (i * 4) << ": " 
                 << std::dec << values[i] << " (0x" << std::hex << values[i] << ")\n";
        }
    }
    
    return logs.str();
}

void DebugFNameEntry(std::stringstream& logs, int32_t Index) {
    int32_t BlockIndex = Index >> 16;
    int32_t ChunkIndex = Index & 0xFFFF;
    
    logs << "Debugging FName Index: " << std::dec << Index << "\n";
    logs << "Block Index: " << std::dec << BlockIndex << "\n";
    logs << "Chunk Index: " << std::dec << ChunkIndex << "\n";
    
    uintptr_t GNamesPtr = BaseAddress + Offsets::Globals::GNames;
    logs << "GNames at: 0x" << std::hex << GNamesPtr << "\n";
    
    // Odczytaj wskaźnik do bloku z offsetem 0xD0
    uintptr_t BlocksPtr = GNamesPtr + Offsets::Special::FNamePoolBlocks;
    logs << "Blocks array at: 0x" << std::hex << BlocksPtr << "\n";
    
    if (!IsAddressValid(BlocksPtr)) {
        logs << "Invalid blocks array address!\n";
        return;
    }
    
    uintptr_t BlockPtr = *(uintptr_t*)(BlocksPtr + (BlockIndex * sizeof(uintptr_t)));
    logs << "Block pointer: 0x" << std::hex << BlockPtr << "\n";
    
    if (!IsAddressValid(BlockPtr)) {
        logs << "Invalid block pointer!\n";
        return;
    }
    
    // Oblicz offset w bloku (stride = 4)
    uintptr_t EntryPtr = BlockPtr + (ChunkIndex * Offsets::Special::FNameStride);
    logs << "Entry at: 0x" << std::hex << EntryPtr << "\n\n";
    
    if (!IsAddressValid(EntryPtr)) {
        logs << "Invalid entry address!\n";
        return;
    }
    
    // Pokaż surowe dane
    logs << "Raw data:\n";
    for (int i = 0; i < 32; i += 16) {
        logs << std::hex << std::setw(4) << std::setfill('0') << i << ": ";
        for (int j = 0; j < 16; j++) {
            if (IsAddressValid(EntryPtr + i + j)) {
                uint8_t byte = *(uint8_t*)(EntryPtr + i + j);
                logs << std::hex << std::setw(2) << std::setfill('0') << (int)byte << " ";
            } else {
                logs << "?? ";
            }
        }
        logs << "  ";
        for (int j = 0; j < 16; j++) {
            if (IsAddressValid(EntryPtr + i + j)) {
                char c = *(char*)(EntryPtr + i + j);
                logs << (c >= 32 && c <= 126 ? c : '.');
            } else {
                logs << "?";
            }
        }
        logs << "\n";
    }
    
    // Odczytaj długość z offsetu 4
    if (IsAddressValid(EntryPtr + Offsets::Special::FNameHeader)) {
        uint16_t header = *(uint16_t*)(EntryPtr + Offsets::Special::FNameHeader);
        uint16_t length = header >> Offsets::Special::FNameLengthBit;
        
        if (length > 0 && length < Offsets::Special::FNameMaxSize) {
            if (IsAddressValid(EntryPtr + Offsets::Special::FNameHeaderSize)) {
                char nameBuffer[256] = {0};
                memcpy(nameBuffer, (void*)(EntryPtr + Offsets::Special::FNameHeaderSize), length);
                logs << "\nName: " << nameBuffer << "\n";
                logs << "Length: " << std::dec << length << "\n";
                logs << "Header: 0x" << std::hex << header << "\n";
            }
        }
    }
}

void TestActorName(std::stringstream& logs, uintptr_t Actor) {
    if (!Actor || !IsAddressValid(Actor)) {
        logs << "Invalid Actor pointer!\n";
        return;
    }
    
    logs << "Actor address: 0x" << std::hex << Actor << "\n";
    
    // Sprawdź czy możemy odczytać FName
    if (!IsAddressValid(Actor + Offsets::Special::UObjectToFNameOffset)) {
        logs << "Failed to read Actor FName at offset 0x" << std::hex << Offsets::Special::UObjectToFNameOffset << "\n";
        return;
    }
    
    int32_t ActorFName = *(int32_t*)(Actor + Offsets::Special::UObjectToFNameOffset);
    logs << "Actor FName Index: " << std::dec << ActorFName << "\n\n";
    
    if (ActorFName <= 0) {
        logs << "Invalid FName index!\n";
        return;
    }
    
    NSString* Name = GetNameFromFName(ActorFName);
    logs << "Actor Name: " << [Name UTF8String] << "\n";
}

void DebugActorArray(std::stringstream& logs) {
    if (!BaseAddress) {
        logs << "BaseAddress is null!\n";
        return;
    }

    // 1. Get GWorld
    uintptr_t GWorldPtr = BaseAddress + Offsets::Globals::GWorld;
    uintptr_t GWorld = *(uintptr_t*)GWorldPtr;
    logs << "GWorld: 0x" << std::hex << GWorld << "\n";

    if (!GWorld) {
        logs << "GWorld is null!\n";
        return;
    }

    // 2. Get PersistentLevel
    uintptr_t PersistentLevel = *(uintptr_t*)(GWorld + Offsets::SDK::UWorldToPersistentLevel);
    logs << "PersistentLevel: 0x" << std::hex << PersistentLevel << "\n";

    if (!PersistentLevel) {
        logs << "PersistentLevel is null!\n";
        return;
    }

    // 3. Get ActorArray
    uintptr_t ActorArray = *(uintptr_t*)(PersistentLevel + Offsets::Special::ULevelToActorArray);
    logs << "ActorArray: 0x" << std::hex << ActorArray << "\n";

    if (!ActorArray) {
        logs << "ActorArray is null!\n";
        return;
    }

    // 4. Get Actor Count
    int32_t ActorCount = *(int32_t*)(ActorArray + Offsets::Special::TArrayToCount);
    logs << "Actor Count: " << std::dec << ActorCount << "\n\n";

    // 5. List first few actors
    logs << "First 10 actors:\n";
    int maxActors = std::min(ActorCount, 10);
    
    for (int i = 0; i < maxActors; i++) {
        uintptr_t Actor = *(uintptr_t*)(ActorArray + i * Offsets::Special::PointerSize);
        if (!Actor) continue;

        // Get actor name if possible
        int32_t ActorFName = *(int32_t*)(Actor + Offsets::Special::UObjectToFNameOffset);
        NSString* Name = GetNameFromFName(ActorFName);
        
        logs << "Actor[" << i << "] at 0x" << std::hex << Actor 
             << " Name: " << [Name UTF8String] << "\n";
    }
}

void ScanForActorArrayPattern(std::stringstream& logs) {
    @try {
        logs << "Starting Extended ActorArray scan (0x000-0xFFF)...\n\n";

        if (!BaseAddress) {
            logs << "BaseAddress is null! Trying to get it...\n";
            BaseAddress = GetBaseAddressOfLibrary("SolarlandClient");
            if (!BaseAddress) {
                logs << "Failed to get BaseAddress!\n";
                return;
            }
        }
        logs << "BaseAddress: 0x" << std::hex << BaseAddress << "\n";

        uintptr_t GWorldPtr = BaseAddress + Offsets::Globals::GWorld;
        uintptr_t GWorld = 0;
        if (!vm_read_buffer(GWorldPtr, &GWorld, sizeof(GWorld))) {
            logs << "Failed to read GWorld!\n";
            return;
        }
        logs << "GWorld: 0x" << std::hex << GWorld << "\n";

        uintptr_t PersistentLevel = 0;
        if (!vm_read_buffer(GWorld + Offsets::SDK::UWorldToPersistentLevel, &PersistentLevel, sizeof(PersistentLevel))) {
            logs << "Failed to read PersistentLevel!\n";
            return;
        }
        logs << "PersistentLevel: 0x" << std::hex << PersistentLevel << "\n\n";

        logs << "Scanning offsets from 0x000 to 0xFFF...\n\n";
        
        // Skanuj wszystkie 3-znakowe offsety
        for (uint16_t offset = 0x000; offset <= 0xFFF; offset += 0x8) {
            @try {
                uintptr_t possibleArray = 0;
                if (!vm_read_buffer(PersistentLevel + offset, &possibleArray, sizeof(possibleArray))) {
                    continue;
                }

                if (!possibleArray || !IsAddressValid(possibleArray)) {
                    continue;
                }

                // Sprawdź strukturę TArray
                struct {
                    uintptr_t Data;
                    int32_t Count;
                    int32_t Max;
                } arrayStruct;

                if (!vm_read_buffer(possibleArray, &arrayStruct, sizeof(arrayStruct))) {
                    continue;
                }

                // Podstawowa walidacja tablicy
                if (arrayStruct.Count <= 0 || arrayStruct.Count > 500 || 
                    arrayStruct.Max <= 0 || arrayStruct.Max < arrayStruct.Count || 
                    arrayStruct.Max > 1000) {
                    continue;
                }

                if (!arrayStruct.Data || !IsAddressValid(arrayStruct.Data)) {
                    continue;
                }

                // Sprawdź aktory z RootComponent
                int validActorsWithRoot = 0;
                int totalValidActors = 0;
                std::stringstream actorDetails;

                for (int i = 0; i < std::min(10, arrayStruct.Count); i++) {
                    uintptr_t actorPtr = 0;
                    if (!vm_read_buffer(arrayStruct.Data + i * sizeof(uintptr_t), &actorPtr, sizeof(actorPtr))) {
                        continue;
                    }

                    if (!actorPtr || !IsAddressValid(actorPtr)) {
                        continue;
                    }

                    totalValidActors++;
                    
                    // Sprawdź RootComponent
                    uintptr_t RootComponent = 0;
                    if (!vm_read_buffer(actorPtr + Offsets::SDK::AActorToRootComponent, &RootComponent, sizeof(RootComponent))) {
                        continue;
                    }

                    if (!RootComponent || !IsAddressValid(RootComponent)) {
                        continue;
                    }

                    // Sprawdź czy możemy odczytać lokalizację
                    Vector3 Location;
                    if (!vm_read_buffer(RootComponent + Offsets::SDK::USceneComponentToRelativeLocation, &Location, sizeof(Location))) {
                        continue;
                    }

                    validActorsWithRoot++;

                    // Zbierz szczegóły aktora
                    int32_t FNameIndex = 0;
                    if (vm_read_buffer(actorPtr + Offsets::Special::UObjectToFNameOffset, &FNameIndex, sizeof(FNameIndex))) {
                        NSString* Name = GetNameFromFName(FNameIndex);
                        actorDetails << "  Actor[" << i << "] at 0x" << std::hex << actorPtr 
                                   << "\n    FName: " << std::dec << FNameIndex
                                   << "\n    Name: " << [Name UTF8String]
                                   << "\n    RootComponent: 0x" << std::hex << RootComponent
                                   << "\n    Location: (" << Location.X << ", " << Location.Y << ", " << Location.Z << ")\n\n";
                    }
                }

                // Pokaż tylko wyniki z prawidłowymi aktorami i RootComponent
                if (validActorsWithRoot >= 2) {
                    logs << "Found potential ActorArray at offset 0x" << std::hex << std::setfill('0') << std::setw(3) << offset << ":\n";
                    logs << "Array address: 0x" << std::hex << possibleArray << "\n";
                    logs << "Data address: 0x" << std::hex << arrayStruct.Data << "\n";
                    logs << "Total count: " << std::dec << arrayStruct.Count << "\n";
                    logs << "Max count: " << std::dec << arrayStruct.Max << "\n";
                    logs << "Valid actors: " << totalValidActors << "\n";
                    logs << "Actors with valid RootComponent: " << validActorsWithRoot << "\n\n";
                    logs << "Actor details:\n" << actorDetails.str();
                    logs << "\n----------------------------------------\n\n";
                }
            } @catch (...) {
                continue;
            }
        }
        
        logs << "Scan completed!\n";
    } @catch (...) {
        logs << "Critical exception in ScanForActorArrayPattern\n";
    }
}

void DebugActorArrayDetailed(std::stringstream& logs) {
    @try {
        if (!BaseAddress) {
            logs << "BaseAddress is null!\n";
            return;
        }

        uintptr_t GWorldPtr = BaseAddress + Offsets::Globals::GWorld;
        uintptr_t GWorld = 0;
        if (!vm_read_buffer(GWorldPtr, &GWorld, sizeof(GWorld))) {
            logs << "Failed to read GWorld!\n";
            return;
        }
        logs << "GWorld: 0x" << std::hex << GWorld << "\n";

        uintptr_t PersistentLevel = 0;
        if (!vm_read_buffer(GWorld + Offsets::SDK::UWorldToPersistentLevel, &PersistentLevel, sizeof(PersistentLevel))) {
            logs << "Failed to read PersistentLevel!\n";
            return;
        }
        logs << "PersistentLevel: 0x" << std::hex << PersistentLevel << "\n";

        // Używamy znalezionego offsetu 0x10
        uintptr_t ActorArrayPtr = 0;
        if (!vm_read_buffer(PersistentLevel + Offsets::Special::ULevelToActorArray, &ActorArrayPtr, sizeof(ActorArrayPtr))) {
            logs << "Failed to read ActorArray pointer!\n";
            return;
        }
        logs << "ActorArray pointer: 0x" << std::hex << ActorArrayPtr << "\n";

        int32_t ActorCount = 0;
        if (!vm_read_buffer(ActorArrayPtr + Offsets::Special::TArrayToCount, &ActorCount, sizeof(ActorCount))) {
            logs << "Failed to read ActorCount!\n";
            return;
        }
        logs << "Actor Count: " << std::dec << ActorCount << "\n\n";

        if (ActorCount <= 0 || ActorCount > 1000) {
            logs << "Invalid actor count!\n";
            return;
        }

        logs << "Detailed actor information:\n";
        for (int i = 0; i < std::min(10, ActorCount); i++) {
            uintptr_t ActorPtr = 0;
            if (!vm_read_buffer(ActorArrayPtr + i * Offsets::Special::PointerSize, &ActorPtr, sizeof(ActorPtr))) {
                logs << "Failed to read Actor pointer at index " << i << "\n";
                continue;
            }

            logs << "\nActor[" << i << "] at 0x" << std::hex << ActorPtr << "\n";
            
            if (!ActorPtr || !IsAddressValid(ActorPtr)) {
                logs << "  Invalid actor pointer\n";
                continue;
            }

            // Read FName
            int32_t FNameIndex = 0;
            if (!vm_read_buffer(ActorPtr + Offsets::Special::UObjectToFNameOffset, &FNameIndex, sizeof(FNameIndex))) {
                logs << "  Failed to read FName index\n";
                continue;
            }

            logs << "  FName Index: " << std::dec << FNameIndex << "\n";
            NSString* Name = GetNameFromFName(FNameIndex);
            logs << "  Name: " << [Name UTF8String] << "\n";

            // Try to read RootComponent
            uintptr_t RootComponent = 0;
            if (vm_read_buffer(ActorPtr + Offsets::SDK::AActorToRootComponent, &RootComponent, sizeof(RootComponent))) {
                logs << "  RootComponent: 0x" << std::hex << RootComponent << "\n";
                
                if (RootComponent && IsAddressValid(RootComponent)) {
                    Vector3 Location;
                    if (vm_read_buffer(RootComponent + Offsets::SDK::USceneComponentToRelativeLocation, &Location, sizeof(Location))) {
                        logs << "  Location: (" << Location.X << ", " << Location.Y << ", " << Location.Z << ")\n";
                    }
                }
            }
        }
    } @catch (...) {
        logs << "Exception in DebugActorArrayDetailed\n";
    }
}

void ScanForActorArray(std::stringstream& logs) {
    @try {
        logs << "Starting ActorArray scan with relaxed validation...\n\n";

        if (!BaseAddress) {
            logs << "BaseAddress is null! Trying to get it...\n";
            BaseAddress = GetBaseAddressOfLibrary("SolarlandClient");
            if (!BaseAddress) {
                logs << "Failed to get BaseAddress!\n";
                return;
            }
        }
        logs << "BaseAddress: 0x" << std::hex << BaseAddress << "\n";

        uintptr_t GWorldPtr = BaseAddress + Offsets::Globals::GWorld;
        uintptr_t GWorld = 0;
        if (!vm_read_buffer(GWorldPtr, &GWorld, sizeof(GWorld))) {
            logs << "Failed to read GWorld!\n";
            return;
        }
        logs << "GWorld: 0x" << std::hex << GWorld << "\n";

        uintptr_t PersistentLevel = 0;
        if (!vm_read_buffer(GWorld + Offsets::SDK::UWorldToPersistentLevel, &PersistentLevel, sizeof(PersistentLevel))) {
            logs << "Failed to read PersistentLevel!\n";
            return;
        }
        logs << "PersistentLevel: 0x" << std::hex << PersistentLevel << "\n\n";

        // Rozszerzony zakres skanowania
        logs << "Scanning offsets from 0x000 to 0x2000...\n\n";
        
        for (uint16_t offset = 0x000; offset <= 0x2000; offset += 0x8) {
            @try {
                uintptr_t possibleArray = 0;
                if (!vm_read_buffer(PersistentLevel + offset, &possibleArray, sizeof(possibleArray))) {
                    continue;
                }

                // Pokaż każdy znaleziony wskaźnik dla debugowania
                logs << "Checking offset 0x" << std::hex << std::setfill('0') << std::setw(3) << offset 
                     << " -> 0x" << possibleArray << "\n";

                if (!possibleArray) {
                    continue;
                }

                // Sprawdź strukturę TArray
                int32_t Count = 0;
                if (!vm_read_buffer(possibleArray + Offsets::Special::TArrayToCount, &Count, sizeof(Count))) {
                    continue;
                }

                // Bardziej liberalna walidacja liczby aktorów
                if (Count <= 0 || Count > 2000) {
                    continue;
                }

                logs << "Found array with count: " << std::dec << Count << "\n";

                // Sprawdź pierwsze kilka elementów
                int validActors = 0;
                std::stringstream actorDetails;

                for (int i = 0; i < std::min(5, Count); i++) {
                    uintptr_t actorPtr = 0;
                    if (!vm_read_buffer(possibleArray + i * sizeof(uintptr_t), &actorPtr, sizeof(actorPtr))) {
                        continue;
                    }

                    if (!actorPtr) {
                        continue;
                    }

                    // Próbuj odczytać FName
                    int32_t FNameIndex = 0;
                    if (!vm_read_buffer(actorPtr + Offsets::Special::UObjectToFNameOffset, &FNameIndex, sizeof(FNameIndex))) {
                        continue;
                    }

                    NSString* Name = GetNameFromFName(FNameIndex);
                    actorDetails << "  Actor[" << i << "] at 0x" << std::hex << actorPtr 
                               << "\n    FName: " << std::dec << FNameIndex
                               << "\n    Name: " << [Name UTF8String] << "\n";

                    // Spróbuj odczytać RootComponent
                    uintptr_t RootComponent = 0;
                    if (vm_read_buffer(actorPtr + Offsets::SDK::AActorToRootComponent, &RootComponent, sizeof(RootComponent))) {
                        actorDetails << "    RootComponent: 0x" << std::hex << RootComponent << "\n";
                    }

                    validActors++;
                }

                // Pokaż wszystkie potencjalne tablice
                if (validActors > 0) {
                    logs << "\nPotential ActorArray found at offset 0x" << std::hex << std::setfill('0') << std::setw(3) << offset << ":\n";
                    logs << "Array address: 0x" << std::hex << possibleArray << "\n";
                    logs << "Actor count: " << std::dec << Count << "\n";
                    logs << "Valid actors found: " << validActors << "\n\n";
                    logs << "Actor details:\n" << actorDetails.str();
                    logs << "\n----------------------------------------\n\n";
                }
            } @catch (...) {
                logs << "Exception at offset 0x" << std::hex << offset << "\n";
                continue;
            }
        }
        
        logs << "Scan completed!\n";
    } @catch (...) {
        logs << "Critical exception in ScanForActorArray\n";
    }
}

void DebugActorArrayOffset(std::stringstream& logs) {
    @try {
        logs << "Debugging ActorArray with hardcoded offset 0x98\n\n";

        if (!PersistentLevel) {
            logs << "PersistentLevel is null!\n";
            return;
        }
        logs << "PersistentLevel: 0x" << std::hex << PersistentLevel << "\n";

        if (!IsAddressValid(PersistentLevel + 0x98)) {
            logs << "Invalid ActorArray address!\n";
            return;
        }

        uintptr_t ActorArrayPtr = *(uintptr_t*)(PersistentLevel + 0x98);
        logs << "ActorArray pointer: 0x" << std::hex << ActorArrayPtr << "\n\n";

        if (!ActorArrayPtr || !IsAddressValid(ActorArrayPtr)) {
            logs << "ActorArray pointer is invalid!\n";
            return;
        }

        logs << "Searching for BP_Character actors:\n";
        int characterCount = 0;

        // Sprawdzamy aktory
        for (int i = 0; i < 50; i++) {
            @try {
                if (!IsAddressValid(ActorArrayPtr + (i * 8))) {
                    continue;
                }

                uintptr_t ActorPtr = *(uintptr_t*)(ActorArrayPtr + (i * 8));
                if (!ActorPtr || !IsAddressValid(ActorPtr)) {
                    continue;
                }

                if (!IsAddressValid(ActorPtr + Offsets::Special::UObjectToFNameOffset)) {
                    continue;
                }

                int32_t FNameIndex = *(int32_t*)(ActorPtr + Offsets::Special::UObjectToFNameOffset);
                if (FNameIndex <= 0) {
                    continue;
                }

                NSString* Name = GetNameFromFName(FNameIndex);
                if (!Name) {
                    continue;
                }
                
                // Sprawdź czy nazwa zawiera "BP_Character"
                if ([Name containsString:@"BP_Character"]) {
                    characterCount++;
                    logs << "\nFound BP_Character[" << characterCount << "] at index " << std::dec << i << ":\n";
                    logs << "  Address: 0x" << std::hex << ActorPtr << "\n";
                    logs << "  Name: " << [Name UTF8String] << "\n";
                    
                    // Get RootComponent and Location
                    if (IsAddressValid(ActorPtr + Offsets::SDK::AActorToRootComponent)) {
                        uintptr_t RootComponent = *(uintptr_t*)(ActorPtr + Offsets::SDK::AActorToRootComponent);
                        if (RootComponent && IsAddressValid(RootComponent)) {
                            logs << "  RootComponent: 0x" << std::hex << RootComponent << "\n";
                            
                            if (IsAddressValid(RootComponent + Offsets::SDK::USceneComponentToRelativeLocation)) {
                                Vector3 Location = *(Vector3*)(RootComponent + Offsets::SDK::USceneComponentToRelativeLocation);
                                logs << "  Location: (" << Location.X << ", " << Location.Y << ", " << Location.Z << ")\n";
                            }
                        }
                    }
                    logs << "  ----------------------\n";
                }
            } @catch (...) {
                logs << "Exception while processing actor at index " << i << "\n";
                continue;
            }
        }

        logs << "\nSummary:\n";
        logs << "Total BP_Character actors found: " << std::dec << characterCount << "\n";

    } @catch (...) {
        logs << "Exception occurred while debugging ActorArray!\n";
    }
}


uintptr_t GetLocalPlayerCameraManager() {
    if (!OwningGameInstance) return 0x0;
	uintptr_t LocalPlayers = *(uintptr_t*)(OwningGameInstance + Offsets::SDK::UGameInstanceToLocalPlayers);
	if (!LocalPlayers) return 0x0;
	uintptr_t ULocalPlayer = *(uintptr_t*)(LocalPlayers);
	if (!ULocalPlayer) return 0x0;
	uintptr_t PlayerController = *(uintptr_t*)(ULocalPlayer + Offsets::SDK::UPlayerToPlayerController);
	if (!PlayerController) return 0x0;
    uintptr_t LocalPlayerCameraManager = *(uintptr_t*)(PlayerController + Offsets::SDK::APlayerControllerToPlayerCameraManager);
	if (!LocalPlayerCameraManager) return 0x0;

    return LocalPlayerCameraManager;
}


uintptr_t GetLocalPlayer() {
    if (!OwningGameInstance) return 0x0;
	uintptr_t LocalPlayers = *(uintptr_t*)(OwningGameInstance + Offsets::SDK::UGameInstanceToLocalPlayers);
	if (!LocalPlayers) return 0x0;
	uintptr_t ULocalPlayer = *(uintptr_t*)(LocalPlayers);
	if (!ULocalPlayer) return 0x0;
	uintptr_t PlayerController = *(uintptr_t*)(ULocalPlayer + Offsets::SDK::UPlayerToPlayerController);
	if (!PlayerController) return 0x0;
	uintptr_t LocalPlayer = *(uintptr_t*)(PlayerController + Offsets::SDK::APlayerControllerToAcknowledgedPawn);
	if (!LocalPlayer) return 0x0;

    return LocalPlayer;
}



// Zmień funkcję GetActorBounds aby używała bezpośredniego odczytu pamięci
ActorBounds GetActorBounds(uintptr_t Actor) {
    ActorBounds bounds = {{0,0,0}, {0,0,0}};
    
    if (!Actor) return bounds;
    
    // Przygotuj parametry dla GetActorBounds
    struct {
        uintptr_t Actor;      // AActor*
        Vector3 Origin;       // FVector&
        Vector3 BoxExtent;    // FVector&
    } params;
    
    params.Actor = Actor;
    
    // Wywołaj funkcję GetActorBounds z KismetSystemLibrary
    uintptr_t KismetSysLibFunction = BaseAddress + Offsets::SDK::Function_GetActorBounds;
    if (ProcessEvent && IsAddressValid(KismetSysLibFunction)) {
        ProcessEvent(Actor, KismetSysLibFunction, (uintptr_t)&params);
        bounds.Origin = params.Origin;
        bounds.BoxExtent = params.BoxExtent;
    } else {
        // Fallback na domyślne wymiary jeśli wywołanie się nie powiedzie
        bounds.Origin = GetActorPosition(GetRootComponent(Actor));
        bounds.BoxExtent = {40.0f, 40.0f, 90.0f};
    }
    
    return bounds;
}

void DrawESP(ImGuiIO& io) {
    static std::chrono::steady_clock::time_point lastUpdateTime = std::chrono::steady_clock::now();
    static const std::chrono::milliseconds updateInterval(16); // ~60 FPS
    static Vector3 lastCameraLocation;
    static FMatrix lastViewMatrix;
    static bool dataUpdated = false;
    
    @try {
        auto currentTime = std::chrono::steady_clock::now();
        
        // Aktualizuj dane tylko co określony interwał
        if (currentTime - lastUpdateTime >= updateInterval) {
            lastUpdateTime = currentTime;
            dataUpdated = false;
            
            // Aktualizacja kamery i macierzy
            if (GetLocalPlayerCameraPOV()) {
                vm_read_buffer(LocalPlayerCameraPOV + Offsets::SDK::FMinimalViewInfoToLocation, 
                             &lastCameraLocation, sizeof(Vector3));
                lastViewMatrix = GetViewProjectionMatrix();
                dataUpdated = true;
            }

            // Aktualizacja pozycji aktorów
            if (PersistentLevel && IsAddressValid(PersistentLevel + 0x98)) {
                uintptr_t ActorArrayPtr = *(uintptr_t*)(PersistentLevel + 0x98);
                if (ActorArrayPtr && IsAddressValid(ActorArrayPtr)) {
                    // Wyczyść i prealokuj pamięć dla wektora
                    cachedActors.clear();
                    cachedActors.reserve(100); // Więcej miejsca dla wszystkich aktorów

                    // Cache wszystkich aktorów z prefiksem BP_
                    for (int i = 0; i < 100; i++) {
                        uintptr_t ActorPtr = *(uintptr_t*)(ActorArrayPtr + (i * 8));
                        if (!ActorPtr || !IsAddressValid(ActorPtr + Offsets::Special::UObjectToFNameOffset)) 
                            continue;

                        int32_t FNameIndex = *(int32_t*)(ActorPtr + Offsets::Special::UObjectToFNameOffset);
                        if (FNameIndex <= 0) continue;

                        NSString* Name = GetNameFromFName(FNameIndex);
                        if (!Name || ![Name hasPrefix:@"BP_"]) continue; // Wszystkie BP_ aktory

                        uintptr_t RootComponent = GetRootComponent(ActorPtr);
                        if (!RootComponent || !IsAddressValid(RootComponent)) continue;

                        Vector3 ActorPosition = GetActorPosition(RootComponent);
                        float distance = (ActorPosition - lastCameraLocation).Length() * 0.01f;
                        
                        // Only show actors within max distance
                        if (distance <= g_espConfig.maxDistance) {
                            cachedActors.push_back({ActorPosition, distance, ActorPtr});
                        }
                    }
                }
            }
        }

        // Rysuj ESP używając zbuforowanych danych
        if (!dataUpdated || cachedActors.empty()) return;

        ImDrawList* drawList = ImGui::GetForegroundDrawList();
        const float screenWidth = io.DisplaySize.x;
        const float screenHeight = io.DisplaySize.y;

        // Rysowanie ESP dla wszystkich BP_ aktorów
        for (const auto& actorData : cachedActors) {
            const Vector3& ActorPosition = std::get<0>(actorData);
            const float distance = std::get<1>(actorData);
            const uintptr_t ActorPtr = std::get<2>(actorData);
            
            // Pobierz nazwę aktora
            int32_t FNameIndex = *(int32_t*)(ActorPtr + Offsets::Special::UObjectToFNameOffset);
            NSString* ActorName = GetNameFromFName(FNameIndex);
            const char* actorNameStr = [ActorName UTF8String];
            
            // Określ kolor na podstawie typu aktora
            ImVec4 actorColor = g_espConfig.defaultColor;
            if ([ActorName containsString:@"BP_Character"]) {
                actorColor = g_espConfig.characterColor;
            } else if ([ActorName containsString:@"BP_Item"] || [ActorName containsString:@"BP_Pickup"]) {
                actorColor = g_espConfig.itemColor;
            } else if ([ActorName containsString:@"BP_Vehicle"] || [ActorName containsString:@"BP_Car"]) {
                actorColor = g_espConfig.vehicleColor;
            } else if ([ActorName containsString:@"BP_Weapon"] || [ActorName containsString:@"BP_Gun"]) {
                actorColor = g_espConfig.weaponColor;
            }
            
            // Zmienne dla box ESP
            float minX = FLT_MAX, minY = FLT_MAX;
            float maxX = -FLT_MAX, maxY = -FLT_MAX;

            Vector2 ScreenPosition;
            if (Project(ScreenPosition, ActorPosition, lastViewMatrix, screenWidth, screenHeight)) {
                if (ScreenPosition.X < -100 || ScreenPosition.X > screenWidth + 100 ||
                    ScreenPosition.Y < -100 || ScreenPosition.Y > screenHeight + 100) 
                    continue;

                // Oblicz granice boxa
                ActorBounds bounds = GetActorBounds(ActorPtr);
                Vector3 points[8];
                points[0] = bounds.Origin + bounds.BoxExtent;
                points[1] = bounds.Origin + Vector3(bounds.BoxExtent.X, bounds.BoxExtent.Y, -bounds.BoxExtent.Z);
                points[2] = bounds.Origin + Vector3(bounds.BoxExtent.X, -bounds.BoxExtent.Y, -bounds.BoxExtent.Z);
                points[3] = bounds.Origin + Vector3(bounds.BoxExtent.X, -bounds.BoxExtent.Y, bounds.BoxExtent.Z);
                points[4] = bounds.Origin - bounds.BoxExtent;
                points[5] = bounds.Origin + Vector3(-bounds.BoxExtent.X, -bounds.BoxExtent.Y, bounds.BoxExtent.Z);
                points[6] = bounds.Origin + Vector3(-bounds.BoxExtent.X, bounds.BoxExtent.Y, bounds.BoxExtent.Z);
                points[7] = bounds.Origin + Vector3(-bounds.BoxExtent.X, bounds.BoxExtent.Y, -bounds.BoxExtent.Z);

                // Znajdź granice 2D boxa
                for (const auto& point : points) {
                    Vector2 screenPoint;
                    if (Project(screenPoint, point, lastViewMatrix, screenWidth, screenHeight)) {
                        minX = std::min(minX, screenPoint.X);
                        minY = std::min(minY, screenPoint.Y);
                        maxX = std::max(maxX, screenPoint.X);
                        maxY = std::max(maxY, screenPoint.Y);
                    }
                }

                // 2D Box dla aktora
                if (g_espConfig.enable2DBox && minX != FLT_MAX) {
                    const ImU32 boxColorU32 = ImGui::ColorConvertFloat4ToU32(actorColor);
                    drawList->AddRect(
                        ImVec2(minX, minY),
                        ImVec2(maxX, maxY),
                        boxColorU32,
                        0.0f,
                        ImDrawFlags_None,
                        g_espConfig.boxThickness
                    );
                }

                // Nazwa aktora
                if (g_espConfig.enableActorNames) {
                    ImVec2 textSize = ImGui::CalcTextSize(actorNameStr);
                    float textX = minX + (maxX - minX - textSize.x) * 0.5f;
                    float textY = minY - textSize.y - 2.0f;
                    
                    // Subtle background
                    drawList->AddRectFilled(
                        ImVec2(textX - 1, textY - 1),
                        ImVec2(textX + textSize.x + 1, textY + textSize.y + 1),
                        IM_COL32(0, 0, 0, 100)
                    );
                    
                    // Text
                    drawList->AddText(
                        ImVec2(textX, textY),
                        ImGui::ColorConvertFloat4ToU32(g_espConfig.textColor),
                        actorNameStr
                    );
                }

                // Distance Text
                if (g_espConfig.enableDistanceText) {
                    char distanceText[16];
                    snprintf(distanceText, sizeof(distanceText), "%.0fm", distance);
                    const ImU32 textColorU32 = ImGui::ColorConvertFloat4ToU32(g_espConfig.textColor);
                    
                    ImVec2 textSize = ImGui::CalcTextSize(distanceText);
                    float textX = minX + (maxX - minX - textSize.x) * 0.5f;
                    float textY = maxY + 1.0f;
                    
                    // Very subtle background
                    drawList->AddRectFilled(
                        ImVec2(textX - 1, textY - 1),
                        ImVec2(textX + textSize.x + 1, textY + textSize.y + 1),
                        IM_COL32(0, 0, 0, 60)
                    );
                    
                    drawList->AddText(
                        ImVec2(textX, textY),
                        textColorU32,
                        distanceText
                    );
                }
            }
        }

    } @catch (...) {
        // Silent exception handling
    }
}

void DebugActorDimensions(uintptr_t Actor) {
    std::stringstream logs;
    logs << "Debugging Actor Dimensions at: 0x" << std::hex << Actor << "\n";
    
    // Skanuj pierwsze 0x1000 bajtów aktora w poszukiwaniu potencjalnych wymiarów
    for (uint32_t offset = 0x0; offset < 0x1000; offset += 4) {
        if (!IsAddressValid(Actor + offset)) continue;
        
        Vector3 potentialDimensions;
        if (vm_read_buffer(Actor + offset, &potentialDimensions, sizeof(Vector3))) {
            // Sprawdź czy wartości są w rozsądnym zakresie dla wymiarów postaci
            if (potentialDimensions.X > 10.0f && potentialDimensions.X < 200.0f &&
                potentialDimensions.Y > 10.0f && potentialDimensions.Y < 200.0f &&
                potentialDimensions.Z > 10.0f && potentialDimensions.Z < 200.0f) {
                logs << "Potential dimensions at offset 0x" << std::hex << offset << ":\n";
                logs << "X: " << potentialDimensions.X << "\n";
                logs << "Y: " << potentialDimensions.Y << "\n";
                logs << "Z: " << potentialDimensions.Z << "\n\n";
            }
        }
    }
    
    espLogs = logs.str(); // Zapisz logi do wyświetlenia
}

// Dodaj implementację funkcji
uintptr_t GetLocalPlayerState() {
    uintptr_t LocalPlayer = GetLocalPlayer();
    if (!LocalPlayer || !IsAddressValid(LocalPlayer)) return 0;
    
    uintptr_t PlayerState = *(uintptr_t*)(LocalPlayer + 0x2c0);
    if (!PlayerState || !IsAddressValid(PlayerState)) return 0;
    
    return PlayerState;
}