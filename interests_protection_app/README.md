# interests_protection_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

<!-- --dart-define=APP_LANGUAGE=zh 语言版本-->
<!-- --dart-define=APP_CHANNEL=0 渠道-->
<!-- --dart-define=APP_RELEASE=release 发布版-->

flutter build apk
flutter build aab
flutter build ios && open -a /Applications/Xcode.app ios/Runner.xcworkspace

<!-- --dart-define=APP_LANGUAGE=zh 语言版本-->
<!-- --dart-define=APP_CHANNEL=0 -->
<!-- --dart-define=APP_RELEASE=release -->

flutter run

<!-- 签名 java 1.8.0_202 -->

keytool -genkey -v -keystore ./app.jks -keyalg RSA -keysize 2048 -validity 10000 -alias InterestsProtection
keytool -genkey -v -keystore ./tairnetchat.jks -keyalg RSA -keysize 2048 -validity 10000 -alias com.tairnet.chat

<!--
local.properties

keyAlias=InterestsProtection
keyFile=../app.jks
keyPassword=InterestsProtection1234567890
storePassword=InterestsProtection1234567890
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=220815

keyAlias=com.tairnet.chat
keyFile=../tairnetchat.jks
keyPassword=com.tairnet.chat_1234567890
storePassword=com.tairnet.chat_1234567890

Privacy - Bluetooth Always Usage Description 麒麟守护需要您的同意，开启蓝牙权限，获取当前位置，以提供所在地突发危机事件预警、紧急救援服务及附近用户动态信息等
Privacy - Bluetooth Peripheral Usage Description 麒麟守护需要您的同意，开启蓝牙权限，获取当前位置，以提供所在地突发危机事件预警、紧急救援服务及附近用户动态信息等

<string>bluetooth-peripheral</string>
 -->

<!-- cd D:\Android\Sdk\platform-tools  -->
 <!-- .\adb.exe connect 127.0.0.1:7555 -->

 <!-- cd /Users/chenjianshao/Library/Android/sdk/platform-tools  -->
 <!-- ./adb kill-server -->
 <!-- ./adb start-server -->
 <!-- ./adb devices -->
 <!-- ./adb connect 127.0.0.1:7555 -->
