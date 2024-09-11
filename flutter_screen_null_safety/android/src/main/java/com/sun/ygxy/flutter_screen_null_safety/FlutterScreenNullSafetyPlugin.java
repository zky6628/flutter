package com.sun.ygxy.flutter_screen_null_safety;

import androidx.annotation.NonNull;

import android.app.Activity;
import android.view.WindowManager;
import android.provider.Settings;
import android.content.Context;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


/** FlutterScreenNullSafetyPlugin */
public class FlutterScreenNullSafetyPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private MethodChannel channel;
  private Context mContext;
  private Activity mActivity;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    mContext = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_screen_null_safety");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch(call.method){
      case "brightness":
        result.success(getBrightness());
        break;
      case "setBrightness":
        double brightness = call.argument("brightness");
        WindowManager.LayoutParams layoutParams = mActivity.getWindow().getAttributes();
        layoutParams.screenBrightness = (float)brightness;
        mActivity.getWindow().setAttributes(layoutParams);
        result.success(null);
        break;
      case "isKeptOn":
        int flags = mActivity.getWindow().getAttributes().flags;
        result.success((flags & WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0) ;
        break;
      case "keepOn":
        Boolean on = call.argument("on");
        if (on) {
          System.out.println("Keeping screen on ");
          mActivity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
        else{
          System.out.println("Not keeping screen on");
          mActivity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
        result.success(null);
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  private float getBrightness(){
    float result = mActivity.getWindow().getAttributes().screenBrightness;
    if (result < 0) { // the application is using the system brightness
      try {
        result = Settings.System.getInt(mActivity.getContentResolver(), Settings.System.SCREEN_BRIGHTNESS) / (float)255;
      } catch (Settings.SettingNotFoundException e) {
        result = 1.0f;
        e.printStackTrace();
      }
    }
    return result;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    mActivity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }
}
