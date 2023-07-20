package com.kevin.flutterfloatwindow.flutter_float_window

import android.Manifest
import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.Activity
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.Uri
import android.os.*
import android.util.Log
import android.view.*
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import io.agora.rtc2.Constants
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.video.VideoCanvas


class FloatWindowLiveService : Service() {
    private lateinit var wmParams: WindowManager.LayoutParams
    private lateinit var mWindowManager: WindowManager
    private lateinit var mWindowView: View
    private lateinit var mContainer: FrameLayout
    private lateinit var mCloseImage: ImageView
    private var hasAdded = false
    private var hasInitialized = false //直播引擎是否初始化
    private var currentUrl = ""
    private var isBig = false//默认是小屏
    private var isButtonShown = true
    private var mWidth = 500
    private var mHeight = 280
    private var mLastWidth = mWidth
    private var mLastHeight = mHeight
    private var mAspectRatio: Float = (9 / 16).toFloat()
    private var useAspectRatio = false
    private var mFloatGravity: FloatWindowGravity = FloatWindowGravity.BOTTOM
    private lateinit var mContext: Context
    private var mScreenWidth: Int = 0
    private var mScreenHeight: Int = 0
    private lateinit var mRtcEngine: RtcEngine

    val touchResponseDistance = 10

    //声明IBinder接口的一个接口变量mBinder
    val mBinder: IBinder = LocalBinder()
    private var mNM: NotificationManager? = null
    private val handler = Handler()
    val runnable = Runnable {
        ivFullScreen.visibility = View.GONE
        ivClose.visibility = View.GONE
        isButtonShown = false
    }

    companion object {
        const val TAG = "FloatWindowLiveService"
    }


    //LocalBinder是继承Binder的一个内部类
    inner class LocalBinder : Binder() {
        val service: FloatWindowLiveService
            get() = this@FloatWindowLiveService

        fun initFloatWindow(context: Activity, isUserController: Boolean = false) {
            mContext = context
            initWindowParams()
            initView(context)
            initGestureListener(context)
        }

        fun removeFloatWindow() {
            removeWindowView()
        }

        fun hasClickClose(): Boolean = hasClickClose

        fun setFloatVideoAspectRatio(aspectRatio: Float) {
            setVideoAspectRatio(aspectRatio)
        }

        fun setFloatVideoWidthAndHeight(width: Int, height: Int) {
            setVideoWidthAndHeight(width, height)
        }

        fun setVideoGravity(gravity: FloatWindowGravity) {
            setGravity(gravity)
        }

        fun setBackgroundColor(color: String) {
            mContainer.setBackgroundColor(Color.parseColor(color))
        }

        fun initFloatLive(context: Activity, appId: String,token: String, channelName: String, optionalUid: Int) {
            initFloatWindow(context)
            initLiveEngine(context, appId,token, channelName, optionalUid)
        }

        fun joinChannel(context: Context, token: String, channelName: String, optionalUid: Int) {
            Log.d(TAG, "===========joinChannel==$hasInitialized")
            if (hasInitialized) {

                mRtcEngine.joinChannel(
                    token, channelName,
                    "",
                    optionalUid
                )
                showFloatView()
            } else {
                Log.d(TAG, "===========Please initialized first")
            }
        }
    }

    private val mRtcEventHandler: IRtcEngineEventHandler = object : IRtcEngineEventHandler() {
        // 监听频道内的远端主播，获取主播的 uid 信息。
        override fun onUserJoined(uid: Int, elapsed: Int) {
            Log.d(TAG, "onUserJoined=$uid")
            Handler(Looper.getMainLooper()).post {
                val surfaceView = RtcEngine.CreateRendererView(mContext.applicationContext)
                rlStatus.visibility=View.GONE
                tvStatus.visibility=View.VISIBLE
                flContainer.addView(surfaceView)
                mRtcEngine.setupRemoteVideo(
                    VideoCanvas(surfaceView, VideoCanvas.RENDER_MODE_FIT, uid)
                )
            }
        }

        override fun onUserOffline(uid: Int, reason: Int) {
            super.onUserOffline(uid, reason)
            Log.d(TAG, "onUserOffline=$uid,reason=$reason")
            Handler(Looper.getMainLooper()).post{
                rlStatus.visibility=View.VISIBLE
                tvStatus.visibility=View.GONE
            }
        }

        override fun onUserEnableVideo(uid: Int, enabled: Boolean) {
            super.onUserEnableVideo(uid, enabled)
            Log.d(TAG, "onUserEnableVideo=$uid,enabled=$enabled")
        }

        override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
            super.onJoinChannelSuccess(channel, uid, elapsed)
            Log.d(TAG, "onJoinChannelSuccess=$uid")
        }

