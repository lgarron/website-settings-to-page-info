#!/usr/bin/env fish

cd "$HOME/chromium/src/"

function rename
  for f in (find $argv[1] -iname "*website_settings*")
    set new (echo $f | sed "s/website_settings/page_info/")
    git mv $f $new
  end
end

function step_1_rename_files
  rename chrome/browser/ui/page_info
  rename chrome/browser/ui/cocoa/page_info
  rename chrome/browser/ui/views/page_info

  ./tools/git/mass-rename.py

  # Fix a stray header guared
  gsed --in-place="" \
    "s#CHROME_BROWSER_UI_COCOA_WEBSITE_SETTINGS_WEBSITE_SETTINGS_BUBBLE_CONTROLLER_H_#CHROME_BROWSER_UI_COCOA_PAGE_INFO_PAGE_INFO_BUBBLE_CONTROLLER_H_#g" \
    "chrome/browser/ui/cocoa/page_info/page_info_bubble_controller_unittest.mm"

  # Update test file names in the BUILD file separately (https://crbug.com/701529)
  gsed --in-place="" \
    "s#page_info/website_settings#page_info/page_info#g" \
    "chrome/test/BUILD.gn"

  # Re-sort
  gn format chrome/test/BUILD.gn
end


# OSX: Use gsed because `sed` doesn't handle word boundaries properly on OSX.
# brew install gnu-sed

function sed_cpp
  set common_match $argv[1]
  set -e argv[1]
  set replacement_args $argv

  for file in (ag --cpp --objcpp --java "$common_match" -l)
    for replacement in $replacement_args
      echo -n "."
      gsed --in-place="" $replacement $file
    end
    echo ""
  end
end

set -g CPP_SED_REPLACEMENTS ""

function addTokenReplacement
  echo "$argv[1] -> $argv[2]"
  set CPP_SED_REPLACEMENTS $CPP_SED_REPLACEMENTS "s#\b$argv[1]\b#$argv[2]#g"
end

function sed_and_reset
  echo "Sed and reset"
  sed_cpp "$argv[1]" $CPP_SED_REPLACEMENTS
  set -g CPP_SED_REPLACEMENTS ""
end

################################

