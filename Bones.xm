Vector3 GetBoneLocation(uintptr_t Player, int boneIdx) {
    if (Player) {
        return TransformToLocation(GetComponentToWorld(Player), GetBoneTransform(Player, boneIdx));
    }
    return {};
}


FTransform GetBoneTransform(uintptr_t entity, int idx) {
    uintptr_t Mesh = getMemoryAddr(entity + Offsets::Character::Mesh);
    if (Mesh) {
        uintptr_t Bones = getMemoryAddr(Mesh + Offsets::StaticMeshComponent::MinLOD);
        if (Bones) {
            return Read<FTransform>(Bones + (idx * 48));
        }
    }
    return {};
}

FTransform GetComponentToWorld(uintptr_t entity) {
    uintptr_t Mesh = getMemoryAddr(entity + Offsets::Character::Mesh);
    if (Mesh) {
        return Read<FTransform>(Mesh + 0x250);
    }
    return {};
}

 namespace Character {
        uintptr_t Mesh =  0x578 +0x8;
    }

    void DrawingSkeleton(CanvasEngine esp, Vector3 vec1, Vector3 vec2, Color color){
    esp.DrawLine(color, 1, Vector2(vec1.X, vec1.Y), Vector2(vec2.X, vec2.Y));
}
 if (showSkeleton) {
                        Color _skeletonColors = clrNew;
                        if (isnull(player.HeadLocation) && isnull(player.Bone.chest) &&
                            isnull(player.Bone.pelvis) && isnull(player.Bone.lShoulder)
                            && isnull(player.Bone.rShoulder) && isnull(player.Bone.lElbow) &&
                            isnull(player.Bone.rElbow) && isnull(player.Bone.lWrist)
                            && isnull(player.Bone.rWrist) && isnull(player.Bone.lThigh) &&
                            isnull(player.Bone.rThigh) && isnull(player.Bone.lKnee)
                            && isnull(player.Bone.rKnee) && isnull(player.Bone.lAnkle) &&
                            isnull(player.Bone.rAnkle)) {
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.neck, player.Bone.chest,
                                            _skeletonColors);
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.chest, player.Bone.pelvis,
                                            _skeletonColors);

                            DrawingSkeleton(CosmicDrawEngine, player.Bone.chest,
                                            player.Bone.lShoulder, _skeletonColors);
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.chest,
                                            player.Bone.rShoulder, _skeletonColors);

                            DrawingSkeleton(CosmicDrawEngine, player.Bone.lShoulder,
                                            player.Bone.lElbow, _skeletonColors);
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.rShoulder,
                                            player.Bone.rElbow, _skeletonColors);

                            DrawingSkeleton(CosmicDrawEngine, player.Bone.lElbow,
                                            player.Bone.lWrist, _skeletonColors);
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.rElbow,
                                            player.Bone.rWrist, _skeletonColors);

                            DrawingSkeleton(CosmicDrawEngine, player.Bone.pelvis,
                                            player.Bone.lThigh, _skeletonColors);
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.pelvis,
                                            player.Bone.rThigh, _skeletonColors);

                            DrawingSkeleton(CosmicDrawEngine, player.Bone.lThigh, player.Bone.lKnee,
                                            _skeletonColors);
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.rThigh, player.Bone.rKnee,
                                            _skeletonColors);

                            DrawingSkeleton(CosmicDrawEngine, player.Bone.lKnee, player.Bone.lAnkle,
                                            _skeletonColors);
                            DrawingSkeleton(CosmicDrawEngine, player.Bone.rKnee, player.Bone.rAnkle,
                                            _skeletonColors);
                        }
                    }

                      Vector3 neckPos = WorldToScreen(GetBoneLocation(actor, BoneID::neck_01), cameraManager.POV, Width,
                                            Height);
            Vector3 chestPos = WorldToScreen(GetBoneLocation(actor, BoneID::spine_03), cameraManager.POV, Width,
                                             Height);
            Vector3 pelvisPos = WorldToScreen(GetBoneLocation(actor, BoneID::pelvis), cameraManager.POV, Width,
                                              Height);
            Vector3 lShoulderPos = WorldToScreen(GetBoneLocation(actor, BoneID::eyebrow_l), cameraManager.POV,
                                                 Width, Height);
            Vector3 rShoulderPos = WorldToScreen(GetBoneLocation(actor, BoneID::nose_side_r_02),
                                                 cameraManager.POV, Width, Height);
            Vector3 lElbowPos = WorldToScreen(GetBoneLocation(actor, BoneID::eyebrow_r), cameraManager.POV, Width,
                                              Height);
            Vector3 rElbowPos = WorldToScreen(GetBoneLocation(actor, BoneID::nose_side_l_01), cameraManager.POV,
                                              Width, Height);
            Vector3 lWristPos = WorldToScreen(GetBoneLocation(actor, BoneID::hair_r_02), cameraManager.POV, Width,
                                              Height);
            Vector3 rWristPos = WorldToScreen(GetBoneLocation(actor, BoneID::hair_r_01), cameraManager.POV, Width,
                                              Height);
            Vector3 lThighPos = WorldToScreen(GetBoneLocation(actor, BoneID::lip_um_01), cameraManager.POV, Width,
                                              Height);
            Vector3 rThighPos = WorldToScreen(GetBoneLocation(actor, BoneID::lip_r), cameraManager.POV, Width,
                                              Height);
            Vector3 lKneePos = WorldToScreen(GetBoneLocation(actor, BoneID::lip_um_02), cameraManager.POV, Width,
                                             Height);
            Vector3 rKneePos = WorldToScreen(GetBoneLocation(actor, BoneID::hair_root), cameraManager.POV, Width,
                                             Height);
            Vector3 lAnklePos = WorldToScreen(GetBoneLocation(actor, BoneID::lip_ur), cameraManager.POV, Width,
                                              Height);
            Vector3 rAnklePos = WorldToScreen(GetBoneLocation(actor, BoneID::hair_b_01), cameraManager.POV, Width,
                                              Height);
          
