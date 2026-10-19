"""Arena v2 (lane V) - per-biome data: ground palette, cliff palette, kit pieces, size tweaks, extras.

Plain data, no bpy, so ground.py can use it outside Blender.
Kit roles are what layout.py places:
  tree_a  medium tree      tree_b  small tree      tree_c  big back tree     tree_d  accent tree
  grass_a/b/c  shrubs / tufts      rock_a  small rock      rock_b  big rock
  mesa_* / butte / ledge* / ridge  sandstone-style cliffs (shared Atia RockCliff meshes, vertex
                                   painted with the biome's CLIFF palette)
Each kit entry: (fbx under asset-library/godot-ready/src/, texture basename or None to take the
FBX's own, alpha clip or None, unlit). Texture basenames are looked up next to the FBX (Source dir,
then the biome folder); `tex_px` caps the copied texture size.
"""

ENV = 'HomeLand_Asset/Environment/'

# Ground palettes (sRGB hex). Lit in game at roughly x1.1-1.3 (x1.0 for the toned-down Arctic),
# so these are darker than the Land hub ground they imitate.
PALETTES = {
    'savannah': dict(
        seed=0, light='C9B052', mid='B68A36', stain='8C4E1C', bleach='D6BE62',
        grass_dark='9C8C3C', grass_light='B3A04C', grass_rim='A0742C',
        dust='CDB476', rut='A87A3A', stone_a='ABA28A', stone_b='8C8670', grout='6C5634', halo='9E6A2C',
        peb='8C6434', pebhi='CDB27E', outer='A48C40'),
    'forest': dict(
        seed=5, light='8FB15E', mid='6E9C46', stain='4D7834', bleach='A2BF68', stain_w=0.5,
        grass_dark='4E8738', grass_light='62A044', grass_rim='5A7A36',
        dust='9C8458', rut='6E5A38', stone_a='A3A68E', stone_b='808672', grout='4E5A3A', halo='4C6E30',
        peb='586838', pebhi='B6C688', outer='5C8A3E',
        dots=[('F2E27A', 0.9, 0.07, 0.11), ('F2A6C6', 1.1, 0.05, 0.11), ('F6F2E6', 1.3, 0.05, 0.09)]),
    'arctic': dict(
        seed=9, light='CFD7E0', mid='B7C2CE', stain='95A3B5', bleach='DCE2E8', stain_w=0.5, bleach_w=0.45,
        grass_dark='868B90', grass_light='9CA2A8', grass_rim='A6B2BE', grass_w=0.8,
        dust='9AA3AD', rut='7B8490', stone_a='8F97A2', stone_b='747D89', grout='505864', halo='8C98A6',
        peb='7A8592', pebhi='E6ECF0', outer='A6B3C2',
        dots=[('E2EEF6', 1.2, 0.05, 0.07)]),
    'mystic': dict(
        seed=13, light='6E5AA6', mid='54438A', stain='3B2E66', bleach='8470BC',
        grass_dark='5A489A', grass_light='7660BC', grass_rim='46387A',
        dust='8A78B8', rut='5E4E8E', stone_a='9C94B8', stone_b='7A7298', grout='3E3460', halo='3A2C60',
        peb='3C3068', pebhi='B8A8E8', outer='4A3C78',
        dots=[('E8CCFF', 1.0, 0.06, 0.07), ('A6ECFF', 1.4, 0.05, 0.07)]),
    'genesis': dict(
        seed=17, light='C8B27A', mid='A88A52', stain='7E5E32', bleach='D8C690',
        grass_dark='8C9858', grass_light='A0AC68', grass_rim='8A7444',
        dust='D2C08C', rut='9A7C4C', stone_a='C0B496', stone_b='9C9076', grout='6A5A3C', halo='84663A',
        peb='7A5C34', pebhi='DCCB9A', outer='9A8250',
        dots=[('F6E27A', 1.0, 0.05, 0.09)]),
    'luna': dict(
        seed=21, light='7A7F9C', mid='5F6482', stain='454A66', bleach='9096B4',
        grass_dark='4A6E80', grass_light='5C8696', grass_rim='3E4560', grass_w=0.6,
        dust='8E92AE', rut='5A5E7A', stone_a='9A9CB4', stone_b='7C7E98', grout='3A3C52', halo='404460',
        peb='3E425C', pebhi='B0B6D2', outer='4E5270',
        craters=dict(cell=7.0, radius=1.6), crater='4A4E6A', crater_lip='9A9EBC',
        dots=[('C8D4FF', 1.2, 0.05, 0.07)]),
}

