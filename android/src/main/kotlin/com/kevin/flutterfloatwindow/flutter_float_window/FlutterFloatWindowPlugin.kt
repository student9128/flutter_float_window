package com.kevin.flutterfloatwindow.flutter_float_window

import android.app.Activity
import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterFloatWindowPlugin */
class FlutterFloatWindowPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var activity: Activity
    private lateinit var context: Context
    var firstUrl = ""
    var isFirstShowFloatWindow = true//多次重复show或者hide悬浮窗的话，service连接上的时候播放视频
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_float_window")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        Log.d(javaClass.name, "onAttachedToEngine")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
//        if (call.method == "getPlatformVersion") {
//            result.success("Android ${android.os.Build.VERSION.RELEASE}")
//        } else {
//            result.notImplemented()
//        }
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "setMainActivityName" -> {}
            "setVideoUrl" -> {
                var videoUrl = call.argument<Any>("videoUrl")
                videoUrl?.let { setVideoUrl(it.toString(), context) }
            }
            "canShowFloatWindow" -> {
                result.success(canDrawOverlays())
            }
            "openSetting" -> {
                openOverlaySetting()
            }
            "initFloatWindow" -> {
                var videoUrl = call.argument<Any>("videoUrl")
                videoUrl?.let { firstUrl = it.toString() }
                bindFloatWindowService()
            }
            "showFloatWindow" -> {
                play()
            }
            "showFloatWindowWithInit" -> {
                if (SettingsUtils.canDrawOverlays(context, true, true)) {
                    var videoUrl = call.argument<Any>("videoUrl")
                    videoUrl?.let { firstUrl = it.toString() }
                    bindFloatWindowService()
                    play()
                } else {
                    Toast.makeText(
                        context,
                        "your have no permission about showing float window",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
//            "hideFloatWindow" -> unbindFloatWindowService()
            "hideFloatWindow" -> hideFloatWindow()
            "play" -> {
                play()
            }
            "pause" -> {
                pause()
            }
            "stop" -> {
                stop()
            }
            "seekTo"->{
                var position = call.argument<Int>("position")
                Log.d(javaClass.name,"position=$position")
                mBinder?.seekTo(position.toString().toLong())
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private var bindService: FloatWindowService? = null
    private var mBinder: FloatWindowService.LocalBinder? = null
    var serviceConnection: ServiceConnection? = null
    var isBind = false
    private fun initService(activity: Activity) {
        serviceConnection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, service: IBinder) {
                Log.e("FloatWindowService", "onServiceConnected,,,$name")
                bindService = (service as FloatWindowService.LocalBinder).service
                mBinder = service
                initFloatWindow(activity)
            }

            override fun onServiceDisconnected(name: ComponentName) {
                Log.e(javaClass.name, "onServiceDisconnected")
                bindService = null
                mBinder = null
            }
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(context)) {
                return false
            }
            true
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            checkOp(context, 24)
        } else {
            true
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private fun checkOp(context: Context, op: Int): Boolean {
        val manager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        try {
            val method = AppOpsManager::class.java.getDeclaredMethod(
                "checkOp",
                Int::class.javaPrimitiveType,
                Int::class.javaPrimitiveType,
                String::class.java
            )
            return AppOpsManager.MODE_ALLOWED == method.invoke(
                manager,
                op,
                Binder.getCallingUid(),
                context.packageName
            ) as Int
        } catch (e: Exception) {
        }
        return false
    }

    private fun openOverlaySetting() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                intent.data = Uri.parse("package:" + context.packageName)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            } catch (e: java.lang.Exception) {
                e.printStackTrace()
                SettingsUtils.startFloatWindowPermissionErrorToast(context)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            if (!SettingsUtils.manageDrawOverlaysForRom(context)) {
                SettingsUtils.startFloatWindowPermissionErrorToast(context)
            }
        }
    }

    private fun setVideoUrl(url: String, context: Context) {
        mBinder?.initMediaSource(url, context)
    }

    private fun play() {
        mBinder?.startPlay()
    }

    private fun pause() {
        mBinder?.pausePlay()
    }

    private fun stop() {
        mBinder?.stopPlay()
    }

    private fun hideFloatWindow() {
        mBinder?.removeFloatWindow()
    }

    private fun bindFloatWindowService() {
        Log.e(javaClass.name, "bindFloatWindowService")
        if (isBind) {
            isBind = false
            context.unbindService(serviceConnection!!)
            bindService = null
            mBinder = null
        }
        var intent = Intent(context, FloatWindowService::class.java)
        context.bindService(intent, serviceConnection!!, Context.BIND_AUTO_CREATE)
        isBind = true
    }

    private fun unbindFloatWindowService() {
        Log.e(javaClass.name, "unbindFloatWindowService")
        if (isBind) {
            isBind = false
            context.unbindService(serviceConnection!!)
            bindService = null
            mBinder = null
        }
    }

    private fun initFloatWindow(activity: Activity) {
        Log.e("FloatWindowService", "initFloatWindow")
        mBinder?.initFloatWindow(activity)
        Log.e("FloatWindowService", "initFloatWindow====$firstUrl")
        setVideoUrl(firstUrl, activity)//初始化的时候不播放，只缓冲
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(javaClass.name, "onAttachedToActivity")
        activity = binding.activity
        initService(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
    }
}