function step_2_rename_classes

  set CPP_SED_REPLACEMENTS $CPP_SED_REPLACEMENTS "s#\"WebsiteSettings#TEMP_STRING_JSDLKFJDSF#g"
  sed_and_reset "WebsiteSettings"

  ################################

  # Based on:
  #
  #     ag --cpp --objcpp "\b[A-Za-z0-9_]*WebsiteSettings[A-Za-z0-9_]*\b" --only-matching --ignore-case --nonumbers --nofilename | sort | uniq
  # (scoped to desktop page_info folders)

  addTokenReplacement "ClearWebsiteSettings" "ClearPageInfo"
  # addTokenReplacement "FlushLossyWebsiteSettings" "FlushLossyPageInfo"
  addTokenReplacement "Java_WebsiteSettingsPopup_addPermissionSection" "Java_PageInfoPopup_addPermissionSection"
  addTokenReplacement "Java_WebsiteSettingsPopup_setSecurityDescription" "Java_PageInfoPopup_setSecurityDescription"
  addTokenReplacement "Java_WebsiteSettingsPopup_updatePermissionDisplay" "Java_PageInfoPopup_updatePermissionDisplay"
  # addTokenReplacement "LaunchedFromWebsiteSettingsPopup" "LaunchedFromPageInfoPopup"
  # addTokenReplacement "MobileWebsiteSettingsOpenedFromMenu" "MobilePageInfoOpenedFromMenu"
  # addTokenReplacement "MobileWebsiteSettingsOpenedFromToolbar" "MobilePageInfoOpenedFromToolbar"
  addTokenReplacement "MockWebsiteSettingsUI" "MockPageInfoUI"
  addTokenReplacement "RecordActionInWebsiteSettings" "RecordActionInPageInfo"
  addTokenReplacement "RecordWebsiteSettingsAction" "RecordPageInfoAction"
  addTokenReplacement "RegisterWebsiteSettingsPopupAndroid" "RegisterPageInfoPopupAndroid"
  addTokenReplacement "ShowWebsiteSettings" "ShowPageInfo"
  addTokenReplacement "ShowWebsiteSettingsBubbleViewsAtPoint" "ShowPageInfoBubbleViewsAtPoint"
  addTokenReplacement "SizeForWebsiteSettingsButtonTitle" "SizeForPageInfoButtonTitle"
  addTokenReplacement "WebSiteSettingsPopupViewBrowserTest" "PageInfoPopupViewBrowserTest"
  addTokenReplacement "WebSiteSettingsUmaUtil" "PageInfoUmaUtil"
  addTokenReplacement "WebsiteSettings" "PageInfo"
  addTokenReplacement "WebsiteSettingsAction" "PageInfoAction"
  addTokenReplacement "WebsiteSettingsBubbleController" "PageInfoBubbleController"
  addTokenReplacement "WebsiteSettingsBubbleControllerForTesting" "PageInfoBubbleControllerForTesting"
  addTokenReplacement "WebsiteSettingsBubbleControllerTest" "PageInfoBubbleControllerTest"
  addTokenReplacement "WebsiteSettingsFilterAdapter" "PageInfoFilterAdapter"
  addTokenReplacement "WebsiteSettingsInfo" "PageInfoInfo"
  addTokenReplacement "WebsiteSettingsInfoBarDelegate" "PageInfoInfoBarDelegate"
  addTokenReplacement "WebsiteSettingsPopup" "PageInfoPopup"
  addTokenReplacement "WebsiteSettingsPopupAndroid" "PageInfoPopupAndroid"
  addTokenReplacement "WebsiteSettingsPopupView" "PageInfoPopupView"
  addTokenReplacement "WebsiteSettingsPopupViewTest" "PageInfoPopupViewTest"
  addTokenReplacement "WebsiteSettingsPopupViewTestApi" "PageInfoPopupViewTestApi"
  addTokenReplacement "WebsiteSettingsPopup_jni" "PageInfoPopup_jni"
  addTokenReplacement "WebsiteSettingsRegistry" "PageInfoRegistry"
  addTokenReplacement "WebsiteSettingsRegistryTest" "PageInfoRegistryTest"
  addTokenReplacement "WebsiteSettingsTest" "PageInfoTest"
  addTokenReplacement "WebsiteSettingsUI" "PageInfoUI"
  addTokenReplacement "WebsiteSettingsUIBridge" "PageInfoUIBridge"
  addTokenReplacement "WebsiteSettingsUtils" "PageInfoUtils"
  addTokenReplacement "getWebsiteSettingsFilterPreference" "getPageInfoFilterPreference"
  addTokenReplacement "mNativeWebsiteSettingsPopup" "mNativePageInfoPopup"
  addTokenReplacement "nativeWebsiteSettingsPopupAndroid" "nativePageInfoPopupAndroid"
  addTokenReplacement "setWebsiteSettingsFilterPreference" "setPageInfoFilterPreference"
  addTokenReplacement "websiteSettingsUIBridge" "PageInfoUIBridge"

  sed_and_reset "WebsiteSettings"

  ################################

  set CPP_SED_REPLACEMENTS $CPP_SED_REPLACEMENTS "s#TEMP_STRING_JSDLKFJDSF#\"WebsiteSettings#g"
  sed_and_reset "TEMP_STRING_JSDLKFJDSF"

end

step_1_rename_files
step_2_rename_classes
git cl format

# Android
# WebsiteSettingsBubbleControllerForTesting
# Website settings
# WebSiteSettingsPopupViewBrowserTest and other test names.
# TODO(sashab): Rename this, and all its resources