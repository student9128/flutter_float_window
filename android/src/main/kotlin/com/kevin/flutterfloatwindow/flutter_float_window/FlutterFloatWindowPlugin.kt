package com.kevin.flutterfloatwindow.flutter_float_window

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity

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
            "setMainActivityName"->{}
            "setVideoUrl"->{
                var videoUrl = call.argument<Any>("videoUrl")
                videoUrl?.let { setVideoUrl(it.toString()) }
            }
            "showFloatWindow" -> bindFloatWindowService()
            "hideFloatWindow" -> unbindFloatWindowService()
            "play"->{
                play()
            }
            "pause"->{
                pause()
            }
            "stop"->{
                stop()
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
    private fun initService() {
        serviceConnection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, service: IBinder) {
                Log.e(javaClass.name, "onServiceConnected")
                bindService = (service as FloatWindowService.LocalBinder).service
                mBinder=service
            }

            override fun onServiceDisconnected(name: ComponentName) {
                Log.e(javaClass.name, "onServiceDisconnected")
                bindService = null
                mBinder=null
            }
        }
    }

    fun setupMethodChannel() {

    }

    private fun setVideoUrl(url:String){
        mBinder?.initMediaSource(url)
    }
    private fun play(){
        mBinder?.startPlay()
    }
    private fun pause(){
        mBinder?.pausePlay()
    }
    private fun stop(){
        mBinder?.stopPlay()
    }

    private fun bindFloatWindowService() {
        Log.e(javaClass.name, "bindFloatWindowService")
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
            mBinder=null
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(javaClass.name, "onAttachedToActivity")
        activity = binding.activity
        initService()
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
    }
}
