package com.kevin.flutterfloatwindow.flutter_float_window

import android.content.Context
import android.content.Intent
import android.content.IntentFilter

class RemoteClickListener constructor(context: Context){
    private val mContext = context
    private var hasInitialized = false
    private lateinit var mReceiver: RemoteClickReceiver
    companion object{
        private var mInstance: RemoteClickListener? = null
        fun getInstance(context: Context): RemoteClickListener {
            mInstance ?: synchronized(this) {
                mInstance ?: RemoteClickListener(context).also { mInstance = it }
            }
            return mInstance!!
        }
    }
    private var l: RemoteViewClickListener? = null
    fun beginListen(listener: RemoteViewClickListener) {
        hasInitialized = true
        mReceiver = RemoteClickReceiver(listener)
        l = listener
        register()
    }
    private fun register() {
        var filter = IntentFilter()
        filter.addAction("com.kevin.float.FORWARD")
        filter.addAction("com.kevin.float.PLAY")
        filter.addAction("com.kevin.float.BACKWARD")
        mContext.registerReceiver(mReceiver, filter)
    }
    fun unregister() {
        if (hasInitialized) {
            mContext.unregisterReceiver(mReceiver)
            hasInitialized = false
        }
    }
    interface RemoteViewClickListener{
        fun onForwardClick()
        fun onPlayClick()
        fun onBackwardClick()
    }
}