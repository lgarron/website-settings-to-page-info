#!/usr/bin/env fish

cd "$HOME/chromium/src/"

set c "chrome"

set main "browser/ui"
set views "browser/ui/views"
set cocoa "browser/ui/cocoa"
set android "browser/ui/android"

set ws "website_settings"
set p "permission"
set pi "page_info"
set pv "popup_view"
set b "bubble"
set bs "bubbles"

################################

# OSX: Use gsed because `sed` doesn't handle word boundaries properly on OSX.
# brew install gnu-sed
# brew install parallel

set SED_CMD "gsed"
if not test (which gsed)
  function gsed
    set $argv
  end
end

function sed_cpp
  set common_match $argv[1]
  set -e argv[1]
  set replacement_args $argv

  for file in (ag --cpp --objcpp "$common_match" -l)
    for replacement in $replacement_args
      echo -n "."
      gsed --in-place="" $replacement $file
    end
    echo ""
  end
end

function sed_gyp
  set common_match $argv[1]
  set -e argv[1]
  set replacement_args $argv

  for file in (ag -G "(\.gyp|\.gypi|\.gn)\$" "$common_match" -l)
    for replacement in $replacement_args
      echo -n "-"
      gsed --in-place="" $replacement $file
    end
    echo ""
  end
end

################################

function folder_and_file_renames
  set -g CPP_SED_REPLACEMENTS ""
  set -g GYP_SED_REPLACEMENTS ""

  set -g current_step "$argv[1]"
  function move
    if [ "$current_step" = "step1-move" ]
      mv -v "$c/$argv[1]" "$c/$argv[2]"
    else
      echo "Recording" "$c/$argv[1]" "$c/$argv[2]"
    end
    # Leave filename as regex dots to keep it simple (there are no false positives).
    set -g CPP_SED_REPLACEMENTS $CPP_SED_REPLACEMENTS "s#$c/$argv[1]#$c/$argv[2]#g"
    set -g GYP_SED_REPLACEMENTS $GYP_SED_REPLACEMENTS "s#$argv[1]#$argv[2]#g"
  end

  function handleFolder
    move "$argv[1]" "$argv[2]"
  end

  # First argument is the folder of the file.
  function handleFile
    move "$argv[1]"/"$argv[2]" "$argv[1]"/"$argv[3]"
  end

  handleFolder "$main/$ws" "$main/$bs"

  handleFile "$main/$bs" $ws"_infobar_delegate.cc" $p"_infobar_delegate.cc"
  handleFile "$main/$bs" $ws"_infobar_delegate.h" $p"_infobar_delegate.h"

  handleFile "$main/$bs" $ws"_ui.cc" $pi"_ui.cc"
  handleFile "$main/$bs" $ws"_ui.h" $pi"_ui.h"
  handleFile "$main/$bs" $ws"_unittest.cc" $pi"_unittest.cc"
  handleFile "$main/$bs" $ws"_utils.cc" $pi"_utils.cc"
  handleFile "$main/$bs" $ws"_utils.h" $pi"_utils.h"
  handleFile "$main/$bs" $ws".cc" $pi".cc"
  handleFile "$main/$bs" $ws".h" $pi".h"

  ################################

  handleFolder "$views/$ws" "$views/$bs"

  handleFile "$views/$bs" $ws"_"$pv".cc" $pi"_"$b".cc"
  handleFile "$views/$bs" $ws"_"$pv".h" $pi"_"$b".h"
  handleFile "$views/$bs" $ws"_"$pv"_unittest.cc" $pi"_"$b"_unittest.cc"

  ################################

  handleFolder "$cocoa/$ws" "$cocoa/$bs"

  handleFile "$cocoa/$bs" $ws"_"$b"_controller_unittest.mm" $pi"_"$b"_controller_unittest.mm"
  handleFile "$cocoa/$bs" $ws"_"$b"_controller.h" $pi"_"$b"_controller.h"
  handleFile "$cocoa/$bs" $ws"_"$b"_controller.mm" $pi"_"$b"_controller.mm"
  handleFile "$cocoa/$bs" $ws"_utils_cocoa.h" $pi"_utils_cocoa.h"
  handleFile "$cocoa/$bs" $ws"_utils_cocoa.mm" $pi"_utils_cocoa.mm"

  ################################

  handleFile "$android" $ws"_popup_android.cc" $pi"_popup_android.cc"
  handleFile "$android" $ws"_popup_android.h" $pi"_popup_android.h"

  ################################

  if [ "$current_step" = "step2-fiximports" ]
    echo -n "Fixing imports..."
    sed_cpp "$ws" $CPP_SED_REPLACEMENTS
    sed_gyp "$ws" $GYP_SED_REPLACEMENTS

    git cl format
    echo "Done."
  end

