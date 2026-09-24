import os
import uuid

# Helper to generate Xcode style 24-character hexadecimal IDs
def gen_id():
    return uuid.uuid4().hex[:24].upper()

FILES = [
    # App
    ("DeyeMacOS/App/DeyeMacOSApp.swift", "DeyeMacOSApp.swift", "source"),
    ("DeyeMacOS/App/AppState.swift", "AppState.swift", "source"),
    # Models
    ("DeyeMacOS/Models/DeyeModels.swift", "DeyeModels.swift", "source"),
    ("DeyeMacOS/Models/StationSnapshot.swift", "StationSnapshot.swift", "source"),
    # Services
    ("DeyeMacOS/Services/DeyeAPI.swift", "DeyeAPI.swift", "source"),
    ("DeyeMacOS/Services/KeychainService.swift", "KeychainService.swift", "source"),
    ("DeyeMacOS/Services/CryptoHelper.swift", "CryptoHelper.swift", "source"),
    ("DeyeMacOS/Services/Formatters.swift", "Formatters.swift", "source"),
    # Views/Components
    ("DeyeMacOS/Views/Components/EnergyCard.swift", "EnergyCard.swift", "source"),
    ("DeyeMacOS/Views/Components/BatterySOCView.swift", "BatterySOCView.swift", "source"),
    ("DeyeMacOS/Views/Components/PowerFlowDiagram.swift", "PowerFlowDiagram.swift", "source"),
    # Views
    ("DeyeMacOS/Views/MainDashboardView.swift", "MainDashboardView.swift", "source"),
    ("DeyeMacOS/Views/MenuBarLabelView.swift", "MenuBarLabelView.swift", "source"),
    ("DeyeMacOS/Views/MenuBarPopoverView.swift", "MenuBarPopoverView.swift", "source"),
    ("DeyeMacOS/Views/LoginView.swift", "LoginView.swift", "source"),
    ("DeyeMacOS/Views/StationPickerView.swift", "StationPickerView.swift", "source"),
    ("DeyeMacOS/Views/SettingsView.swift", "SettingsView.swift", "source"),
    # Resources
    ("DeyeMacOS/Resources/Assets.xcassets", "Assets.xcassets", "resource"),
    ("DeyeMacOS/Resources/Info.plist", "Info.plist", "plist"),
    ("DeyeMacOS/Resources/DeyeMacOS.entitlements", "DeyeMacOS.entitlements", "entitlements"),
]

# Generate stable IDs
file_map = {}
for path, name, ftype in FILES:
    file_map[name] = {
        "path": path,
        "name": name,
        "type": ftype,
        "file_id": gen_id(),
        "build_id": gen_id() if ftype in ("source", "resource") else None
    }

proj_id = gen_id()
target_id = gen_id()
main_group_id = gen_id()
sources_build_phase_id = gen_id()
resources_build_phase_id = gen_id()
frameworks_build_phase_id = gen_id()
product_file_id = gen_id()
products_group_id = gen_id()

debug_target_cfg_id = gen_id()
release_target_cfg_id = gen_id()
target_cfg_list_id = gen_id()

debug_proj_cfg_id = gen_id()
release_proj_cfg_id = gen_id()
proj_cfg_list_id = gen_id()

# Subgroups
app_group_id = gen_id()
models_group_id = gen_id()
services_group_id = gen_id()
views_group_id = gen_id()
components_group_id = gen_id()
resources_group_id = gen_id()

pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""

for name, info in file_map.items():
    if info["build_id"]:
        pbx += f"""\t\t{info['build_id']} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {info['file_id']} /* {name} */; }};\n"""

pbx += f"""/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{product_file_id} /* DeyeMacOS.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DeyeMacOS.app; sourceTree = BUILT_PRODUCTS_DIR; }};
"""

for name, info in file_map.items():
    last_type = "sourcecode.swift"
    if info["type"] == "resource":
        last_type = "folder.assetcatalog"
    elif info["type"] == "plist":
        last_type = "text.plist.xml"
    elif info["type"] == "entitlements":
        last_type = "text.plist.entitlements"

    pbx += f"""\t\t{info['file_id']} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {last_type}; path = "{info['path']}"; sourceTree = "<group>"; }};\n"""

