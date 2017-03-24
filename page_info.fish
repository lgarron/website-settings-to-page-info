#!/usr/bin/env fish

cd "$HOME/chromium/src/"

function rename
  for f in (find $argv[1] -iname "*website_settings*")
    set new (echo $f | sed "s/website_settings/page_info/")
    git mv $f $new
  end
end

function step_1_a_cpp
  rename chrome/browser/ui/page_info
  rename chrome/browser/ui/cocoa/page_info
  rename chrome/browser/ui/views/page_info

  ./tools/git/mass-rename.py

  # Fix a stray include guard
  sed --in-place="" \
    "s#CHROME_BROWSER_UI_COCOA_WEBSITE_SETTINGS_WEBSITE_SETTINGS_BUBBLE_CONTROLLER_H_#CHROME_BROWSER_UI_COCOA_PAGE_INFO_PAGE_INFO_BUBBLE_CONTROLLER_H_#g" \
    "chrome/browser/ui/cocoa/page_info/page_info_bubble_controller.h"

  # Update test file names in the BUILD file separately (https://crbug.com/701529)
  sed --in-place="" \
    "s#page_info/website_settings#page_info/page_info#g" \
    "chrome/test/BUILD.gn"

  ./tools/git/mass-rename.py

  # Re-sort
  gn format chrome/test/BUILD.gn

end

function step_1_b_java
  rename chrome/browser/ui/android/page_info
  # website_settings.xml, website_settings_permission_row.xml
  rename chrome/android/java/res/layout

  mv \
    "chrome/android/java/src/org/chromium/chrome/browser/page_info/WebsiteSettingsPopup.java" \
    "chrome/android/java/src/org/chromium/chrome/browser/page_info/PageInfoPopup.java"

  # Update Java separately
  sed --in-place="" \
    "s#WebsiteSettingsPopup#PageInfoPopup#g" \
    "chrome/browser/BUILD.gn"

  gn format chrome/browser/BUILD.gn

  # Update Java separately
  sed --in-place="" \
    "s#WebsiteSettingsPopup#PageInfoPopup#g" \
    "chrome/test/BUILD.gn"

  gn format chrome/test/BUILD.gn

  # Update Java separately
  sed --in-place="" \
    "s#WebsiteSettingsPopup#PageInfoPopup#g" \
    "chrome/android/java_sources.gni"

  gn format chrome/android/java_sources.gni

  # Update autogenerated JNI include.
  sed --in-place="" \
    "s#WebsiteSettingsPopup_jni#PageInfoPopup_jni#g" \
    "chrome/browser/ui/android/page_info/page_info_popup_android.cc"

  # Update JNI functions.
  sed --in-place="" \
    "s#Java_WebsiteSettingsPopup#Java_PageInfoPopup#g" \
    "chrome/browser/ui/android/page_info/page_info_popup_android.cc"

  ./tools/git/mass-rename.py

end

function step_1_rename_files
  echo "Renaming C++ files"
  step_1_a_cpp
  echo "Renaming Java files"
  step_1_b_java
end


# OSX: Use gsed because `sed` doesn't handle word boundaries properly on OSX.
# brew install gnu-sed

function sed_src
  set common_match $argv[1]
  set -e argv[1]
  set path         $argv[1]
  set -e argv[1]
  set replacement_args $argv

  for file in (ag -i -l "$common_match" $path)
    for replacement in $replacement_args
      echo -n "."
      sed --in-place="" $replacement $file
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
  sed_src "$argv[1]" "$argv[2]" $CPP_SED_REPLACEMENTS
  set -g CPP_SED_REPLACEMENTS ""
end

################################

