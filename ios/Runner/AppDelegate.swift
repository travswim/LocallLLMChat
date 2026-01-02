import UIKit
import Flutter
import os

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let batteryChannel = FlutterMethodChannel(name: "com.example.app/memory",
                                              binaryMessenger: controller.binaryMessenger)
    
    batteryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getAvailableMemory" {
           if #available(iOS 13.0, *) {
               // os_proc_available_memory() returns bytes available to YOUR process
               result(Int64(os_proc_available_memory()))
           } else {
               // Fallback for older iOS (unlikely for GenAI apps)
               result(FlutterError(code: "UNAVAILABLE", 
                                 message: "iOS 13+ required for memory API", 
                                 details: nil))
           }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
