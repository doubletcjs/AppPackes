package com.tairnet.chat;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import org.jetbrains.annotations.NotNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private EventChannel.EventSink eventSink;
    private Intent launchIntent;
    private MethodChannel channel;

    @Override
    public void configureFlutterEngine(@NonNull @NotNull FlutterEngine flutterEngine) {
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(0);
        }

        GeneratedPluginRegistrant.registerWith(this.getFlutterEngine());

        this.config(this.getFlutterEngine().getDartExecutor().getBinaryMessenger(), "com.tairnet.chat.android.local.notification/listen");

        launchIntent = getIntent();
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);

        this.handleUriScheme(intent, false);
    }

    // 配置
    private void config(BinaryMessenger messenger, String eventChannelName) {
        // 发送指令给Flutter
        EventChannel eventChannel = new EventChannel(messenger, eventChannelName);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object listener, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object listener) {

            }
        });

        channel = new MethodChannel(messenger, "com.tairnet.chat.android.local.notification/receiver");
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("openLaunchIntent")) {
                if (launchIntent != null) {
                    this.handleUriScheme(launchIntent, true);
                    launchIntent = null;
                }
            }
        });
    }

    private void handleUriScheme(Intent intent, boolean onCreate) {
        String payload = intent.getStringExtra("payload");
        if (payload != null) {
            if (onCreate == true) {
                this.eventSinkListener(payload);
            } else {
                this.eventSinkListener(payload);
            }
        }
    }

    private void eventSinkListener(String evt) {
        ThreadUtil.runUiThread(() -> {
            Message message = new Message();
            message.obj = evt;
            sinkHandler.sendMessage(message);
        });
    }

    // 主线程
    private static class ThreadUtil {
        static void runUiThread(Runnable runnable) {
            final Handler UIHandler = new Handler(Looper.getMainLooper());
            UIHandler.post(runnable);
        }
    }

    // 发送回调信息
    private final Handler sinkHandler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(@NonNull Message msg) {
            String s = (String) msg.obj;
            if (eventSink != null) {
                eventSink.success(s);
            }
        }
    };

}