function step_2_rename_contents

  echo "Temporarily replacing strings"

  # Every string containing `WebsiteSettings` as a word is an UMA name that
  # should be preserved, *except* one case in page_info_unittest. We use a
  # unique string to preserve them, and restore the old name at the end.
  #
  # Our approach has false positives in e.g. website_settings_registry.cc, but
  # we don't want to replace any of those, so that is harmless.
  #
  # However, there is two false negatives, so we handle those manually.
  sed --in-place="" \
    "s#No WebsiteSettings instance created#No PageInfo instance created#g" \
    "chrome/browser/ui/page_info/page_info_unittest.cc"
  sed --in-place="" \
    "s#WebsiteSettingsPopupAndroid#PageInfoPopupAndroid#g" \
    "chrome/browser/android/chrome_jni_registrar.cc"

  set CPP_SED_REPLACEMENTS $CPP_SED_REPLACEMENTS "s#\(\".*\)WebsiteSettings#\1TEMP_STRING_JSDLKFJDSF#g"

  sed_and_reset "WebsiteSettings" .

  ################################

  # Based on:
  # ag --hidden --ignore-case --ignore "*.stamp" --ignore "*.ninja" "websitesettings"

  echo "Main replacements"

  # Used by page_info_unittest
    addTokenReplacement "ClearWebsiteSettings" "ClearPageInfo"
    addTokenReplacement "MockWebsiteSettingsUI" "MockPageInfoUI"
  
  # Content Settings
    # addTokenReplacement "FlushLossyWebsiteSettings" "FlushLossyPageInfo"
    # addTokenReplacement "getWebsiteSettingsFilterPreference" "getPageInfoFilterPreference"
    # addTokenReplacement "setWebsiteSettingsFilterPreference" "setPageInfoFilterPreference"
    # addTokenReplacement "WebsiteSettingsFilterAdapter" "PageInfoFilterAdapter"
    # addTokenReplacement "WebsiteSettingsHandler" "PageInfoHandler"
    # addTokenReplacement "WebsiteSettingsInfo" "PageInfoInfo"
    # addTokenReplacement "WebsiteSettingsRegistry" "PageInfoRegistry"
    # addTokenReplacement "WebsiteSettingsRegistryTest" "PageInfoRegistryTest"
    # addTokenReplacement "WebSiteSettingsUmaUtil" "PageInfoSettingsUmaUtil"
    # addTokenReplacement "WebsiteSettingsUtils" "PageInfoUtils"

  # UMA Actions
    # addTokenReplacement "LaunchedFromWebsiteSettingsPopup" "LaunchedFromPageInfoPopup"
    # addTokenReplacement "MobileWebsiteSettingsOpenedFromMenu" "MobilePageInfoOpenedFromMenu"
    # addTokenReplacement "MobileWebsiteSettingsOpenedFromToolbar" "MobilePageInfoOpenedFromToolbar"
  
  # PageInfoPopup.java
    addTokenReplacement "mNativeWebsiteSettingsPopup" "mNativePageInfoPopup"
    addTokenReplacement "nativeRecordWebsiteSettingsAction" "nativeRecordPageInfoAction"
    addTokenReplacement "nativeWebsiteSettingsPopupAndroid" "nativePageInfoPopupAndroid"
  
  # Permissions code
    # addTokenReplacement "RecordActionInWebsiteSettings" "RecordActionInPageInfo"
  
  # Page Info
    addTokenReplacement "RecordWebsiteSettingsAction" "RecordPageInfoAction"
  
  # Page Info JNI
    addTokenReplacement "RegisterWebsiteSettingsPopupAndroid" "RegisterPageInfoPopupAndroid"
  
  # Used by the browser to open Page Info
    addTokenReplacement "ShowWebsiteSettings" "ShowPageInfo"
    addTokenReplacement "ShowWebsiteSettingsBubbleViewsAtPoint" "ShowPageInfoBubbleViewsAtPoint"

  # Also shared by permission_bubble: https://crbug.com/701001
    addTokenReplacement "SizeForWebsiteSettingsButtonTitle" "SizeForPageInfoButtonTitle"
  
  # Handled below ("WebsiteSettings[Action]")
    # addTokenReplacement "WebsiteSettings" "PageInfo"
    # addTokenReplacement "WebsiteSettingsAction" "PageInfoAction"
  
  # Page Info Classes
    addTokenReplacement "WebsiteSettingsBubbleController" "PageInfoBubbleController"
    addTokenReplacement "WebsiteSettingsBubbleControllerForTesting" "PageInfoBubbleControllerForTesting"
    addTokenReplacement "WebsiteSettingsBubbleControllerTest" "PageInfoBubbleControllerTest"
    addTokenReplacement "WebsiteSettingsInfoBarDelegate" "PageInfoInfoBarDelegate"
    addTokenReplacement "WebsiteSettingsPopup" "PageInfoPopup"
    addTokenReplacement "WebsiteSettingsPopupAndroid" "PageInfoPopupAndroid"
    addTokenReplacement "WebsiteSettingsPopupView" "PageInfoPopupView"
    # aargh TooMuchCaMelCase
    addTokenReplacement "WebSiteSettingsPopupViewBrowserTest" "WebSiteSettingsPopupViewBrowserTest"
    addTokenReplacement "WebsiteSettingsPopupViewTest" "PageInfoPopupViewTest"
    addTokenReplacement "WebsiteSettingsPopupViewTestApi" "PageInfoPopupViewTestApi"
    addTokenReplacement "WebsiteSettingsTest" "PageInfoTest"
    addTokenReplacement "WebsiteSettingsUI" "PageInfoUI"
    addTokenReplacement "WebsiteSettingsUIBridge" "PageInfoUIBridge"
    addTokenReplacement "websiteSettingsUIBridge" "pageInfoUIBridge"

  sed_and_reset "WebsiteSettings" .

  ################################

  # Based on:
  # ag --hidden --ignore-case --ignore "*.stamp" --ignore "*.ninja" "website_settings"

  # Content Settings include guards
    # addTokenReplacement "COMPONENTS_CONTENT_SETTINGS_CORE_BROWSER_WEBSITE_SETTINGS_INFO_H_" "COMPONENTS_CONTENT_SETTINGS_CORE_BROWSER_PAGE_INFO_INFO_H_"
    # addTokenReplacement "COMPONENTS_CONTENT_SETTINGS_CORE_BROWSER_WEBSITE_SETTINGS_REGISTRY_H_" "COMPONENTS_CONTENT_SETTINGS_CORE_BROWSER_PAGE_INFO_REGISTRY_H_"

  # All Sites (Android) - android_chrome_strings.grd
    # addTokenReplacement "IDS_NO_SAVED_WEBSITE_SETTINGS" "IDS_NO_SAVED_PAGE_INFO"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE" "IDS_PAGE_INFO_ADD_SITE"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE_ADD_BUTTON" "IDS_PAGE_INFO_ADD_SITE_ADD_BUTTON"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE_DESCRIPTION_AUTOPLAY" "IDS_PAGE_INFO_ADD_SITE_DESCRIPTION_AUTOPLAY"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE_DESCRIPTION_BACKGROUND_SYNC" "IDS_PAGE_INFO_ADD_SITE_DESCRIPTION_BACKGROUND_SYNC"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE_DESCRIPTION_JAVASCRIPT" "IDS_PAGE_INFO_ADD_SITE_DESCRIPTION_JAVASCRIPT"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE_DIALOG_TITLE" "IDS_PAGE_INFO_ADD_SITE_DIALOG_TITLE"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE_SITE_URL" "IDS_PAGE_INFO_ADD_SITE_SITE_URL"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ADD_SITE_TOAST" "IDS_PAGE_INFO_ADD_SITE_TOAST"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_ALLOWED_GROUP_HEADING" "IDS_PAGE_INFO_ALLOWED_GROUP_HEADING"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_BLOCKED_GROUP_HEADING" "IDS_PAGE_INFO_BLOCKED_GROUP_HEADING"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_ALLOWED" "IDS_PAGE_INFO_CATEGORY_ALLOWED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_ALLOWED_EXCEPT_THIRD_PARTY" "IDS_PAGE_INFO_CATEGORY_ALLOWED_EXCEPT_THIRD_PARTY"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_ALLOWED_RECOMMENDED" "IDS_PAGE_INFO_CATEGORY_ALLOWED_RECOMMENDED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_ASK" "IDS_PAGE_INFO_CATEGORY_ASK"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_AUTOPLAY_ALLOWED" "IDS_PAGE_INFO_CATEGORY_AUTOPLAY_ALLOWED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_AUTOPLAY_DISABLED_DATA_SAVER" "IDS_PAGE_INFO_CATEGORY_AUTOPLAY_DISABLED_DATA_SAVER"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_BLOCKED" "IDS_PAGE_INFO_CATEGORY_BLOCKED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_BLOCKED_RECOMMENDED" "IDS_PAGE_INFO_CATEGORY_BLOCKED_RECOMMENDED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_CAMERA_ASK" "IDS_PAGE_INFO_CATEGORY_CAMERA_ASK"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_COOKIE_ALLOWED" "IDS_PAGE_INFO_CATEGORY_COOKIE_ALLOWED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_JAVASCRIPT_ALLOWED" "IDS_PAGE_INFO_CATEGORY_JAVASCRIPT_ALLOWED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_LOCATION_ASK" "IDS_PAGE_INFO_CATEGORY_LOCATION_ASK"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_MIC_ASK" "IDS_PAGE_INFO_CATEGORY_MIC_ASK"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_NOTIFICATIONS_ASK" "IDS_PAGE_INFO_CATEGORY_NOTIFICATIONS_ASK"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_CATEGORY_POPUPS_BLOCKED" "IDS_PAGE_INFO_CATEGORY_POPUPS_BLOCKED"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_DEVICE_LOCATION" "IDS_PAGE_INFO_DEVICE_LOCATION"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_EMBEDDED_IN" "IDS_PAGE_INFO_EMBEDDED_IN"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_EXCEPTIONS_GROUP_HEADING" "IDS_PAGE_INFO_EXCEPTIONS_GROUP_HEADING"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSIONS_ALLOW" "IDS_PAGE_INFO_PERMISSIONS_ALLOW"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSIONS_ALLOW_DSE" "IDS_PAGE_INFO_PERMISSIONS_ALLOW_DSE"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSIONS_ALLOW_DSE_ADDRESS_BAR" "IDS_PAGE_INFO_PERMISSIONS_ALLOW_DSE_ADDRESS_BAR"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSIONS_BLOCK" "IDS_PAGE_INFO_PERMISSIONS_BLOCK"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSIONS_BLOCK_DSE" "IDS_PAGE_INFO_PERMISSIONS_BLOCK_DSE"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSIONS_CATEGORY" "IDS_PAGE_INFO_PERMISSIONS_CATEGORY"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_REVOKE_DEVICE_PERMISSION" "IDS_PAGE_INFO_REVOKE_DEVICE_PERMISSION"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_SITE_CATEGORY" "IDS_PAGE_INFO_SITE_CATEGORY"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_STORAGE" "IDS_PAGE_INFO_STORAGE"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_USAGE_CATEGORY" "IDS_PAGE_INFO_USAGE_CATEGORY"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_USB" "IDS_PAGE_INFO_USB"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_USB_NO_DEVICES" "IDS_PAGE_INFO_USB_NO_DEVICES"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_USE_CAMERA" "IDS_PAGE_INFO_USE_CAMERA"
    # addTokenReplacement "IDS_WEBSITE_SETTINGS_USE_MIC" "IDS_PAGE_INFO_USE_MIC"
    # addTokenReplacement "no_saved_website_settings" "no_saved_page_info"
    # addTokenReplacement "website_settings_add_site" "page_info_add_site"
    # addTokenReplacement "website_settings_add_site_add_button" "page_info_add_site_add_button"
    # addTokenReplacement "website_settings_add_site_description_autoplay" "page_info_add_site_description_autoplay"
    # addTokenReplacement "website_settings_add_site_description_background_sync" "page_info_add_site_description_background_sync"
    # addTokenReplacement "website_settings_add_site_description_javascript" "page_info_add_site_description_javascript"
    # addTokenReplacement "website_settings_add_site_dialog_title" "page_info_add_site_dialog_title"
    # addTokenReplacement "website_settings_add_site_site_url" "page_info_add_site_site_url"
    # addTokenReplacement "website_settings_add_site_toast" "page_info_add_site_toast"
    # addTokenReplacement "website_settings_allowed_group_heading" "page_info_allowed_group_heading"
    # addTokenReplacement "website_settings_blocked_group_heading" "page_info_blocked_group_heading"
    # addTokenReplacement "website_settings_category_allowed" "page_info_category_allowed"
    # addTokenReplacement "website_settings_category_allowed_except_third_party" "page_info_category_allowed_except_third_party"
    # addTokenReplacement "website_settings_category_allowed_recommended" "page_info_category_allowed_recommended"
    # addTokenReplacement "website_settings_category_ask" "page_info_category_ask"
    # addTokenReplacement "website_settings_category_autoplay_allowed" "page_info_category_autoplay_allowed"
    # addTokenReplacement "website_settings_category_autoplay_disabled_data_saver" "page_info_category_autoplay_disabled_data_saver"
    # addTokenReplacement "website_settings_category_blocked" "page_info_category_blocked"
    # addTokenReplacement "website_settings_category_blocked_recommended" "page_info_category_blocked_recommended"
    # addTokenReplacement "website_settings_category_camera_ask" "page_info_category_camera_ask"
    # addTokenReplacement "website_settings_category_cookie_allowed" "page_info_category_cookie_allowed"
    # addTokenReplacement "website_settings_category_javascript_allowed" "page_info_category_javascript_allowed"
    # addTokenReplacement "website_settings_category_location_ask" "page_info_category_location_ask"
    # addTokenReplacement "website_settings_category_mic_ask" "page_info_category_mic_ask"
    # addTokenReplacement "website_settings_category_notifications_ask" "page_info_category_notifications_ask"
    # addTokenReplacement "website_settings_category_popups_blocked" "page_info_category_popups_blocked"
    # addTokenReplacement "website_settings_device_location" "page_info_device_location"
    # addTokenReplacement "website_settings_embedded_in" "page_info_embedded_in"
    # addTokenReplacement "website_settings_exceptions_group_heading" "page_info_exceptions_group_heading"
    # addTokenReplacement "website_settings_permissions_allow" "page_info_permissions_allow"
    # addTokenReplacement "website_settings_permissions_allow_dse" "page_info_permissions_allow_dse"
    # addTokenReplacement "website_settings_permissions_allow_dse_address_bar" "page_info_permissions_allow_dse_address_bar"
    # addTokenReplacement "website_settings_permissions_block" "page_info_permissions_block"
    # addTokenReplacement "website_settings_permissions_block_dse" "page_info_permissions_block_dse"
    # addTokenReplacement "website_settings_permissions_category" "page_info_permissions_category"
    # addTokenReplacement "website_settings_revoke_device_permission" "page_info_revoke_device_permission"
    # addTokenReplacement "website_settings_site_category" "page_info_site_category"
    # addTokenReplacement "website_settings_storage" "page_info_storage"
    # addTokenReplacement "website_settings_usage_category" "page_info_usage_category"
    # addTokenReplacement "website_settings_usb" "page_info_usb"
    # addTokenReplacement "website_settings_usb_no_devices" "page_info_usb_no_devices"
    # addTokenReplacement "website_settings_use_camera" "page_info_use_camera"
    # addTokenReplacement "website_settings_use_mic" "page_info_use_mic"

  # PageInfoAction enum
    addTokenReplacement "WEBSITE_SETTINGS_CERTIFICATE_DIALOG_OPENED" "PAGE_INFO_CERTIFICATE_DIALOG_OPENED"
    addTokenReplacement "WEBSITE_SETTINGS_CHANGED_PERMISSION" "PAGE_INFO_CHANGED_PERMISSION"
    addTokenReplacement "WEBSITE_SETTINGS_CONNECTION_HELP_OPENED" "PAGE_INFO_CONNECTION_HELP_OPENED"
    addTokenReplacement "WEBSITE_SETTINGS_CONNECTION_TAB_SELECTED" "PAGE_INFO_CONNECTION_TAB_SELECTED"
    addTokenReplacement "WEBSITE_SETTINGS_CONNECTION_TAB_SHOWN_IMMEDIATELY" "PAGE_INFO_CONNECTION_TAB_SHOWN_IMMEDIATELY"
    addTokenReplacement "WEBSITE_SETTINGS_COOKIES_DIALOG_OPENED" "PAGE_INFO_COOKIES_DIALOG_OPENED"
    addTokenReplacement "WEBSITE_SETTINGS_COUNT" "PAGE_INFO_COUNT"
    addTokenReplacement "WEBSITE_SETTINGS_OPENED" "PAGE_INFO_OPENED"
    addTokenReplacement "WEBSITE_SETTINGS_PERMISSIONS_TAB_SELECTED" "PAGE_INFO_PERMISSIONS_TAB_SELECTED"
    addTokenReplacement "WEBSITE_SETTINGS_SECURITY_DETAILS_OPENED" "PAGE_INFO_SECURITY_DETAILS_OPENED"
    addTokenReplacement "WEBSITE_SETTINGS_SITE_SETTINGS_OPENED" "PAGE_INFO_SITE_SETTINGS_OPENED"
    addTokenReplacement "WEBSITE_SETTINGS_TRANSPARENCY_VIEWER_OPENED" "PAGE_INFO_TRANSPARENCY_VIEWER_OPENED"

  # website_settings.xml / PageInfoPopup.java
    addTokenReplacement "website_settings_connection_message" "page_info_connection_message"
    addTokenReplacement "website_settings_connection_summary" "page_info_connection_summary"
    addTokenReplacement "website_settings_permissions_list" "page_info_permissions_list"
    addTokenReplacement "website_settings_instant_app_button" "page_info_instant_app_button"
    addTokenReplacement "website_settings_open_online_button" "page_info_open_online_button"
    addTokenReplacement "website_settings_popup_button_height" "page_info_popup_button_height"
    addTokenReplacement "website_settings_popup_button_padding_sides" "page_info_popup_button_padding_sides"
    addTokenReplacement "website_settings_popup_padding_sides" "page_info_popup_padding_sides"
    addTokenReplacement "website_settings_popup_text" "page_info_popup_text"
    addTokenReplacement "website_settings_site_settings_button" "page_info_site_settings_button"
    addTokenReplacement "website_settings_url" "page_info_url"

  # website_settings_permission_row.xml / PageInfoPopup.java\
  # Note: website_settings_popup_text is also shared by website_settings.xml
    addTokenReplacement "website_settings_permission_icon" "page_info_permission_icon"
    addTokenReplacement "website_settings_permission_row" "page_info_permission_row"
    addTokenReplacement "website_settings_permission_status" "page_info_permission_status"
    addTokenReplacement "website_settings_permission_unavailable_message" "page_info_permission_unavailable_message"
    addTokenReplacement "website_settings_popup_permission_icon_size" "page_info_popup_permission_icon_size"
    addTokenReplacement "website_settings_popup_text_link" "page_info_popup_text_link"


  # PageInfoUI
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_ALLOWED_BY_DEFAULT" "IDS_PAGE_INFO_BUTTON_TEXT_ALLOWED_BY_DEFAULT"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_ALLOWED_BY_EXTENSION" "IDS_PAGE_INFO_BUTTON_TEXT_ALLOWED_BY_EXTENSION"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_ALLOWED_BY_POLICY" "IDS_PAGE_INFO_BUTTON_TEXT_ALLOWED_BY_POLICY"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_ALLOWED_BY_USER" "IDS_PAGE_INFO_BUTTON_TEXT_ALLOWED_BY_USER"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_ASK_BY_DEFAULT" "IDS_PAGE_INFO_BUTTON_TEXT_ASK_BY_DEFAULT"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_ASK_BY_POLICY" "IDS_PAGE_INFO_BUTTON_TEXT_ASK_BY_POLICY"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_ASK_BY_USER" "IDS_PAGE_INFO_BUTTON_TEXT_ASK_BY_USER"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_BLOCKED_BY_DEFAULT" "IDS_PAGE_INFO_BUTTON_TEXT_BLOCKED_BY_DEFAULT"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_BLOCKED_BY_EXTENSION" "IDS_PAGE_INFO_BUTTON_TEXT_BLOCKED_BY_EXTENSION"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_BLOCKED_BY_POLICY" "IDS_PAGE_INFO_BUTTON_TEXT_BLOCKED_BY_POLICY"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_BLOCKED_BY_USER" "IDS_PAGE_INFO_BUTTON_TEXT_BLOCKED_BY_USER"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_DETECT_IMPORTANT_CONTENT_BY_DEFAULT" "IDS_PAGE_INFO_BUTTON_TEXT_DETECT_IMPORTANT_CONTENT_BY_DEFAULT"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_BUTTON_TEXT_DETECT_IMPORTANT_CONTENT_BY_USER" "IDS_PAGE_INFO_BUTTON_TEXT_DETECT_IMPORTANT_CONTENT_BY_USER"
  
  # PageInfo
    addTokenReplacement "IDS_WEBSITE_SETTINGS_DELETE_USB_DEVICE" "IDS_PAGE_INFO_DELETE_USB_DEVICE"

  # PageInfoInfobarDelegate
    addTokenReplacement "IDS_WEBSITE_SETTINGS_INFOBAR_BUTTON" "IDS_PAGE_INFO_INFOBAR_BUTTON"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_INFOBAR_TEXT" "IDS_PAGE_INFO_INFOBAR_TEXT"

  # WebVR Shell
    addTokenReplacement "IDS_WEBSITE_SETTINGS_INSECURE_WEBVR_CONTENT_PERMANENT" "IDS_PAGE_INFO_INSECURE_WEBVR_CONTENT_PERMANENT"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_INSECURE_WEBVR_CONTENT_TRANSIENT" "IDS_PAGE_INFO_INSECURE_WEBVR_CONTENT_TRANSIENT"

  # PermissionMenuModel
    addTokenReplacement "IDS_WEBSITE_SETTINGS_MENU_ITEM_ALLOW" "IDS_PAGE_INFO_MENU_ITEM_ALLOW"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_MENU_ITEM_BLOCK" "IDS_PAGE_INFO_MENU_ITEM_BLOCK"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_MENU_ITEM_DEFAULT_ALLOW" "IDS_PAGE_INFO_MENU_ITEM_DEFAULT_ALLOW"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_MENU_ITEM_DEFAULT_ASK" "IDS_PAGE_INFO_MENU_ITEM_DEFAULT_ASK"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_MENU_ITEM_DEFAULT_BLOCK" "IDS_PAGE_INFO_MENU_ITEM_DEFAULT_BLOCK"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_MENU_ITEM_DEFAULT_DETECT_IMPORTANT_CONTENT" "IDS_PAGE_INFO_MENU_ITEM_DEFAULT_DETECT_IMPORTANT_CONTENT"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_MENU_ITEM_DETECT_IMPORTANT_CONTENT" "IDS_PAGE_INFO_MENU_ITEM_DETECT_IMPORTANT_CONTENT"

  # Used by HTTP Basic Auth. To be unforked: https://crbug.com/704788
    addTokenReplacement "IDS_WEBSITE_SETTINGS_NON_SECURE_TRANSPORT" "IDS_PAGE_INFO_NON_SECURE_TRANSPORT"

  # Page Info
    addTokenReplacement "IDS_WEBSITE_SETTINGS_NUM_COOKIES" "IDS_PAGE_INFO_NUM_COOKIES"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSION_ALLOW" "IDS_PAGE_INFO_PERMISSION_ALLOW"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSION_ASK" "IDS_PAGE_INFO_PERMISSION_ASK"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_PERMISSION_BLOCK" "IDS_PAGE_INFO_PERMISSION_BLOCK"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TITLE" "IDS_PAGE_INFO_TITLE"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TITLE_SITE_DATA" "IDS_PAGE_INFO_TITLE_SITE_DATA"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TITLE_SITE_PERMISSIONS" "IDS_PAGE_INFO_TITLE_SITE_PERMISSIONS"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_AUTOPLAY" "IDS_PAGE_INFO_TYPE_AUTOPLAY"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_BACKGROUND_SYNC" "IDS_PAGE_INFO_TYPE_BACKGROUND_SYNC"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_CAMERA" "IDS_PAGE_INFO_TYPE_CAMERA"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_FLASH" "IDS_PAGE_INFO_TYPE_FLASH"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_IMAGES" "IDS_PAGE_INFO_TYPE_IMAGES"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_JAVASCRIPT" "IDS_PAGE_INFO_TYPE_JAVASCRIPT"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_LOCATION" "IDS_PAGE_INFO_TYPE_LOCATION"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_MIC" "IDS_PAGE_INFO_TYPE_MIC"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_MIDI_SYSEX" "IDS_PAGE_INFO_TYPE_MIDI_SYSEX"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_NOTIFICATIONS" "IDS_PAGE_INFO_TYPE_NOTIFICATIONS"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_TYPE_POPUPS" "IDS_PAGE_INFO_TYPE_POPUPS"
    addTokenReplacement "IDS_WEBSITE_SETTINGS_USB_DEVICE_LABEL" "IDS_PAGE_INFO_USB_DEVICE_LABEL"
  
  # Android page_info
    addTokenReplacement "java_website_settings" "java_page_info"
    addTokenReplacement "java_website_settings_pop" "java_page_info_pop"

  # WebsiteSettingsPopupView
    addTokenReplacement "POPUP_WEBSITE_SETTINGS" "POPUP_PAGE_INFO"

  # Content Settings
    # addTokenReplacement "PREF_WEBSITE_SETTINGS_FILTER" "PREF_PAGE_INFO_FILTER"

  # Handled below ("website_settings[_]")
    # addTokenReplacement "website_settings" "page_info"
    # addTokenReplacement "website_settings_" "page_info_"

  # Page Info
    addTokenReplacement "page_info_action_javagen" "page_info_action_javagen"

  # Content Settings
    # addTokenReplacement "website_settings_filter" "page_info_filter"
    # addTokenReplacement "website_settings_info" "page_info_info"
    # addTokenReplacement "website_settings_info_" "page_info_info_"

  # Constant corresponding to PageInfoInfobarDelegate
    addTokenReplacement "WEBSITE_SETTINGS_INFOBAR_DELEGATE" "PAGE_INFO_INFOBAR_DELEGATE"

  # File paths
    # addTokenReplacement "website_settings_infobar_delegate" "page_info_infobar_delegate"
    # addTokenReplacement "website_settings_popup_view" "page_info_popup_view"
    # addTokenReplacement "website_settings_popup_view_unittest" "page_info_popup_view_unittest"

  # Content Settings (inc. some file paths)
    # addTokenReplacement "website_settings_registry" "page_info_registry"
    # addTokenReplacement "website_settings_registry_" "page_info_registry_"
    # addTokenReplacement "website_settings_registry_unittest" "page_info_registry_unittest"

  # File paths
    # addTokenReplacement "website_settings_ui" "page_info_ui"
    # addTokenReplacement "website_settings_unittest" "page_info_unittest"

  # JNI
    addTokenReplacement "website_settings_action_javagen" "page_info_action_javagen"

  sed_and_reset "website_settings" .

  ################################

  # Comments

  addTokenReplacement "Website Settings UI" "Page Info UI"
  addTokenReplacement "website settings UI" "page info UI"

  addTokenReplacement "Website Settings Popup" "Page Info Popup"
  addTokenReplacement "website settings popup" "page info popup"

  addTokenReplacement "website settings bubble" "page info bubble"

  addTokenReplacement "Website settings dialog" "Page info dialog"
  addTokenReplacement "Website Settings dialog" "Page Info dialog"

  # tools/metrics/actions/actions.xml
  addTokenReplacement "Website Settings opened" "Page Info opened"

  # chrome/browser/ui/page_info/website_settings_infobar_delegate.h
  addTokenReplacement "website settings infobar" "page info infobar"

  # website_settings_popup_view.cc
  addTokenReplacement "too large for the website settings" "too large for the page info"
  addTokenReplacement "Website Settings are not" "The regular PageInfoPopupView is not"

  # chrome/browser/ui/cocoa/page_info/website_settings_bubble_controller.m
  addTokenReplacement "more than one website settings" "more than one page info"

  # chrome/browser/ui/browser_window.h
  addTokenReplacement "Shows the website settings using" "Shows Page Info using"

  sed_and_reset "website settings" .

  ################

  addTokenReplacement "Provides a bridge between the WebSettingsUI" "Provides a bridge between the PageInfoUI"

  sed_and_reset "WebSettingsUI" .

  ################################

  # WebsiteSettings[Action]

  # Occurrences of WebsiteSettings[Action] that should be replaced are all in
  # ./chrome UMA-related references that we want to stay backwards-compatible
  # are excluded using the TEMP_STRING approach above, or by virtue of being in
  # ./tools/metrics instead.

  addTokenReplacement "WebsiteSettings" "PageInfo"
  addTokenReplacement "WebsiteSettingsAction" "PageInfoAction"
  sed_and_reset "WebsiteSettings" chrome

  ################################

  # website_settings[_]

  # All occurrences of website_settings[_] tokens that we care to replace are in
  # ./chrome

  addTokenReplacement "website_settings" "page_info"
  addTokenReplacement "website_settings_" "page_info_"
  sed_and_reset "website_settings" chrome

  ################################

  echo "Restoring strings"

  set CPP_SED_REPLACEMENTS $CPP_SED_REPLACEMENTS "s#TEMP_STRING_JSDLKFJDSF#WebsiteSettings#g"
  sed_and_reset "TEMP_STRING_JSDLKFJDSF" .

  ################################
  
  echo "git cl format"
  git cl format

end

function step_3_remove_comments
  # Delete two lines: http://unix.stackexchange.com/questions/56123/remove-line-containing-certain-string-and-the-following-line
  sed --in-place="" \
    '/and all its resources/,+1 d' \
    "chrome/android/java/src/org/chromium/chrome/browser/page_info/PageInfoPopup.java"
  # Delete before and after: http://stackoverflow.com/questions/9442681/delete-n1-previous-lines-and-n2-lines-following-with-respect-to-a-line-containin
  vim -c 'g/Normalize all/-1,+1d' -c 'x' \
    "chrome/browser/ui/cocoa/page_info/page_info_bubble_controller.h"
end

step_1_rename_files
step_2_rename_contents
step_3_remove_comments