# Cliff vertex palettes: grass/snow top (2 tones), 5 strata bottom->top, underside.
CLIFF = {
    'savannah': dict(top=('BC9440', '9C8536'), bands=('74452A', '8A5432', '9C633A', '8E5634', 'AC7644'), under='5A3420'),
    'forest': dict(top=('5E9A3E', '4C8434'), bands=('6A665A', '7A7668', '888474', '76725F', '928B78'), under='46433C'),
    'arctic': dict(top=('D6DEE6', 'C2CCD6'), bands=('6C7682', '7C8692', '8A94A0', '78828E', '98A2AC'), under='525A64'),
    'mystic': dict(top=('7A62C0', '5E4C9C'), bands=('4A3E6E', '57497E', '64568C', '524676', '6E62A0'), under='30284A'),
    'genesis': dict(top=('C8B27A', 'A89A5E'), bands=('9A7A50', 'AC8A5C', 'BC9A68', 'A2825A', 'C8A876'), under='6A5034'),
    'luna': dict(top=('7A7F9C', '646A88'), bands=('4A4E66', '565A74', '626682', '52566E', '6E7290'), under='2E3044'),
}

KIT = {
    'savannah': {
        'tree_a': (ENV + 'Savannah/Tree/Source/SM_Tree02_Allside.fbx', 'T_Tree02_C.png', 0.5, True),
        'tree_b': (ENV + 'Savannah/Tree/Source/SM_Tree03a_Allside.fbx', 'T_Tree03_C.png', 0.5, True),
        'tree_c': (ENV + 'Savannah/Tree/Source/SM_Tree03_Allside.fbx', 'T_Tree03_C.png', 0.5, True),
        'tree_d': (ENV + 'Savannah/Tree/Source/SM_Tree01_Allside.fbx', 'T_Tree01_C.png', 0.5, True),
        'grass_a': (ENV + 'Savannah/Shrub/Source/SM_Shrub01_Allside_NoPlane.fbx', 'T_Shrub_savannah.png', 0.6, False),
        'grass_b': (ENV + 'Savannah/Shrub/Source/SM_Shrub02_Allside.fbx', 'T_Shrub_savannah.png', 0.6, False),
        'grass_c': (ENV + 'Savannah/Shrub/Source/SM_Shrub03_Allside.fbx', 'T_Shrub_savannah.png', 0.6, False),
        'rock_a': ('Atia_Asset/DeliveryAssets/Environment/Rock/SavannahRock/SM_SavannahRock_01.fbx', 'T_SavannahRock_01_C.png', None, False),
        'rock_b': ('Atia_Asset/DeliveryAssets/Environment/Rock/SavannahRock/SM_SavannahRock_02.fbx', 'T_SavannahRock_02_C.png', None, False),
    },
    'forest': {
        'tree_a': (ENV + 'Forest/Tree/Source/SM_Tree01_AllSide.fbx', 'tancay.png', 0.5, True),
        'tree_b': (ENV + 'Forest/Tree/Source/SM_Tree2_Allside.fbx', 'T_Spruce_C.png', 0.5, True),
        'tree_c': (ENV + 'Forest/Tree/Source/SM_Tree01_AllSide.fbx', 'tancay.png', 0.5, True),
        'tree_d': (ENV + 'Forest/Tree/Source/SM_Tree2_Allside.fbx', 'T_Spruce_C.png', 0.5, True),
        'grass_a': (ENV + 'Forest/Shrub/Source/SM_Shrub01_Allside.fbx', 'T_Shrub01_F_C.png', 0.5, False),
        'grass_b': (ENV + 'Forest/Shrub/Source/SM_Shrub02_Allside.fbx', 'T_Shrub02_F_C.png', 0.5, False),
        'grass_c': (ENV + 'Forest/Shrub/Source/SM_Shrub01_Allside.fbx', 'T_Shrub02_F_C.png', 0.5, False),
        'rock_a': (ENV + 'Forest/Quarry/Source/SM_Quarry_02.fbx', 'T_Quarry_C.png', None, False),
        'rock_b': (ENV + 'Forest/Quarry/Source/SM_Quarry_01.fbx', 'T_Quarry_C.png', None, False),
        'flower': (ENV + 'Forest/Ground/Flower/Source/SM_Flower.fbx', 'T_Flower.png', 0.5, True),
    },
    'arctic': {
        'tree_a': (ENV + 'Arctic/Tree/Source/SM_A_Tree01.fbx', 'T_Tree01_C.png', 0.5, True),
        'tree_b': (ENV + 'Arctic/Tree/Source/SM_A_Tree02.fbx', 'T_Tree02_C.png', 0.5, True),
        'tree_c': (ENV + 'Arctic/Tree/Source/SM_A_Tree01.fbx', 'T_Tree01_C.png', 0.5, True),
        'tree_d': (ENV + 'Arctic/Tree/Source/SM_A_Tree02.fbx', 'T_Tree02_C.png', 0.5, True),
        'grass_a': (ENV + 'Forest/Shrub/Source/SM_Shrub01_Allside.fbx', 'T_Shrub01_A_C.png', 0.5, False),
        'grass_b': (ENV + 'Forest/Shrub/Source/SM_Shrub02_Allside.fbx', 'T_Shrub02_A_C.png', 0.5, False),
        'grass_c': (ENV + 'Forest/Shrub/Source/SM_Shrub01_Allside.fbx', 'T_Shrub02_A_C.png', 0.5, False),
        'rock_a': (ENV + 'Arctic/Props/Source/SM_Stone_01.fbx', 'T_Rock_C.png', None, False),
        'rock_b': (ENV + 'Arctic/Rock/Source/SM_Rock_01.fbx', 'T_Rock_C.png', None, False),
        'log': (ENV + 'Arctic/Props/Source/SM_TreeLog_1.fbx', 'T_Props_C.png', None, False),
    },
    'mystic': {
        'tree_a': (ENV + 'Mystic/Tree/Source/SM_Tree_01_Allside.fbx', 'T_Tree_M_01.png', 0.5, True),
        'tree_b': (ENV + 'Mystic/Tree/Source/SM_Tree_02_Allside.fbx', 'T_Tree_M_02.png', 0.5, True),
        'tree_c': (ENV + 'Mystic/Tree/Source/SM_Tree_03_Allside.fbx', 'T_Tree_M_03.png', 0.5, True),
        'tree_d': (ENV + 'Mystic/Tree/Source/SM_Tree_04_Allside.fbx', 'T_Tree_M_04.png', 0.5, True),
        'grass_a': (ENV + 'Mystic/Shrub/Source/SM_Shrub01_M.fbx', 'T_Shrub01_M_C.png', 0.5, False),
        'grass_b': (ENV + 'Mystic/Shrub/Source/SM_Shrub02_M.fbx', 'T_Shrub02_M_C.png', 0.5, False),
        'grass_c': (ENV + 'Mystic/Shrub/Source/SM_Shrub01_M.fbx', 'T_Shrub02_M_C.png', 0.5, False),
        'rock_a': (ENV + 'Mystic/Rock/Source/SM_Rock_02.fbx', 'T_Rock_C.png', None, False),
        'rock_b': (ENV + 'Mystic/Rock/Source/SM_Rock_01.fbx', 'T_Rock_C.png', None, False),
    },
    'genesis': {
        'tree_a': (ENV + 'Genesis/Tree/Source/SM_Tree_G_01.fbx', None, 0.5, True),
        'tree_b': (ENV + 'Genesis/Tree/Source/SM_Tree_G_04.fbx', None, 0.5, True),
        'tree_c': (ENV + 'Genesis/Tree/Source/SM_Tree_G_03.fbx', None, 0.5, True),
        'tree_d': (ENV + 'Genesis/Tree/Source/SM_Tree_G_02.fbx', None, 0.5, True),
        'grass_a': (ENV + 'Forest/Shrub/Source/SM_Shrub01_Allside.fbx', 'T_Shrub01_G_C.png', 0.5, False),
        'grass_b': (ENV + 'Forest/Shrub/Source/SM_Shrub02_Allside.fbx', 'T_Shrub02_G_C.png', 0.5, False),
        'grass_c': (ENV + 'Forest/Shrub/Source/SM_Shrub01_Allside.fbx', 'T_Shrub02_G_C.png', 0.5, False),
        'rock_a': (ENV + 'Genesis/Rock/Source/SM_Rock_G_02.fbx', 'T_Rock_G_C.png', None, False),
        'rock_b': (ENV + 'Genesis/Rock/Source/SM_Rock_G_01.fbx', 'T_Rock_G_C.png', None, False),
    },
    'luna': {
        'tree_a': (ENV + 'LunaLanding/Tree/Source/SM_Luna_Landing_Tree_1.fbx', 'T_Luna_Landing_Tree_1_C.png', 0.5, True),
        'tree_b': (ENV + 'LunaLanding/Tree/Source/SM_Luna_Landing_Tree_3.fbx', 'T_Luna_Landing_Tree_3_C.png', 0.5, True),
        'tree_c': (ENV + 'LunaLanding/Tree/Source/SM_Luna_Landing_Tree_2.fbx', 'T_Luna_Landing_Tree_2_C.png', 0.5, True),
        'tree_d': (ENV + 'LunaLanding/Tree/Source/SM_Luna_Landing_Tree_4.fbx', 'T_Luna_Landing_Tree_4_C.png', 0.5, True),
        'grass_a': (ENV + 'LunaLanding/Shrub/Source/SM__Luna_Landing_Shrub01_Allside.fbx', 'T_Luna_Landing_Shrub_1_C.png', 0.5, False),
        'grass_b': (ENV + 'LunaLanding/Shrub/Source/SM_Luna_Landing_Shrub_1.fbx', 'T_Luna_Landing_Shrub_1_C.png', 0.5, False),
        'grass_c': (ENV + 'LunaLanding/Shrub/Source/SM__Luna_Landing_Shrub01_Allside.fbx', 'T_Luna_Landing_Shrub_1_C.png', 0.5, False),
        'rock_a': (ENV + 'LunaLanding/Luna_Landing_Rock/Source/SM_Luna_Landing_Rock_1.fbx', 'T_Luna_Landing_Rock_1_C.png', None, False),
        'rock_b': (ENV + 'LunaLanding/Rock/Source/SM_Rocks_Luna_A1.fbx', 'T_Rocks_Luna_A_C.png', None, False),
    },
}

