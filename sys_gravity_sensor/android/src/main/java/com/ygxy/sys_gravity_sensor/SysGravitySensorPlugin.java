package com.ygxy.sys_gravity_sensor;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.content.Context;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;
import android.view.OrientationEventListener;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class SysGravitySensorPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private MethodChannel channel;
    private OrientationEventListener mOrientationEventListener;
    private final static String TAG = "SysGravitySensorPlugin";
    private final static String METHOD = "com.gzygxy.method.sys_gravity_sensor";
    private final static String EVENT = "com.gzygxy.event.sys_gravity_sensor";
    private int currentOrientation = -1;
    private EventChannel.EventSink mEventSink;
    private FlutterPluginBinding mFlutterPluginBinding;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), METHOD);
        channel.setMethodCallHandler(this);
        mFlutterPluginBinding = flutterPluginBinding;
        isOpen = false;
        Log.d(TAG, "onAttachedToEngine----------------111");
    }

    private boolean isOpen;

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "setOpenGravity":
                boolean isOPenGravity = call.argument("isOPenGravity");
                result.success(isOPenGravity);
                break;
            case "enable_gravity_watch":
                Log.d(TAG, "onAttachedToEngine------1212----------1222");
                EventChannel eventChannel = new EventChannel(mFlutterPluginBinding.getBinaryMessenger(), EVENT);
                eventChannel.setStreamHandler(this);
                if(!isOpen){
                    Log.d(TAG, "onAttachedToEngine----1313------------1333");
                    initOrientationEventListener(mFlutterPluginBinding.getApplicationContext());
                    isOpen = true;
                }
                if(mOrientationEventListener!=null){
                    mOrientationEventListener.enable();
                }
                result.success(null);
                break;
            case "disable_gravity_watch":
                isOpen = false;
                if(mOrientationEventListener!=null){
                    mOrientationEventListener.disable();
                }

                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        if(mOrientationEventListener!=null){
            mOrientationEventListener.disable();
        }
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        mEventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        mEventSink = null;
    }

    private void initOrientationEventListener(final Context context) {
        mOrientationEventListener = new OrientationEventListener(context) {
            @Override
            public void onOrientationChanged(int orientation) {
                if (orientation > 355 || orientation < 5) { //0度  90 正竖屏
                    if (currentOrientation > 355 || currentOrientation < 5) {
                        return;
                    }
                    Log.d(TAG, "onOrientationChanged: ORIENTATION_PORTRAIT");
                    currentOrientation = orientation;
                    if (mEventSink != null) {
                        Map<String, String> map = new HashMap<>();
                        map.put("event", "watch");
                        map.put("orientation", "orientationPortrait");
                        mEventSink.success(map);
                    }
                } else if (orientation > 70 && orientation < 110) { //90度 右横屏
                    if (currentOrientation > 70 && currentOrientation < 110) {
                        return;
                    }
                    Log.d(TAG, "onOrientationChanged: orientationLandscapeRight");
                    currentOrientation = orientation;
                    if (mEventSink != null) {
                        Map<String, String> map = new HashMap<>();
                        map.put("event", "watch");
                        map.put("orientation", "orientationLandscapeRight");
                        mEventSink.success(map);
                    }
                } else if (orientation > 160 && orientation < 200) { //180度 倒竖屏
                    if (currentOrientation > 160 && currentOrientation < 200) {
                        return;
                    }
                    Log.d(TAG, "onOrientationChanged: orientationPortraitUpsideDown");
                    currentOrientation = orientation;
                    if (mEventSink != null) {
                        Map<String, String> map = new HashMap<>();
                        map.put("event", "watch");
                        map.put("orientation", "orientationPortraitUpsideDown");
                        mEventSink.success(map);
                    }
                } else if (orientation > 250 && orientation < 290) { //270度 左横屏
                    if (currentOrientation > 250 && currentOrientation < 290) {
                        return;
                    }
                    Log.d(TAG, "onOrientationChanged: orientationLandscapeLeft");
                    currentOrientation = orientation;
                    if (mEventSink != null) {
                        Map<String, String> map = new HashMap<>();
                        map.put("event", "watch");
                        map.put("orientation", "orientationLandscapeLeft");
                        mEventSink.success(map);
                    }
                }
            }
        };
        if (mOrientationEventListener.canDetectOrientation()) {
            mOrientationEventListener.enable();
        } else {
            mOrientationEventListener.disable();
            Log.d(TAG, "onOrientationChanged: " + "当前设备不支持手机旋转");
        }
    }
}
