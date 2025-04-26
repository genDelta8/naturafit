import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

String operatingSystemCached = "iOS";
bool isMobileCached = true;
bool isMobileWebCached = false;
bool isWebOrDesktopCached = false;
bool isDesktopCached = false;



Future<bool> isMobileWeb() async {
  debugPrint('Checking if mobile web');
  if (!kIsWeb) {
    isMobileWebCached = false;
    return false;
  }

  var deviceInfo = DeviceInfoPlugin();
  try {
    var webInfo = await deviceInfo.webBrowserInfo;
    
    // Check multiple indicators for mobile browsers
    isMobileWebCached = 
      // Check if platform contains 'mobile'
      (webInfo.platform?.toLowerCase().contains('mobile') ?? false) ||
      // Check if userAgent contains mobile indicators
      (webInfo.userAgent?.toLowerCase().contains('mobile') ?? false) ||
      (webInfo.userAgent?.toLowerCase().contains('android') ?? false) ||
      (webInfo.userAgent?.toLowerCase().contains('iphone') ?? false) ||
      // Check viewport width (typical mobile breakpoint)
      (webInfo.browserName.toString().toLowerCase() == 'chrome mobile');
      
    debugPrint('Mobile web detection result: $isMobileWebCached');
    return isMobileWebCached;
  } catch (e) {
    debugPrint('Error detecting mobile web: $e');
    isMobileWebCached = false;
    return false;
  }
}

Future<bool> isMobile() async {
  debugPrint('Checking if mobile');
  //if (isMobileCached != null) return isMobileCached;
  
  var deviceInfo = DeviceInfoPlugin();

    try {
    await deviceInfo.androidInfo; // If this works, it's an Android device
    isMobileCached = true;
    debugPrint('YES Mobile');
    return true;
  } catch (_) {}

  try {
    await deviceInfo.iosInfo; // If this works, it's an iOS device
    isMobileCached = true;
    debugPrint('YES Mobile');
    return true;
  } catch (_) {}

  debugPrint('NOT mobile');
  isMobileCached = false;
  return isMobileCached;
}

Future<bool> isDesktop() async {
  debugPrint('Checking if desktop');
  //if (isDesktopCached != null) return isDesktopCached;
  var deviceInfo = DeviceInfoPlugin();
  try {
    await deviceInfo.macOsInfo; // If this works, it's an Android device
    isDesktopCached = true;
    return true;
  } catch (_) {}

  try {
    await deviceInfo.windowsInfo; // If this works, it's an iOS device
    isDesktopCached = true;
    return true;
  } catch (_) {}

  try {
    await deviceInfo.linuxInfo; // If this works, it's an iOS device
    isDesktopCached = true;
    return true;
  } catch (_) {}


  isDesktopCached = false;
  return isDesktopCached;
}

Future<bool> isWebOrDesktop() async {
  debugPrint('Checking if web or desktop');
  if (kIsWeb) {
    // For web, return true only if it's NOT mobile web
    isWebOrDesktopCached = !(await isMobileWeb());
  } else {
    // For native platforms, return true only if it's desktop (Windows, macOS, Linux)
    isWebOrDesktopCached = await isDesktop();
  }
  debugPrint('isWebOrDesktopCached: $isWebOrDesktopCached');
  return isWebOrDesktopCached;
}

Future<String> getOperatingSystem() async {
  debugPrint('Checking operating system');
  //if (operatingSystemCached != null) return operatingSystemCached;
  
  if (kIsWeb) {
    operatingSystemCached = "Web";
    return "Web";
  } else {
    if (Platform.isMacOS) {
      operatingSystemCached = "macOS";
    } else if (Platform.isWindows) {
      operatingSystemCached = "Windows";
    } else if (Platform.isLinux) {
      operatingSystemCached = "Linux";
    } else if (Platform.isAndroid) {
      operatingSystemCached = "Android";
    } else if (Platform.isIOS) {
      operatingSystemCached = "iOS";
    } else {
      operatingSystemCached = "Unknown";
    }
    return operatingSystemCached;
  }
}