# Height multipliers per role (the shared layout's heights are tuned for Savannah).
ROLE_H = {
    'forest': {'tree_c': 1.0, 'tree_b': 1.15, 'grass_a': 0.8, 'grass_b': 0.8, 'grass_c': 0.8},
    'arctic': {'grass_a': 0.8, 'grass_b': 0.8, 'grass_c': 0.8},
    'mystic': {'grass_a': 0.8, 'grass_b': 0.8, 'grass_c': 0.8},
    'genesis': {'grass_a': 0.8, 'grass_b': 0.8, 'grass_c': 0.8},
    'luna': {'grass_a': 0.8, 'grass_b': 0.8, 'grass_c': 0.8},
}

# Extra props on top of the shared layout: (role, x, z, yaw_deg, height_m).
EXTRAS = {
    'forest': [('flower', -14.6, -5.2, 0, 0.6), ('flower', -8.4, -12.0, 40, 0.6), ('flower', 10.2, 3.2, 90, 0.6),
               ('flower', 9.4, 7.8, 10, 0.5), ('tree_b', -19.0, -8.5, 0, 5.0), ('tree_b', 16.5, -3.0, 0, 5.5)],
    'arctic': [('log', -11.5, -7.5, 70, 0.7), ('log', 10.8, 2.6, 15, 0.6)],
}
