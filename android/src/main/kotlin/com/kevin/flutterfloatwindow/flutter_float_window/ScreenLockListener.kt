package com.kevin.flutterfloatwindow.flutter_float_window

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.PowerManager

class ScreenLockListener constructor(context: Context) {
    private val mContext = context
    private lateinit var mReceiver: ScreenLockBroadcastReceiver

    companion object {
        private var mInstance: ScreenLockListener? = null
        fun getInstance(context: Context): ScreenLockListener {
            mInstance ?: synchronized(this) {
                mInstance ?: ScreenLockListener(context).also { mInstance = it }
            }
            return mInstance!!
        }
    }


    private var l: ScreenStateListener? = null
    fun beginListen(listener: ScreenStateListener) {
        mReceiver = ScreenLockBroadcastReceiver(listener)
        l = listener
        register()
        getScreenState()
    }

    private fun getScreenState() {
        val powerManager: PowerManager =
            mContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.KITKAT) {
            if (powerManager.isInteractive) {//亮屏
                l?.onScreenOn()
            } else {//锁屏
                l?.onScreenOff()
            }
        } else {
            if (powerManager.isScreenOn) {
                l?.onScreenOn()
            } else {
                l?.onScreenOff()
            }
        }
    }

    private fun register() {
        var filter = IntentFilter()
        filter.addAction(Intent.ACTION_SCREEN_ON)
        filter.addAction(Intent.ACTION_SCREEN_OFF)
        filter.addAction(Intent.ACTION_USER_PRESENT)
        mContext.registerReceiver(mReceiver, filter)
    }

    fun unregister() {
        mContext.unregisterReceiver(mReceiver)
    }

    interface ScreenStateListener {
        fun onScreenOn()
        fun onScreenOff()
        fun onScreenPresent()
    }
}