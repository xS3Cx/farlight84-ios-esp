#ifndef OFFSETS_H
#define OFFSETS_H

#include <cstdint>

namespace Offsets {
    struct Globals {
        const static uintptr_t GWorld = 0x89ad978; 
        const static uintptr_t GUObjectArray = 0x8934258; 
        const static uintptr_t GNames = 0x879c300; 
        const static uintptr_t ProcessEventOffset = 0x22B5538;
    };

    struct SDK {
        // UEngine
        const static uintptr_t UEngineToGameViewportClientClass = 0x118; 

        const static uintptr_t Function_GetActorBounds = 0x105dfeeb0; // Dostosuj ten offset do swojej gry


        // UGameViewportClient
        const static uintptr_t UGameViewportClientToWorld = 0x70; 

        // UWorld
        const static uintptr_t UWorldToPersistentLevel = 0x30; 
        const static uintptr_t UWorldToOwningGameInstance = 0x2C0; 

        // UGameInstance
        const static uintptr_t UGameInstanceToLocalPlayers = 0x38; 

        // UPlayer
        const static uintptr_t UPlayerToPlayerController = 0x30; 
        // AActor
        const static uintptr_t AActorToRootComponent = 0x1B0; 

        // USceneComponent
        const static uintptr_t USceneComponentToRelativeLocation = 0x134;  

        // APlayerController
        const static uintptr_t APlayerControllerToAcknowledgedPawn = 0x338; 
        const static uintptr_t APlayerControllerToPlayerCameraManager = 0x350; 
        // APlayerCameraManager
        const static uintptr_t APlayerCameraManagerToCameraCachePrivate = 0x1D80; 
        // FCameraCacheEntry
        const static uintptr_t FCameraCacheEntryToPOV = 0x10; 

        // FMinimalViewInfo
        const static uintptr_t FMinimalViewInfoToLocation = 0x0; 
        const static uintptr_t FMinimalViewInfoToRotation = 0xc; 
        const static uintptr_t FMinimalViewInfoToFOV = 0x18; 
        const static uintptr_t FCameraCacheEntryToCameraCache = 0x310; 
  
    };

    struct Special {
        const static uintptr_t ULevelToActorArray = 0x98;
        const static uintptr_t UObjectToFNameOffset = 0x18;
        const static uintptr_t TArrayToCount = 0xA0;
        const static uintptr_t PointerSize = 0x8;

        const static uintptr_t FNameStride = 0x2;
        const static uintptr_t FNamePoolBlocks = 0xc8;
        const static uintptr_t FNameHeader = 0x0;
        const static uintptr_t FNameLengthBit = 0x6; 
        const static uintptr_t FNameMaxSize = 0xFF;
        const static uintptr_t FNameHeaderSize = 0x2;

        const static uintptr_t TUObjectArrayToElementCount = 0x4; 
        const static uintptr_t FUObjectItemSize = 0x18;
    };
};

#endif /* OFFSETS_H */