pbx += f"""/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_build_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_group_id} /* App */,
\t\t\t\t{models_group_id} /* Models */,
\t\t\t\t{services_group_id} /* Services */,
\t\t\t\t{views_group_id} /* Views */,
\t\t\t\t{resources_group_id} /* Resources */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{product_file_id} /* DeyeMacOS.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{app_group_id} /* App */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_map['DeyeMacOSApp.swift']['file_id']} /* DeyeMacOSApp.swift */,
\t\t\t\t{file_map['AppState.swift']['file_id']} /* AppState.swift */,
\t\t\t);
\t\t\tname = App;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{models_group_id} /* Models */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_map['DeyeModels.swift']['file_id']} /* DeyeModels.swift */,
\t\t\t\t{file_map['StationSnapshot.swift']['file_id']} /* StationSnapshot.swift */,
\t\t\t);
\t\t\tname = Models;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{services_group_id} /* Services */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_map['DeyeAPI.swift']['file_id']} /* DeyeAPI.swift */,
\t\t\t\t{file_map['KeychainService.swift']['file_id']} /* KeychainService.swift */,
\t\t\t\t{file_map['CryptoHelper.swift']['file_id']} /* CryptoHelper.swift */,
\t\t\t\t{file_map['Formatters.swift']['file_id']} /* Formatters.swift */,
\t\t\t);
\t\t\tname = Services;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{views_group_id} /* Views */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{components_group_id} /* Components */,
\t\t\t\t{file_map['MainDashboardView.swift']['file_id']} /* MainDashboardView.swift */,
\t\t\t\t{file_map['MenuBarLabelView.swift']['file_id']} /* MenuBarLabelView.swift */,
\t\t\t\t{file_map['MenuBarPopoverView.swift']['file_id']} /* MenuBarPopoverView.swift */,
\t\t\t\t{file_map['LoginView.swift']['file_id']} /* LoginView.swift */,
\t\t\t\t{file_map['StationPickerView.swift']['file_id']} /* StationPickerView.swift */,
\t\t\t\t{file_map['SettingsView.swift']['file_id']} /* SettingsView.swift */,
\t\t\t);
\t\t\tname = Views;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{components_group_id} /* Components */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_map['EnergyCard.swift']['file_id']} /* EnergyCard.swift */,
\t\t\t\t{file_map['BatterySOCView.swift']['file_id']} /* BatterySOCView.swift */,
\t\t\t\t{file_map['PowerFlowDiagram.swift']['file_id']} /* PowerFlowDiagram.swift */,
\t\t\t);
\t\t\tname = Components;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{resources_group_id} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_map['Assets.xcassets']['file_id']} /* Assets.xcassets */,
\t\t\t\t{file_map['Info.plist']['file_id']} /* Info.plist */,
\t\t\t\t{file_map['DeyeMacOS.entitlements']['file_id']} /* DeyeMacOS.entitlements */,
\t\t\t);
\t\t\tname = Resources;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} /* DeyeMacOS */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {target_cfg_list_id} /* Build configuration list for PBXNativeTarget "DeyeMacOS" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_build_phase_id} /* Sources */,
\t\t\t\t{frameworks_build_phase_id} /* Frameworks */,
\t\t\t\t{resources_build_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = DeyeMacOS;
\t\t\tproductName = DeyeMacOS;
\t\t\tproductReference = {product_file_id} /* DeyeMacOS.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_cfg_list_id} /* Build configuration list for PBXProject "DeyeMacOS" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_id} /* DeyeMacOS */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_build_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{file_map['Assets.xcassets']['build_id']} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_build_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
"""

for name, info in file_map.items():
    if info["type"] == "source":
        pbx += f"""\t\t\t\t{info['build_id']} /* {name} in Sources */,\n"""

pbx += f"""\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_proj_cfg_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_proj_cfg_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_target_cfg_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "DeyeMacOS/Resources/DeyeMacOS.entitlements";
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "DeyeMacOS/Resources/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.deye.DeyeMacOS;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_target_cfg_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "DeyeMacOS/Resources/DeyeMacOS.entitlements";
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "DeyeMacOS/Resources/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.deye.DeyeMacOS;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{proj_cfg_list_id} /* Build configuration list for PBXProject "DeyeMacOS" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_proj_cfg_id} /* Debug */,
\t\t\t\t{release_proj_cfg_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{target_cfg_list_id} /* Build configuration list for PBXNativeTarget "DeyeMacOS" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_target_cfg_id} /* Debug */,
\t\t\t\t{release_target_cfg_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {proj_id} /* Project object */;
}}
"""

with open("DeyeMacOS.xcodeproj/project.pbxproj", "w", encoding="utf-8") as f:
    f.write(pbx)

print("Created DeyeMacOS.xcodeproj/project.pbxproj successfully!")
