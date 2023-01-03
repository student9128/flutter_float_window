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
    lateinit var channel: MethodChannel
    private lateinit var activity: Activity
    private lateinit var context: Context
    var firstUrl = ""
    private var useController = false
    private var isPlayWhenScreenOff = true//锁屏情况下是否播放
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
            "getScreenOffTimeout" -> {
                var time = Settings.System.getInt(
                    context.contentResolver,
                    Settings.System.SCREEN_OFF_TIMEOUT
                )
                result.success(time)
            }
            "setScreenOffTimeout" -> {
                var args = call.arguments
                args?.let {
                    setScreenTimeout(it.toString().toInt())
                }
            }
            "setScreenOnForever" -> {
                setScreenTimeout(Int.MAX_VALUE)
            }
            "canWriteSettings" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    result.success(Settings.System.canWrite(context))
                } else {
                    result.success(true)
                }
            }
            "isPlayWhenScreenOff" -> {
                Log.d(javaClass.name, "isPlayWhenScreenOff====${call.arguments}")
//                var temp = call.argument<Boolean>("isPlayWhenScreenOff")
                var temp = call.arguments
                temp?.let {
                    isPlayWhenScreenOff = it.toString() == "true"
                }
//                temp?.let { isPlayWhenScreenOff = it }
            }
            "setVideoUrl" -> {
                var videoUrl = call.argument<Any>("videoUrl")
                videoUrl?.let { setVideoUrl(it.toString(), context) }
            }
            "setWidthAndHeight" -> {
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")
                if (width != null && height != null) {
                    mBinder?.setFloatVideoWidthAndHeight(width, height)
                }
            }
            "setAspectRatio" -> {
                val ar = call.arguments
                ar?.let {
                    mBinder?.setFloatVideoAspectRatio(it.toString().toFloat())
                }
            }
            "setGravity" -> {
                var gravity = call.arguments
                gravity?.let {
                    setGravity(it.toString())
                }
            }
            "setBackgroundColor" -> {
                var color = call.arguments
                color?.let {
                    mBinder?.setBackgroundColor(it.toString())
                }
            }
            "canShowFloatWindow" -> {
                result.success(canDrawOverlays())
            }
            "openSetting" -> {
                openOverlaySetting()
            }
            "launchApp" -> {
                var packageName = context.packageName
                val packageManager = context.packageManager
                val launchIntentForPackage = packageManager.getLaunchIntentForPackage(packageName)
                context.startActivity(launchIntentForPackage)
                mBinder?.pausePlay()
                mBinder?.removeFloatWindow()
            }
            "initFloatWindow" -> {
                var videoUrl = call.argument<Any>("videoUrl")
                var uc = call.argument<Boolean>("useController")
                uc?.let { useController = it }
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
            "hideFloatWindow" -> {
                result.success(hideFloatWindow())
            }
            "play" -> {
                play()
            }
            "pause" -> {
                pause()
            }
            "stop" -> {
                stop()
            }
            "seekTo" -> {
                var args = call.arguments
                Log.d(javaClass.name, "position======$args")
                var position = call.argument<Int>("position")
                Log.d(javaClass.name, "position=$position")
                mBinder?.seekTo(position.toString().toLong())
            }
            "initFloatLive" -> {
                var args = call.arguments
                var appId = call.argument<String>("appId")
                Log.d(FloatWindowLiveService.TAG, "===========initFloatLive")
                bindFloatWindowLiveService()
                appId?.let {
                    initFloatLiveWindow(activity,it)
                }
            }
            "joinChannel" -> {
                var args = call.arguments
                var token = call.argument<String>("token")
                var channelName = call.argument<String>("channelName")
                var optionalUid = call.argument<Int>("optionalUid")
                if (token == null || channelName == null || optionalUid == null) return
                mBinderLive?.joinChannel(context, token, channelName, optionalUid)
            }
            "leaveChannel" -> {
                mBinderLive?.removeFloatWindow()
                result.success("")
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private var bindServiceLive: FloatWindowLiveService? = null
    private var mBinderLive: FloatWindowLiveService.LocalBinder? = null
    var serviceConnectionLive: ServiceConnection? = null
    var isBindLive = false

    private fun initServiceLive(activity: Activity) {
        serviceConnectionLive = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
                bindServiceLive = (service as FloatWindowLiveService.LocalBinder).service
                mBinderLive = service
//                mBinderLive?.initFloatLive(activity.baseContext, "d4d4713353494ff5b93fca5ec5169f9b")
                Log.d(FloatWindowLiveService.TAG, "===========onServiceConnected")
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                bindServiceLive = null
                mBinderLive = null
            }

        }
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

    private fun setGravity(gravity: String) {
        when (gravity) {
            "top" -> mBinder?.setVideoGravity(FloatWindowGravity.TOP)
            "left" -> mBinder?.setVideoGravity(FloatWindowGravity.LEFT)
            "right" -> mBinder?.setVideoGravity(FloatWindowGravity.RIGHT)
            "bottom" -> mBinder?.setVideoGravity(FloatWindowGravity.BOTTOM)
            "center" -> mBinder?.setVideoGravity(FloatWindowGravity.CENTER)
            "tl" -> mBinder?.setVideoGravity(FloatWindowGravity.TL)
            "tr" -> mBinder?.setVideoGravity(FloatWindowGravity.TR)
            "bl" -> mBinder?.setVideoGravity(FloatWindowGravity.BL)
            "br" -> mBinder?.setVideoGravity(FloatWindowGravity.BR)
        }
    }

    private fun setVideoUrl(url: String, context: Context) {
        mBinder?.initMediaSource(url, context)
    }

    private fun play() {
        ScreenLockListener.getInstance(activity)
            .beginListen(object : ScreenLockListener.ScreenStateListener {
                override fun onScreenOn() {
                    Log.e("FloatWindowService", "initFloatWindow====onScreenOn")
                }

                override fun onScreenOff() {
                    Log.e("FloatWindowService", "initFloatWindow====onScreenOff")
                    if (!isPlayWhenScreenOff) {
                        mBinder?.pausePlay()
                    }
                }

                override fun onScreenPresent() {
                    if (!isPlayWhenScreenOff) {
                        mBinder?.let {
                            if (!it.hasClickClose()) {
                                it?.startPlay()
                            }
                        }
                    }
                    Log.e("FloatWindowService", "initFloatWindow====onScreenPresent")
                }

            })
        mBinder?.startPlay()
    }

    private fun pause() {
        mBinder?.pausePlay()
    }

    private fun stop() {
        mBinder?.stopPlay()
    }

    private fun hideFloatWindow(): Long {
        ScreenLockListener.getInstance(context).unregister()
        return mBinder?.removeFloatWindow()!!
    }

    private fun bindFloatWindowLiveService() {
        Log.d(FloatWindowLiveService.TAG, "===========bindFloatWindowLiveService")
        if (isBindLive) {
            isBindLive = false
            context.unbindService(serviceConnectionLive!!)
            bindServiceLive = null
            mBinderLive = null
        }
        var intent = Intent(context, FloatWindowLiveService::class.java)
        context.bindService(intent, serviceConnectionLive!!, Context.BIND_AUTO_CREATE)
        isBindLive = true
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

    private fun initFloatLiveWindow(activity: Activity,appId:String){
        mBinderLive?.initFloatLive(activity, appId)
        mBinderLive?.service?.setOnClickListener(object :FloatWindowLiveService.OnClickListener{
            override fun onFullScreenClick() {
                mBinderLive?.removeFloatWindow()
                channel.invokeMethod("onLiveFullScreenClick", null)
            }

            override fun onCloseClick() {
                mBinderLive?.removeFloatWindow()
                channel.invokeMethod("onLiveCloseClick", null)
            }

        })
    }
    private fun initFloatWindow(activity: Activity) {
        Log.e("FloatWindowService", "initFloatWindow")
        mBinder?.initFloatWindow(activity, isUserController = useController)
        Log.e("FloatWindowService", "initFloatWindow====$firstUrl")
        setVideoUrl(firstUrl, activity)//初始化的时候不播放，只缓冲
        mBinder?.service?.setOnClickListener(object : FloatWindowService.OnClickListener {
            override fun onFullScreenClick() {
                Log.e(javaClass.name, "onFullScreenClick")
                //在这里判断窗口是在app内还是外
                channel.invokeMethod("onFullScreenClick", null)

            }

            override fun onCloseClick() {
                channel.invokeMethod("onCloseClick", null)
            }

            override fun onPlayClick(isPlay: Boolean) {
                channel.invokeMethod("onPlayClick", isPlay)
            }

        })
        ScreenLockListener.getInstance(activity)
            .beginListen(object : ScreenLockListener.ScreenStateListener {
                override fun onScreenOn() {
                    Log.e("FloatWindowService", "initFloatWindow====onScreenOn")
                }

                override fun onScreenOff() {
                    Log.e("FloatWindowService", "initFloatWindow====onScreenOff")
                    if (!isPlayWhenScreenOff) {
                        mBinder?.pausePlay()
                    }
                }

                override fun onScreenPresent() {
                    if (!isPlayWhenScreenOff) {
                        mBinder?.let {
                            if (!it.hasClickClose()) {
                                it?.startPlay()
                            }
                        }
                    }
                    Log.e("FloatWindowService", "initFloatWindow====onScreenPresent")
                }

            })
    }

    /**
     * 修改手机锁屏时间
     * @param timeMilliseconds 毫秒为单位
     *
     * 永久亮屏 使用 Int.MAX_VALUE
     */
    private fun setScreenTimeout(timeMilliseconds: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.System.canWrite(context)) {
                var intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                intent.data = Uri.parse("package:" + context.packageName)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
            } else {
                Settings.System.putInt(
                    context.contentResolver,
                    Settings.System.SCREEN_OFF_TIMEOUT,
                    timeMilliseconds
                )
            }
        } else {
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_OFF_TIMEOUT,
                timeMilliseconds
            )
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(javaClass.name, "onAttachedToActivity")
        activity = binding.activity
        initService(binding.activity)
        initServiceLive(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
    }
}