        override fun onError(err: Int) {
            super.onError(err)
            Log.d(TAG, "onError=$err")
        }

        override fun onRemoteVideoStateChanged(uid: Int, state: Int, reason: Int, elapsed: Int) {
            super.onRemoteVideoStateChanged(uid, state, reason, elapsed)
            Log.d(TAG, "onRemoteVideoStateChanged=uid=$uid,state=$state,reason=$reason")
        }

        override fun onLeaveChannel(stats: RtcStats?) {
            super.onLeaveChannel(stats)
            Log.d(TAG, "onLeaveChannel=${stats?.totalDuration}")
        }

        override fun onFirstRemoteVideoFrame(uid: Int, width: Int, height: Int, elapsed: Int) {
            super.onFirstRemoteVideoFrame(uid, width, height, elapsed)
            Log.d(TAG, "onFirstRemoteVideoFrame====$uid")
        }
    }

    override fun onCreate() {
        mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        Log.e(javaClass.name, "onCreate")
        showNotification()
    }

    lateinit var flContainer: FrameLayout
    lateinit var ivClose: ImageView
    lateinit var ivFullScreen: ImageView
    private lateinit var rlStatus: RelativeLayout
    private lateinit var tvStatus: TextView
    //    lateinit var flContainer: StyledPlayerView
    lateinit var clContainer: ConstraintLayout
    var hasClickClose = false
    private fun initView(context: Context) {
        mContainer = FrameLayout(context)
        mContainer.setBackgroundColor(Color.parseColor("#00000000"))
        var flp = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        )
        mContainer.layoutParams = flp

        val view = LayoutInflater.from(context).inflate(R.layout.layout_floaw_window_live, null)
        clContainer = view.findViewById(R.id.cl_parent)
        ivClose = view.findViewById(R.id.iv_close)
        ivFullScreen = view.findViewById(R.id.iv_full_screen)
        flContainer = view.findViewById(R.id.fl_container)
        rlStatus = view.findViewById(R.id.rl_status)
        tvStatus = view.findViewById(R.id.tv_status)
        val layoutParams = flContainer.layoutParams
        mWidth = layoutParams.width
        mHeight = layoutParams.height

        ivClose.setOnClickListener {
            hasClickClose = true
            listener?.onCloseClick()
            removeWindowView()
        }
        ivFullScreen.setOnClickListener {
            listener?.onFullScreenClick()
//            openApp(context)
        }
    }

    private fun checkPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            var permissions = arrayOf(Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA)
            for (permission in permissions) {
                if (ContextCompat.checkSelfPermission(
                        activity,
                        permission
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    ActivityCompat.requestPermissions(activity, permissions, 200)
                }
            }
        }
    }

    private fun initLiveEngine(context: Context, appId: String,token: String, channelName: String, optionalUid: Int) {
        Log.d(TAG, "===========initLiveEngine")
//        mRtcEngine = RtcEngine.create(context, "d4d4713353494ff5b93fca5ec5169f9b", mRtcEventHandler)
        mRtcEngine = RtcEngine.create(context, appId, mRtcEventHandler)
        hasInitialized = true
        // 直播场景下，设置频道场景为 BROADCASTING。
        mRtcEngine.setChannelProfile(Constants.CHANNEL_PROFILE_LIVE_BROADCASTING)
        // 根据场景设置用户角色为 BORADCASTER 或 AUDIENCE。
        mRtcEngine.setClientRole(Constants.CLIENT_ROLE_AUDIENCE)

        // 视频默认禁用，你需要调用 enableVideo 开始视频流。
        mRtcEngine.enableVideo()
        mRtcEngine.joinChannel(
            token, channelName,
            "",
            optionalUid
        )
        showFloatView()
    }

    lateinit var dataSourceFactory: DataSource.Factory
    private fun buildMediaSource(uri: Uri, context: Context): MediaSource? {

        dataSourceFactory = if (isHTTP(uri)) {
            val httpDataSourceFactory = DefaultHttpDataSource.Factory()
                .setUserAgent("ExoPlayer")
                .setAllowCrossProtocolRedirects(true)
            httpDataSourceFactory
        } else {
            DefaultDataSource.Factory(context)
        }
        return ProgressiveMediaSource.Factory(
            dataSourceFactory
        ).createMediaSource(MediaItem.fromUri(uri))
    }

    private fun isHTTP(uri: Uri?): Boolean {
        if (uri == null || uri.scheme == null) {
            return false
        }
        val scheme = uri.scheme
        return scheme == "http" || scheme == "https"
    }

    override fun onDestroy() {
        Log.e(javaClass.name, "onDestroy")
        mNM!!.cancel(101)
    }

    override fun onBind(intent: Intent): IBinder? {
        Log.e(javaClass.name, "onBind")
        return mBinder
    }

    override fun onUnbind(intent: Intent): Boolean {
        Log.e(javaClass.name, "onUnbind")
//        player?.stop()
        removeWindowView()
        return super.onUnbind(intent)
    }

    private fun showNotification() {
//        CharSequence text = ;
//        val contentIntent = PendingIntent.getActivity(
//            this, 0,
//            Intent(this, ServiceActivity::class.java), 0
//        )
//        val notification = Notification.Builder(this)
//            .setSmallIcon(R.mipmap.ic_launcher)
//            .setTicker("Service Start")
//            .setWhen(System.currentTimeMillis())
//            .setContentTitle("current service")
//            .setContentText("Service Start")
//            .setContentIntent(contentIntent)
//            .build()
//        mNM!!.notify(101, notification)
        Log.e(javaClass.name, "通知栏已出")
    }

    private fun initWindowParams() {
        mWindowManager = application.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        mScreenWidth = mWindowManager.defaultDisplay.width
        mScreenHeight = mWindowManager.defaultDisplay.height
        wmParams = WindowManager.LayoutParams()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            setWMTypeCompat()
        } else if (RomUtil.isMiui) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                setWMTypeCompat()
            } else {
                wmParams.type = WindowManager.LayoutParams.TYPE_PHONE
            }
        } else {
            wmParams.type = WindowManager.LayoutParams.TYPE_TOAST
        }
        wmParams.format = PixelFormat.RGBA_8888
        wmParams.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        wmParams.gravity = Gravity.START or Gravity.TOP
        wmParams.width = WindowManager.LayoutParams.WRAP_CONTENT
        wmParams.height = WindowManager.LayoutParams.WRAP_CONTENT
    }


    private fun setWMTypeCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            wmParams.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            wmParams.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            wmParams.type = WindowManager.LayoutParams.TYPE_PHONE
        }