end

################################

function step3renameCpp

  set -g CPP_SED_REPLACEMENTS ""

  function addTokenReplacement
    echo "$argv[1] -> $argv[2]"
    set CPP_SED_REPLACEMENTS $CPP_SED_REPLACEMENTS "s#\b$argv[1]\b#$argv[2]#g"
  end

  function sed_and_reset
    echo "Sed and reset"
    sed_cpp "WebsiteSettings" $CPP_SED_REPLACEMENTS
    set -g CPP_SED_REPLACEMENTS ""
  end

  ################################

  addTokenReplacement "\"WebsiteSettings" "TEMP_STRING_JSDLKFJDSF"
  sed_and_reset

  ################################

  # Based on:
  #
  #     ag --cpp --objcpp "\b[A-Za-z0-9_]*WebsiteSettings[A-Za-z0-9_]*\b" --only-matching --ignore-case --nonumbers --nofilename | sort | uniq
  #
  # addTokenReplacement "BuildWebsiteSettingsPatternMatchesFilter"          "BuildPageInfoPatternMatchesFilter"
  # addTokenReplacement "FlushLossyWebsiteSettings"                         "FlushLossyPageInfo"
  # addTokenReplacement "Java_WebsiteSettingsPopup_addPermissionSection"    "Java_PageInfoPopup_addPermissionSection"
  # addTokenReplacement "Java_WebsiteSettingsPopup_showDialog"              "Java_PageInfoPopup_showDialog"
  # addTokenReplacement "Java_WebsiteSettingsPopup_updatePermissionDisplay" "Java_PageInfoPopup_updatePermissionDisplay"
  # addTokenReplacement "MatchesWebsiteSettingsPattern"                     "MatchesPageInfoPattern"
  addTokenReplacement "MockWebsiteSettingsUI"                             "MockPageInfoUI"
  addTokenReplacement "RecordWebsiteSettingsAction"                       "RecordPageInfoAction"
  addTokenReplacement "RegisterWebsiteSettingsPopupAndroid"               "RegisterPageInfoPopupAndroid"
  addTokenReplacement "ShowWebsiteSettings"                               "ShowPageInfo"
  addTokenReplacement "ShowWebsiteSettingsBubbleViewsAtPoint"             "ShowPageInfoBubbleViewsAtPoint"
  addTokenReplacement "SizeForWebsiteSettingsButtonTitle"                 "SizeForPageInfoButtonTitle"
  # addTokenReplacement "WebSiteSettingsUmaUtil"                            "PageInfoUmaUtil"
  addTokenReplacement "WebsiteSettings"                                   "PageInfo"
  addTokenReplacement "WebsiteSettingsAction"                             "PageInfoAction"
  addTokenReplacement "WebsiteSettingsBubbleController"                   "PageInfoBubbleController"
  addTokenReplacement "WebsiteSettingsBubbleControllerForTesting"         "PageInfoBubbleControllerForTesting"
  addTokenReplacement "WebsiteSettingsBubbleControllerTest"               "PageInfoBubbleControllerTest"
  # addTokenReplacement "WebsiteSettingsInfo"                               "PageInfoInfo"
  # addTokenReplacement "WebsiteSettingsInfoBarDelegate"                    "PageInfoInfoBarDelegate"
  addTokenReplacement "WebsiteSettingsPopupAndroid"                       "PageInfoPopupAndroid"
  # addTokenReplacement "WebsiteSettingsPopupView"                          "PageInfoPopupView"
  # addTokenReplacement "WebsiteSettingsPopupViewTest"                      "PageInfoPopupViewTest"
  # addTokenReplacement "WebsiteSettingsPopupViewTestApi"                   "PageInfoPopupViewTestApi"
  # addTokenReplacement "WebsiteSettingsPopup_jni"                          "PageInfoPopup_jni"
  # addTokenReplacement "WebsiteSettingsRegistry"                           "PageInfoRegistry"
  # addTokenReplacement "WebsiteSettingsRegistryTest"                       "PageInfoRegistryTest"
  addTokenReplacement "WebsiteSettingsTest"                               "PageInfoTest"
  addTokenReplacement "WebsiteSettingsUI"                                 "PageInfoUI"
  addTokenReplacement "WebsiteSettingsUIBridge"                           "PageInfoUIBridge"
  addTokenReplacement "websiteSettingsUIBridge"                           "PageInfoUIBridge"

  # Bubble
  addTokenReplacement "WebsiteSettingsPopupView"                          "PageInfoBubble"
  addTokenReplacement "WebsiteSettingsPopupViewTest"                      "PageInfoBubbleTest"
  addTokenReplacement "WebsiteSettingsPopupViewTestApi"                   "PageInfoBubbleTestApi"

  # Permission
  addTokenReplacement "WebsiteSettingsInfoBarDelegate"                    "PermissionInfoBarDelegate"

  sed_and_reset

  ################################

  addTokenReplacement "TEMP_STRING_JSDLKFJDSF" "\"WebsiteSettings"
  sed_and_reset

  ################################

  # Based on:
  #
  #     ag --cpp --objcpp "\b[A-Za-z0-9_]*website_settings[A-Za-z0-9_]*\b" --only-matching --nonumbers --nofilename | sort | uniq
  #
  # addTokenReplacement "java_website_settings"              "java_page_info"
  # addTokenReplacement "java_website_settings_pop"          "java_page_info_pop"
  addTokenReplacement "website_settings"                   "page_info"
  addTokenReplacement "website_settings_"                  "page_info_"
  addTokenReplacement "website_settings_bubble_controller" "page_info_bubble_controller"
  addTokenReplacement "website_settings_info"              "page_info_info"
  addTokenReplacement "website_settings_info_"             "page_info_info_"
  # addTokenReplacement "website_settings_infobar_delegate"  "page_info_infobar_delegate"
  addTokenReplacement "website_settings_popup_android"     "page_info_popup_android"
  addTokenReplacement "website_settings_popup_view"        "page_info_popup_view"
  # addTokenReplacement "website_settings_registry"          "page_info_registry"
  # addTokenReplacement "website_settings_registry_"         "page_info_registry_"
  addTokenReplacement "website_settings_ui"                "page_info_ui"
  addTokenReplacement "website_settings_utils"             "page_info_utils"
  addTokenReplacement "website_settings_utils_cocoa"       "page_info_utils_cocoa"

  addTokenReplacement "website_settings_infobar_delegate"  "permission_infobar_delegate"

  ################################

  sed_and_reset

end

################################

switch "$argv[1]"
case "step1-move"
  folder_and_file_renames step1-move
case "step2-fiximports"
  folder_and_file_renames step2-fiximports
case "step3-rename-cpp"
  step3renameCpp
case "all"
  folder_and_file_renames step1-move
  folder_and_file_renames step2-fiximports
  step3renameCpp
end


################################

# TODO
# - header guards
# - with space: "Website Settings"
#   - ag --cpp --objcpp --java "\b[A-Za-z0-9_]*website settings[A-Za-z0-9_]*\b" --ignore-case
# - variables (lowercase, too)
# - constants/string IDs
# - histogram descriptions
