#!/usr/bin/env fish

cd "$HOME/chromium/src/"

set C "chrome"

set MAIN "browser/ui"
set VIEWS "browser/ui/views"
set COCOA "browser/ui/cocoa"
set ANDROID "browser/ui/android"

set WS "website_settings"
set P "permission"
set PI "page_info"
set B "bubble"
set BS "bubbles"

################################

function find_cpp
  ag --cpp --objcpp "$argv[1]" -l
end

function find_gyp_gn
  ag -G "(\.gyp|\.gypi|\.gn)\$" "$argv[1]" -l
end

################################

function replace_cpp
  find_cpp "$argv[1]" | xargs sed -i .bakkybackus "s#$argv[1]#$argv[2]#g"
  find . -iname "*.bakkybackus" | xargs rm
end

function replace_chrome_gyp_gn
  cd chrome
  find_gyp_gn "$argv[1]" | xargs sed -i .bakkybackus "s#$argv[1]#$argv[2]#g"
  find . -iname "*.bakkybackus" | xargs rm
  cd -
end

################################

function move
  mv -v               "$C/$argv[1]" "$C/$argv[2]"
  set CPP_FILE_LIST $CPP_FILE_LIST $argv[2]

  replace_cpp           "$C/$argv[1]" "$C/$argv[2]"
  replace_chrome_gyp_gn "$argv[1]"    "$argv[2]"
end

function moveFileInFolder
  move "$argv[1]"/"$argv[2]" "$argv[1]"/"$argv[3]"
end

function replaceToken
  echo "$argv[1] -> $argv[2]"
  replace_cpp "\b$argv[1]\b" "$argv[2]"
end

################################

move "$MAIN/$WS" "$MAIN/$BS"

moveFileInFolder "$MAIN/$BS" $WS"_infobar_delegate.cc" $P"_infobar_delegate.cc"
moveFileInFolder "$MAIN/$BS" $WS"_infobar_delegate.h" $P"_infobar_delegate.h"

moveFileInFolder "$MAIN/$BS" $WS"_ui.cc" $PI"_ui.cc"
moveFileInFolder "$MAIN/$BS" $WS"_ui.h" $PI"_ui.h"
moveFileInFolder "$MAIN/$BS" $WS"_unittest.cc" $PI"_unittest.cc"
moveFileInFolder "$MAIN/$BS" $WS"_utils.cc" $PI"_utils.cc"
moveFileInFolder "$MAIN/$BS" $WS"_utils.h" $PI"_utils.h"
moveFileInFolder "$MAIN/$BS" $WS".cc" $PI".cc"
moveFileInFolder "$MAIN/$BS" $WS".h" $PI".h"

################################

move "$VIEWS/$WS" "$VIEWS/$BS"

moveFileInFolder "$VIEWS/$BS" $WS"_popup_view.cc" $PI"_"$B".cc"
moveFileInFolder "$VIEWS/$BS" $WS"_popup_view.h" $PI"_"$B".h"
moveFileInFolder "$VIEWS/$BS" $WS"_popup_view_unittest.cc" $PI"_"$B"_unittest.cc"

################################

move "$COCOA/$WS" "$COCOA/$BS"

moveFileInFolder "$COCOA/$BS" $WS"_"$B"_controller_unittest.mm" $PI"_"$B"_controller_unittest.mm"
moveFileInFolder "$COCOA/$BS" $WS"_"$B"_controller.h" $PI"_"$B"_controller.h"
moveFileInFolder "$COCOA/$BS" $WS"_"$B"_controller.mm" $PI"_"$B"_controller.mm"
moveFileInFolder "$COCOA/$BS" $WS"_utils_cocoa.h" $PI"_utils_cocoa.h"
moveFileInFolder "$COCOA/$BS" $WS"_utils_cocoa.mm" $PI"_utils_cocoa.mm"

################################

moveFileInFolder "$ANDROID" $WS"_popup_android.cc" $PI"_popup_android.cc"
moveFileInFolder "$ANDROID" $WS"_popup_android.h" $PI"_popup_android.h"

################################

replaceToken "\"WebsiteSettings" "TEMP_STRING_JSDLKFJDSF"