//        wmParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
    }

    /**
     * 高宽比
     * 0.0~1.0
     */
    fun setVideoAspectRatio(float: Float) {
        val layoutParams = flContainer.layoutParams
        var vWidth = layoutParams.width
        var vHeight = layoutParams.height
        vHeight = (vWidth * float).toInt()
        layoutParams.height = vHeight
        flContainer.layoutParams = layoutParams
        mAspectRatio = if (mAspectRatio > 1.0) {
            1.0f
        } else {
            float
        }
    }

    /**
     * 设置视频悬浮窗的宽高
     */
    fun setVideoWidthAndHeight(width: Int, height: Int) {
        var sWidth = mWindowManager.defaultDisplay.width
        var sHeight = mWindowManager.defaultDisplay.height
        val layoutParams = flContainer.layoutParams
        if (width <= sWidth) {
            sWidth = if (width < 500) {
                500
            } else {

                width
            }
            sHeight = if (height < 280) {
                280
            } else {
                height
            }
        }
        if (useAspectRatio) {//用高宽比
            layoutParams.height = (sWidth * mAspectRatio).toInt()
            flContainer.layoutParams = layoutParams
            mWidth = sWidth
            mHeight = (sWidth * mAspectRatio).toInt()
        } else {
            layoutParams.width = sWidth
            layoutParams.height = sHeight
            flContainer.layoutParams = layoutParams
            mWidth = sWidth
            mHeight = sHeight
        }
        mLastWidth = mWidth
        mLastWidth = mHeight
    }

    fun setFloatWindowGravity(gravity: FloatWindowGravity) {
        mFloatGravity = gravity
    }

    fun setGravity(gravity: FloatWindowGravity) {
        val layoutParams = flContainer.layoutParams
        val lWidth = layoutParams.width
        val lHeight = layoutParams.height
        val sWidth = mWindowManager.defaultDisplay.width
        val sHeight = mWindowManager.defaultDisplay.height
        when (gravity) {
            FloatWindowGravity.LEFT -> {
                if (lWidth < sWidth - dip2px(mContext, 32f)) {
                    wmParams.x = dip2px(mContext, 16f)
                    wmParams.y = (sHeight - lHeight) / 2
                } else {//居中
                    wmParams.x = (sWidth - lWidth) / 2
                    wmParams.y = (sHeight - lHeight) / 2
                }
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
            FloatWindowGravity.TOP -> {
                wmParams.x = (sWidth - lWidth) / 2
                wmParams.y = dip2px(mContext, 60f)
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
            FloatWindowGravity.RIGHT -> {
                if (lWidth < sWidth - dip2px(mContext, 32f)) {
                    wmParams.x = sWidth - lWidth - dip2px(mContext, 16f)
                    wmParams.y = (sHeight - lHeight) / 2
                } else {//居中
                    wmParams.x = (sWidth - lWidth) / 2
                    wmParams.y = (sHeight - lHeight) / 2
                }
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
            FloatWindowGravity.BOTTOM -> {
                wmParams.x = (sWidth - lWidth) / 2
                wmParams.y = sHeight - lHeight - dip2px(mContext, 50f)
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
            FloatWindowGravity.CENTER -> {
                wmParams.x = (sWidth - lWidth) / 2
                wmParams.y = (sHeight - lHeight) / 2
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
            FloatWindowGravity.TL -> {
                if (lWidth < sWidth - dip2px(mContext, 32f)) {
                    wmParams.x = dip2px(mContext, 16f)
                    wmParams.y = dip2px(mContext, 60f)
                } else {//居中
                    wmParams.x = (sWidth - lWidth) / 2
                    wmParams.y = dip2px(mContext, 60f)
                }
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
            FloatWindowGravity.TR -> {
                if (lWidth < sWidth - dip2px(mContext, 32f)) {
                    wmParams.x = sWidth - lWidth - dip2px(mContext, 16f)
                    wmParams.y = dip2px(mContext, 60f)
                } else {//居中
                    wmParams.x = (sWidth - lWidth) / 2
                    wmParams.y = dip2px(mContext, 60f)
                }
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
            FloatWindowGravity.BL -> {
                if (lWidth < sWidth - dip2px(mContext, 32f)) {
                    wmParams.x = dip2px(mContext, 16f)
                    wmParams.y = sHeight - lHeight - dip2px(mContext, 50f)
                } else {//居中
                    wmParams.x = (sWidth - lWidth) / 2
                    wmParams.y = sHeight - lHeight - dip2px(mContext, 50f)
                }
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }

            FloatWindowGravity.BR -> {
                if (lWidth < sWidth - dip2px(mContext, 32f)) {
                    wmParams.x = sWidth - lWidth - dip2px(mContext, 16f)
                    wmParams.y = sHeight - lHeight - dip2px(mContext, 50f)
                } else {//居中
                    wmParams.x = (sWidth - lWidth) / 2
                    wmParams.y = sHeight - lHeight - dip2px(mContext, 50f)
                }
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
        }
    }

    fun showFloatView() {
        hasClickClose = false
        if (!hasAdded) {
            try {
                if (mContainer.childCount > 0) {
                    mContainer.removeAllViews()
                }
                Log.d(
                    javaClass.name,
                    "player width height=23=====${flContainer.width},,${flContainer.height}"
                )
                mContainer.addView(clContainer)
                mWindowManager.addView(mContainer, wmParams)
                val width = mWindowManager.defaultDisplay.width
                val height = mWindowManager.defaultDisplay.height
                setGravity(mFloatGravity)//设置窗口位置
//                wmParams.x = width - 600
//                wmParams.y = 200
//                mWindowManager.updateViewLayout(mContainer, wmParams)
                hasAdded = true
//                if (!useController) {
                handler.postDelayed(runnable, 3000)
//                }
            } catch (e: Exception) {
                hasAdded = false
            }
            Log.e(
                javaClass.name,
                "initFloatWindow12-------${flContainer.width},,${flContainer.height}"
            )
        }
    }

    private fun addViewToWindow(view: View) {
        if (!hasAdded) {
            try {
                if (mContainer.childCount > 0) {
                    mContainer.removeAllViews()
                }
                mContainer.addView(view)
                mContainer.addView(mCloseImage)
                mWindowManager.addView(mContainer, wmParams)
                val width = mWindowManager.defaultDisplay.width
                val height = mWindowManager.defaultDisplay.height
                wmParams.x = width
                wmParams.y = height / 2
                hasAdded = true
                mWindowManager.updateViewLayout(mContainer, wmParams)
            } catch (e: Exception) {
                hasAdded = false
            }
        }

    }

    /**
     * 移除控件
     */
    private fun removeWindowView() {
        if (hasAdded) {
            mRtcEngine.leaveChannel()
            RtcEngine.destroy()
            //移除悬浮窗口
            mWindowManager.removeView(mContainer)
            hasAdded = false
        }
    }

    var lastX: Int = 0
    var lastY: Int = 0

    @SuppressLint("ClickableViewAccessibility")
    private fun initGestureListener(context: Context) {
        var gestureDetector =
            GestureDetector(applicationContext, object : GestureDetector.OnGestureListener {
                override fun onDown(e: MotionEvent): Boolean {
                    lastX = e.rawX.toInt()
                    lastY = e.rawY.toInt()
                    return false
                }

                override fun onShowPress(e: MotionEvent) {
                }

                override fun onSingleTapUp(e: MotionEvent): Boolean = false

                override fun onScroll(
                    e1: MotionEvent,
                    e2: MotionEvent,
                    distanceX: Float,
                    distanceY: Float
                ): Boolean {
                    var distanceX = e2.rawX - lastX
                    var distanceY = e2.rawY - lastY
                    lastX = e2.rawX.toInt()
                    lastY = e2.rawY.toInt()
                    wmParams.x = wmParams.x + distanceX.toInt()
                    wmParams.y = wmParams.y + distanceY.toInt()
                    mWindowManager.updateViewLayout(mContainer, wmParams)
                    return true
                }

                override fun onLongPress(e: MotionEvent) {
                }

                override fun onFling(
                    e1: MotionEvent,
                    e2: MotionEvent,
                    velocityX: Float,
                    velocityY: Float
                ): Boolean = false

            })
        gestureDetector.setOnDoubleTapListener(object : GestureDetector.OnDoubleTapListener {
            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                if (!isButtonShown) {
                    handler.removeCallbacks(runnable)
                    ivFullScreen.visibility = View.VISIBLE
                    ivClose.visibility=View.VISIBLE
                    isButtonShown = true
                    handler.postDelayed(runnable, 3000)
                }
//                openApp(context)
//                else {
//                    player?.play()
//                }
                return true
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                val layoutParams = flContainer.layoutParams
                var width = layoutParams.width
                var height = layoutParams.height
                val i = mScreenWidth - dip2px(mContext, 16f)
                var tempWidth = i * 4 / 5
                var tempX = wmParams.x
                var tempY = wmParams.y
                var tempHeight = 0
                Log.i(
                    javaClass.name,
                    "!!!!!!!!===width=$width,i=$i,tempWidth=$tempWidth,,tempY=${tempY},tempHeight=$tempHeight,$mWidth,$mHeight"
                )
                if (width < tempWidth) {//放大
                    Log.i(javaClass.name, "走了吗${i / (mWidth * 1.0f)}")
                    layoutParams.width = tempWidth
                    layoutParams.height = tempWidth * mHeight / mWidth
                    flContainer.layoutParams = layoutParams
                    storeParams(layoutParams)
                    setWindowLocation()
                } else {//缩小
                    tempHeight = layoutParams.height * (i / mWidth)
                    layoutParams.width = mLastWidth
                    layoutParams.height = mLastHeight
                    flContainer.layoutParams = layoutParams
                    wmParams.x = tempX
                    wmParams.y = tempY
                    Log.i(
                        javaClass.name,
                        "!!!!!!!!===123width=$width,i=$i,tempWidth=$tempWidth,,tempY=${tempY},tempHeight=$tempHeight"
                    )
                    storeParams(layoutParams)
//                    mWindowManager.updateViewLayout(mContainer, wmParams)
                    setWindowLocation()
                }
//                if (isBig) {
//                    layoutParams.width = layoutParams.width * 2 / 3
//                    layoutParams.height = layoutParams.height * 2 / 3
//                    flContainer.layoutParams = layoutParams
//                    isBig = false
//                } else {
//                    val layoutParams = flContainer.layoutParams
//                    layoutParams.width = layoutParams.width * 3 / 2
//                    layoutParams.height = layoutParams.height * 3 / 2
//                    flContainer.layoutParams = layoutParams
//
//                    isBig = true
//                }
                return true
            }

            override fun onDoubleTapEvent(e: MotionEvent): Boolean = false

        })
        clContainer?.setOnTouchListener { v, event ->
            gestureDetector.onTouchEvent(event)
            if (event.action == MotionEvent.ACTION_UP) {
                setWindowLocation()
            }
            true
        }
    }
    private fun storeParams(layoutParams: ViewGroup.LayoutParams) {
        mLastWidth = mWidth
        mLastHeight = mHeight
        mWidth = layoutParams.width
        mHeight = layoutParams.height
    }
    private fun setWindowLocation() {
        var centerX = wmParams.x + clContainer.width / 2
        var valueAnimatorX = ValueAnimator()
        if (centerX > mScreenWidth / 2) {
            valueAnimatorX.setObjectValues(
                wmParams.x,
                mScreenWidth - dip2px(mContext, 16f) - mWidth
            )
        } else {
            valueAnimatorX.setObjectValues(wmParams.x, dip2px(mContext, 16f))
        }
        valueAnimatorX.addUpdateListener { animation -> //                        Log.d(javaClass.name,"e1=====onAnimationUpdate===>${animation?.getAnimatedValue()}")
            animation?.let {
                var v: Int = animation.animatedValue as Int
                wmParams.x = v
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
        }
        var valueAnimatorY = ValueAnimator()
        val belowLimit = mScreenHeight - dip2px(mContext, 50f) - mHeight
        val topLimit = dip2px(mContext, 50f)
        if (wmParams.y > belowLimit) {
            valueAnimatorY.setObjectValues(wmParams.y, belowLimit)
        } else if (wmParams.y < topLimit) {
            valueAnimatorY.setObjectValues(wmParams.y, topLimit)
        }
        valueAnimatorY.addUpdateListener { animation ->
            animation?.let {
                var v: Int = animation.animatedValue as Int
                wmParams.y = v
                mWindowManager.updateViewLayout(mContainer, wmParams)
            }
        }
        if (valueAnimatorY.values != null && valueAnimatorY.values.isNotEmpty()) {
            var animSet = AnimatorSet()
            animSet.playTogether(valueAnimatorX, valueAnimatorY)
            animSet.duration = 300
            animSet.interpolator = DecelerateInterpolator()
            animSet.start()
        } else {
            valueAnimatorX.start()
        }
    }
    private fun openApp(context: Context) {
        var packageName = context.packageName
        val packageManager = context.packageManager
        val launchIntentForPackage = packageManager.getLaunchIntentForPackage(packageName)
        startActivity(launchIntentForPackage)
//        if (player!!.isPlaying) {
//            player?.pause()
//        }
        removeWindowView()
    }
    //getTouchSlop


    // 根据手机的分辨率从 dp 的单位 转成为 px(像素)
    fun dip2px(context: Context, dpValue: Float): Int {
        // 获取当前手机的像素密度（1个dp对应几个px）
        val scale = context.resources.displayMetrics.density
        return (dpValue * scale + 0.5f).toInt() // 四舍五入取整
    }

    // 根据手机的分辨率从 px(像素) 的单位 转成为 dp
    fun px2dip(context: Context, pxValue: Float): Int {
        // 获取当前手机的像素密度（1个dp对应几个px）
        val scale = context.resources.displayMetrics.density
        return (pxValue / scale + 0.5f).toInt() // 四舍五入取整
    }

    private var listener: OnClickListener? = null
    fun setOnClickListener(l: OnClickListener) {
        listener = l
    }

    interface OnClickListener {
        fun onFullScreenClick()
        fun onCloseClick()
//        fun onPlayClick(b: Boolean)
    }

}