enum BoneID : int {
    Root = 0,
    pelvis = 1,
    spine_01 = 2,
    spine_02 = 3,
    spine_03 = 4,
    neck_01 = 45,
    Head = 46,
    face_root = 7,
    eyebrows_pos_root = 8,
    eyebrows_root = 9,
    eyebrows_r = 10,
    eyebrows_l = 11,
    eyebrow_l = 12,
    eyebrow_r = 13,
    forehead_root = 14,
    forehead = 15,
    jaw_pos_root = 16,
    jaw_root = 17,
    jaw = 18,
    mouth_down_pos_root = 19,
    mouth_down_root = 20,
    lip_bm_01 = 21,
    lip_bm_02 = 22,
    lip_br = 23,
    lip_bl = 24,
    jaw_01 = 25,
    jaw_02 = 26,
    cheek_pos_root = 27,
    cheek_root = 28,
    cheek_r = 29,
    cheek_l = 30,
    nose_side_root = 31,
    nose_side_r_01 = 32,
    nose_side_r_02 = 33,
    nose_side_l_01 = 34,
    nose_side_l_02 = 35,
    eye_pos_r_root = 36,
    eye_r_root = 37,
    eye_rot_r_root = 38,
    eye_lid_u_r = 39,
    eye_r = 40,
    eye_lid_b_r = 41,
    eye_pos_l_root = 42,
    eye_l_root = 43,
    eye_rot_l_root = 44,
    eye_lid_u_l = 45,
    eye_l = 46,
    eye_lid_b_l = 47,
    nose_pos_root = 48,
    nose = 49,
    mouth_up_pos_root = 50,
    mouth_up_root = 51,
    lip_ul = 52,
    lip_um_01 = 53,
    lip_um_02 = 54,
    lip_ur = 55,
    lip_l = 56,
    lip_r = 57,
    hair_root = 58,
    hair_b_01 = 59,
    hair_b_02 = 60,
    hair_l_01 = 61,
    hair_l_02 = 62,
    hair_r_01 = 63,
    hair_r_02 = 64,
    hair_f_02 = 65,
    hair_f_01 = 66,
    hair_b_pt_01 = 67,
    hair_b_pt_02 = 68,
    hair_b_pt_03 = 69,
    hair_b_pt_04 = 70,
    hair_b_pt_05 = 71,
    camera_fpp = 72,
    GunReferencePoint = 73,
    GunRef = 74,
    breast_l = 75,
    breast_r = 76,
    clavicle_l = 77,
    upperarm_l = 78,
    lowerarm_l = 79,
    hand_l = 80,
    thumb_01_l = 81,
    thumb_02_l = 82,
    thumb_03_l = 83,
    thumb_04_l_MBONLY = 84,
    index_01_l = 85,
    index_02_l = 86,
    index_03_l = 87,
    index_04_l_MBONLY = 88,
    middle_01_l = 89,
    middle_02_l = 90,
    middle_03_l = 91,
    middle_04_l_MBONLY = 92,
    ring_01_l = 93,
    ring_02_l = 94,
    ring_03_l = 95,
    ring_04_l_MBONLY = 96,
    pinky_01_l = 97,
    pinky_02_l = 98,
    pinky_03_l = 99,
    pinky_04_l_MBONLY = 100,
    item_l = 101,
    lowerarm_twist_01_l = 102,
    upperarm_twist_01_l = 103,
    clavicle_r = 104,
    upperarm_r = 105,
    lowerarm_r = 106,
    hand_r = 107,
    thumb_01_r = 108,
    thumb_02_r = 109,
    thumb_03_r = 110,
    thumb_04_r_MBONLY = 111,
    index_01_r = 112,
    index_02_r = 113,
    index_03_r = 114,
    index_04_r_MBONLY = 115,
    middle_01_r = 116,
    middle_02_r = 117,
    middle_03_r = 118,
    middle_04_r_MBONLY = 119,
    ring_01_r = 120,
    ring_02_r = 121,
    ring_03_r = 122,
    ring_04_r_MBONLY = 123,
    pinky_01_r = 124,
    pinky_02_r = 125,
    pinky_03_r = 126,
    pinky_04_r_MBONLY = 127,
    item_r = 128,
    lowerarm_twist_01_r = 129,
    upperarm_twist_01_r = 130,
    BackPack = 131,
    backpack_01 = 132,
    backpack_02 = 133,
    Slot_Primary = 134,
    Slot_Secondary = 135,
    Slot_Melee = 136,
    slot_throwable = 137,
    coat_l_01 = 138,
    coat_l_02 = 139,
    coat_l_03 = 140,
    coat_l_04 = 141,
    coat_fl_01 = 142,
    coat_fl_02 = 143,
    coat_fl_03 = 144,
    coat_fl_04 = 145,
    coat_b_01 = 146,
    coat_b_02 = 147,
    coat_b_03 = 148,
    coat_b_04 = 149,
    coat_r_01 = 150,
    coat_r_02 = 151,
    coat_r_03 = 152,
    coat_r_04 = 153,
    coat_fr_01 = 154,
    coat_fr_02 = 155,
    coat_fr_03 = 156,
    coat_fr_04 = 157,
    thigh_l = 158,
    calf_l = 159,
    foot_l = 160,
    ball_l = 161,
    calf_twist_01_l = 162,
    thigh_twist_01_l = 163,
    thigh_r = 164,
    calf_r = 165,
    foot_r = 166,
    ball_r = 167,
    calf_twist_01_r = 168,
    thigh_twist_01_r = 169,
    Slot_SideArm = 170,
    skirt_l_01 = 171,
    skirt_l_02 = 172,
    skirt_l_03 = 173,
    skirt_f_01 = 174,
    skirt_f_02 = 175,
    skirt_f_03 = 176,
    skirt_b_01 = 177,
    skirt_b_02 = 178,
    skirt_b_03 = 179,
    skirt_r_01 = 180,
    skirt_r_02 = 181,
    skirt_r_03 = 182,
    ik_hand_root = 183,
    ik_hand_gun = 184,
    ik_hand_r = 185,
    ik_hand_l = 186,
    ik_aim_root = 187,
    ik_aim_l = 188,
    ik_aim_r = 189,
    ik_foot_root = 190,
    ik_foot_l = 191,
    ik_foot_r = 192,
    camera_tpp = 193,
    ik_target_root = 194,
    ik_target_l = 195,
    ik_target_r = 196,
    VB_spine_03_spine_03 = 197,
    VB_upperarm_r_lowerarm_r = 198
};


Vector3 GetBoneLocation(uintptr_t Player, int boneIdx) {
    if (Player) {
        return TransformToLocation(GetComponentToWorld(Player), GetBoneTransform(Player, boneIdx));
    }
    return {};
}

Vector3 GetHeadLocation(uintptr_t entity) {
    return GetBoneLocation(entity, BoneID::Head);
}


struct PlayerBone {
    Vector3 neck;
    Vector3 chest;
    Vector3 pelvis;
    Vector3 lShoulder;
    Vector3 rShoulder;
    Vector3 lElbow;
    Vector3 rElbow;
    Vector3 lWrist;
    Vector3 rWrist;
    Vector3 lThigh;
    Vector3 rThigh;
    Vector3 lKnee;
    Vector3 rKnee;
    Vector3 lAnkle;
    Vector3 rAnkle;
};