# Based on:
#
#     ag --cpp --objcpp "\b[A-Za-z0-9_]*WebsiteSettings[A-Za-z0-9_]*\b" --only-matching --ignore-case --nonumbers --nofilename | sort | uniq
#
# replaceToken "BuildWebsiteSettingsPatternMatchesFilter"          "BuildPageInfoPatternMatchesFilter"
# replaceToken "FlushLossyWebsiteSettings"                         "FlushLossyPageInfo"
# replaceToken "Java_WebsiteSettingsPopup_addPermissionSection"    "Java_PageInfoPopup_addPermissionSection"
# replaceToken "Java_WebsiteSettingsPopup_showDialog"              "Java_PageInfoPopup_showDialog"
# replaceToken "Java_WebsiteSettingsPopup_updatePermissionDisplay" "Java_PageInfoPopup_updatePermissionDisplay"
# replaceToken "MatchesWebsiteSettingsPattern"                     "MatchesPageInfoPattern"
replaceToken "MockWebsiteSettingsUI"                             "MockPageInfoUI"
replaceToken "RecordWebsiteSettingsAction"                       "RecordPageInfoAction"
replaceToken "RegisterWebsiteSettingsPopupAndroid"               "RegisterPageInfoPopupAndroid"
replaceToken "ShowWebsiteSettings"                               "ShowPageInfo"
replaceToken "ShowWebsiteSettingsBubbleViewsAtPoint"             "ShowPageInfoBubbleViewsAtPoint"
replaceToken "SizeForWebsiteSettingsButtonTitle"                 "SizeForPageInfoButtonTitle"
# replaceToken "WebSiteSettingsUmaUtil"                            "PageInfoUmaUtil"
replaceToken "WebsiteSettings"                                   "PageInfo"
replaceToken "WebsiteSettingsAction"                             "PageInfoAction"
replaceToken "WebsiteSettingsBubbleController"                   "PageInfoBubbleController"
replaceToken "WebsiteSettingsBubbleControllerForTesting"         "PageInfoBubbleControllerForTesting"
replaceToken "WebsiteSettingsBubbleControllerTest"               "PageInfoBubbleControllerTest"
# replaceToken "WebsiteSettingsInfo"                               "PageInfoInfo"
# replaceToken "WebsiteSettingsInfoBarDelegate"                    "PageInfoInfoBarDelegate"
replaceToken "WebsiteSettingsPopupAndroid"                       "PageInfoPopupAndroid"
# replaceToken "WebsiteSettingsPopupView"                          "PageInfoPopupView"
# replaceToken "WebsiteSettingsPopupViewTest"                      "PageInfoPopupViewTest"
# replaceToken "WebsiteSettingsPopupViewTestApi"                   "PageInfoPopupViewTestApi"
# replaceToken "WebsiteSettingsPopup_jni"                          "PageInfoPopup_jni"
# replaceToken "WebsiteSettingsRegistry"                           "PageInfoRegistry"
# replaceToken "WebsiteSettingsRegistryTest"                       "PageInfoRegistryTest"
replaceToken "WebsiteSettingsTest"                               "PageInfoTest"
replaceToken "WebsiteSettingsUI"                                 "PageInfoUI"
replaceToken "WebsiteSettingsUIBridge"                           "PageInfoUIBridge"
replaceToken "websiteSettingsUIBridge"                           "PageInfoUIBridge"

# Bubble
replaceToken "WebsiteSettingsPopupView"                          "PageInfoBubble"
replaceToken "WebsiteSettingsPopupViewTest"                      "PageInfoBubbleTest"
replaceToken "WebsiteSettingsPopupViewTestApi"                   "PageInfoBubbleTestApi"

# Permission
replaceToken "WebsiteSettingsInfoBarDelegate"                    "PermissionInfoBarDelegate"


replaceToken "TEMP_STRING_JSDLKFJDSF" "\"WebsiteSettings"

################################

# Based on:
#
#     ag --cpp --objcpp "\b[A-Za-z0-9_]*website_settings[A-Za-z0-9_]*\b" --only-matching --nonumbers --nofilename | sort | uniq
#
# replaceToken "java_website_settings"              "java_page_info"
# replaceToken "java_website_settings_pop"          "java_page_info_pop"
replaceToken "website_settings"                   "page_info"
replaceToken "website_settings_"                  "page_info_"
replaceToken "website_settings_bubble_controller" "page_info_bubble_controller"
replaceToken "website_settings_info"              "page_info_info"
replaceToken "website_settings_info_"             "page_info_info_"
# replaceToken "website_settings_infobar_delegate"  "page_info_infobar_delegate"
replaceToken "website_settings_popup_android"     "page_info_popup_android"
replaceToken "website_settings_popup_view"        "page_info_popup_view"
# replaceToken "website_settings_registry"          "page_info_registry"
# replaceToken "website_settings_registry_"         "page_info_registry_"
replaceToken "website_settings_ui"                "page_info_ui"
replaceToken "website_settings_utils"             "page_info_utils"
replaceToken "website_settings_utils_cocoa"       "page_info_utils_cocoa"

replaceToken "website_settings_infobar_delegate"  "permission_infobar_delegate"

################################

# Hack the following line before `diff_cmd = BuildGitDiffCmd` in `depot_tools/git_cl.py`
#
#     cmd.append('-sort-includes')
#
git cl format

################################

# TODO
# - header guards
# - with space: "Website Settings"
#   - ag --cpp --objcpp --java "\b[A-Za-z0-9_]*website settings[A-Za-z0-9_]*\b" --ignore-case
# - variables (lowercase, too)