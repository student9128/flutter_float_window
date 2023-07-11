package com.kevin.flutterfloatwindow.flutter_float_window

import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.util.Log
import android.view.*
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.constraintlayout.widget.ConstraintLayout
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.hls.HlsDataSourceFactory
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource

class FloatWindowService : Service() {
    private lateinit var wmParams: WindowManager.LayoutParams
    private lateinit var mWindowManager: WindowManager
    private lateinit var mWindowView: View
    private lateinit var mContainer: FrameLayout
    private lateinit var mCloseImage: ImageView
    private var hasAdded = false
    private var hasRelease = false
    private var currentUrl = ""
    private var isBig = false//默认是小屏
    private var isButtonShown = true
    private var mWidth = 500
    private var mHeight = 280
    private var mLastWidth = mWidth
    private var mLastHeight = mHeight
    private var mAspectRatio: Float = (9 / 16).toFloat()
    private var useAspectRatio = false
    private var mFloatGravity: FloatWindowGravity = FloatWindowGravity.BR
    private lateinit var mContext: Context
    private var mScreenWidth: Int = 0
    private var mScreenHeight: Int = 0
    private var mFastForwardMillisecond = 15000//快进或者快退

    //使用exoPlayer自带的播放器样式
    private var useController = false

    val touchResponseDistance = 10

    //声明IBinder接口的一个接口变量mBinder
    val mBinder: IBinder = LocalBinder()
    private var mNM: NotificationManager? = null
    private val handler = Handler()
    val runnable = Runnable {
        ivFullScreen.visibility = View.GONE
        ivPlay.visibility = View.GONE
        ivForward.visibility = View.GONE
        ivBackward.visibility = View.GONE
        ivClose.visibility = View.GONE
        isButtonShown = false
    }


    //LocalBinder是继承Binder的一个内部类
    inner class LocalBinder : Binder() {
        val service: FloatWindowService
            get() = this@FloatWindowService

        fun initFloatWindow(context: Context, isUserController: Boolean = false) {
            mContext = context
            useController = isUserController
            initWindowParams()
            initView(context)
            initGestureListener()
        }

        fun initMediaSource(url: String, context: Context) {
            currentUrl = url
            val mediaSource = buildMediaSource(url, context)
            player?.setMediaSource(mediaSource!!)
            player?.prepare()
//            player?.play()
            mContainer.requestLayout()
//            Log.d(
//                javaClass.name,
//                "player width height======${spvPlayerView.width},,${spvPlayerView.height}"
//            )
        }

        fun startPlay() {//开始播放的时候展示出画面
            showFloatView()
            hasClickClose = false
//            Log.d(javaClass.name, "player is playing======${player!!.isPlaying},,${hasRelease}")
            if (!player!!.isPlaying) {
                if (hasRelease) {
                    player?.prepare()
                    player?.playWhenReady = true
                    player?.play()
//                    Log.d(javaClass.name, "player is playing======走了吗")
                } else {
                    player?.play()
                }
            }
            setWardBtnStatus()
            ivPlay.setImageResource(R.drawable.ic_pause)
        }

        fun stopPlay() {
            if (player!!.isPlaying) {
                player?.stop()
                hasRelease = true
//                player?.clearMediaItems()
            }
        }

        fun pausePlay() {
            player?.let {
                if (it.isPlaying) {
                    it.pause()
                    ivPlay.setImageResource(R.drawable.ic_play)
                }
            }
        }

        fun seekTo(position: Long) {
            player?.seekTo(position)
            setWardBtnStatus()
        }

        fun setPlaybackSpeed(speed: Double) {
            player?.setPlaybackSpeed(speed.toFloat())
        }

        fun removeFloatWindow(): Long {
            removeWindowView()
            return if (player != null) {
                player.contentPosition
            } else {
                0
            }
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

    }

    //设置前进和后退按钮的状态
    private fun setWardBtnStatus() {
        var position = player.currentPosition
        var total = player.contentDuration
        if (position < mFastForwardMillisecond) {
            ivBackward.imageAlpha = 153
            ivBackward.isClickable = false
        } else {
            ivBackward.imageAlpha = 255
            ivBackward.isClickable = true
        }
        if (total - position <= mFastForwardMillisecond) {
            ivForward.imageAlpha = 153
            ivForward.isClickable = false
        } else {
            ivForward.imageAlpha = 255
            ivForward.isClickable = true
        }
    }

    override fun onCreate() {
        mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        Log.e(javaClass.name, "onCreate")
        showNotification()
    }

    lateinit var player: ExoPlayer
    lateinit var ivClose: ImageView
    lateinit var ivPlay: ImageView
    lateinit var ivFullScreen: ImageView
    lateinit var ivForward: ImageView
    lateinit var ivBackward: ImageView
    lateinit var spvPlayerView: StyledPlayerView
    lateinit var clContainer: ConstraintLayout
    var hasClickClose = false
    var isVideoEnd = false
    private fun initView(context: Context) {
        mContainer = FrameLayout(context)
        mContainer.setBackgroundColor(Color.parseColor("#00000000"))
        var flp = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        )
        mContainer.layoutParams = flp

        player = ExoPlayer.Builder(context).build()

        val view = LayoutInflater.from(context).inflate(R.layout.layout_float_window, null)
        clContainer = view.findViewById(R.id.cl_parent)
        ivClose = view.findViewById(R.id.iv_close)
        ivPlay = view.findViewById(R.id.iv_play)
        ivFullScreen = view.findViewById(R.id.iv_full_screen)
        spvPlayerView = view.findViewById(R.id.player_view)
        ivForward = view.findViewById(R.id.iv_forward)
        ivBackward = view.findViewById(R.id.iv_backward)
        val layoutParams = spvPlayerView.layoutParams
        mWidth = layoutParams.width
        mHeight = layoutParams.height
        spvPlayerView.useController = useController
        spvPlayerView.player = player
        if (useController) {
            ivPlay.visibility = View.GONE
            ivFullScreen.visibility = View.GONE
            ivForward.visibility = View.GONE
            ivBackward.visibility = View.GONE
            isButtonShown = false
        }
        var audioAttributes: AudioAttributes = AudioAttributes.Builder().setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
            .build()
        player.setAudioAttributes(audioAttributes, true)
        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_IDLE -> {
                        Log.d(javaClass.name, "stateIdle")
                    }
                    Player.STATE_ENDED -> {
                        Log.d(javaClass.name, "stateEnd")
                        ivPlay.setImageResource(R.drawable.ic_play)
                        isVideoEnd = true
                    }
                    Player.STATE_READY -> {
                        Log.d(javaClass.name, "stateReady")
                        isVideoEnd = false
                    }
                    Player.STATE_BUFFERING -> {
                        Log.d(javaClass.name, "stateBuffering")

                    }
                }
                super.onPlaybackStateChanged(playbackState)
            }

            override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
                Log.d(javaClass.name, "playWhenReady====$reason")
                when (reason) {
                    Player.PLAY_WHEN_READY_CHANGE_REASON_AUDIO_FOCUS_LOSS -> {
                        ivPlay.setImageResource(R.drawable.ic_play)
                        isVideoEnd = false
                    }
                    Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST -> {

                    }
                }
                super.onPlayWhenReadyChanged(playWhenReady, reason)
            }
        })

        ivPlay.setOnClickListener {
            if (isVideoEnd) {
                isVideoEnd = false
                player.seekTo(0)
                player.play()
                ivPlay.setImageResource(R.drawable.ic_pause)
            } else {
                if (player.isPlaying) {
                    player.pause()
                    ivPlay.setImageResource(R.drawable.ic_play)
                    listener?.onPlayClick(false)
                    handler.removeCallbacks(runnable)
                } else {
                    player.play()
                    ivPlay.setImageResource(R.drawable.ic_pause)
                    listener?.onPlayClick(true)
                    handler.postDelayed(runnable, 3000)
                }
            }
        }
        ivClose.setOnClickListener {
            hasClickClose = true
            listener?.onCloseClick()
            removeWindowView()
        }
        ivFullScreen.setOnClickListener {
            listener?.onFullScreenClick()
//            openApp(context)
        }
        ivForward.setOnClickListener {
            var position = player.currentPosition
            var total = player.contentDuration
            Log.d(javaClass.name, "position=$position,total=$total")
            var next = position + mFastForwardMillisecond
            if (next < total) {
                player.seekTo(next)
                if (total - next < mFastForwardMillisecond) {
                    ivForward.imageAlpha = 153
                    ivForward.isClickable = false
                }
            } else {
                player.seekTo(total)
                ivForward.imageAlpha = 153
                ivForward.isClickable = false
            }
            if (!ivBackward.isClickable) {
                ivBackward.imageAlpha = 255
                ivBackward.isClickable = true
            }
        }
        ivBackward.setOnClickListener {
            var position = player.currentPosition
            var next = position - mFastForwardMillisecond
            if (next > 0) {
                player.seekTo(next)
                ivForward.imageAlpha = 255
                ivForward.isClickable = true
            } else {
                player.seekTo(0)
                ivBackward.imageAlpha = 153
                ivBackward.isClickable = false
            }
            if (!ivForward.isClickable) {
                ivForward.imageAlpha = 255
                ivForward.isClickable = true
            }
            isVideoEnd = false
            ivPlay.setImageResource(R.drawable.ic_pause)
        }
    }

    lateinit var dataSourceFactory: DataSource.Factory
    private fun buildMediaSource(url: String, context: Context): MediaSource? {
        val uri = Uri.parse(url)
        dataSourceFactory = if (isHTTP(uri)) {
            val httpDataSourceFactory = DefaultHttpDataSource.Factory()
                .setUserAgent("ExoPlayer")
                .setAllowCrossProtocolRedirects(true)
            httpDataSourceFactory
        } else {
            DefaultDataSource.Factory(context)
        }

        return if (url.lowercase().endsWith(".m3u8")) HlsMediaSource.Factory(dataSourceFactory)
            .createMediaSource(MediaItem.fromUri(uri)) else ProgressiveMediaSource.Factory(
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
        player?.stop()
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
        val layoutParams = spvPlayerView.layoutParams
        var vWidth = layoutParams.width
        var vHeight = layoutParams.height
        vHeight = (vWidth * float).toInt()
        layoutParams.height = vHeight
        spvPlayerView.layoutParams = layoutParams
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
        val layoutParams = spvPlayerView.layoutParams
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
            spvPlayerView.layoutParams = layoutParams
            mWidth = sWidth
            mHeight = (sWidth * mAspectRatio).toInt()
        } else {
            layoutParams.width = sWidth
            layoutParams.height = sHeight
            spvPlayerView.layoutParams = layoutParams
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
        val layoutParams = spvPlayerView.layoutParams
        val lWidth = layoutParams.width
        val lHeight = layoutParams.height
        storeParams(layoutParams)
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
        if (!hasAdded) {
            try {
                if (mContainer.childCount > 0) {
                    mContainer.removeAllViews()
                }
                Log.d(
                    javaClass.name,
                    "player width height=23=====${spvPlayerView.width},,${spvPlayerView.height}"
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
                if (!useController) {
                    handler.postDelayed(runnable, 3000)
                }
            } catch (e: Exception) {
                hasAdded = false
            }
            Log.e(
                javaClass.name,
                "initFloatWindow12-------${spvPlayerView.width},,${spvPlayerView.height}"
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
            if (player!!.isPlaying) {
                player?.stop()
                hasRelease = true
            }
//            player?.stop()
            //移除悬浮窗口
            mWindowManager.removeView(mContainer)
            hasAdded = false
        }
    }

    var lastX: Int = 0
    var lastY: Int = 0

    @SuppressLint("ClickableViewAccessibility")
    private fun initGestureListener() {
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
                    Log.i(
                        javaClass.name,
                        "!!!!!!!!===distanceX=$distanceX,distanceY = $distanceY,lastX=$lastX," +
                                "lastY=$lastY,wX=${wmParams.x},wY=${wmParams.y},$mWidth,$mHeight,sW=$mScreenWidth"
                    )
                    Log.d(javaClass.name, "e1=====${e1.action},e2===${e2.action}")
                    return true
                }

                override fun onLongPress(e: MotionEvent) {
                    Log.d(javaClass.name, "e1=====onLongPress")
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
                    ivPlay.visibility = View.VISIBLE
                    ivFullScreen.visibility = View.VISIBLE
                    ivForward.visibility = View.VISIBLE
                    ivBackward.visibility = View.VISIBLE
                    ivClose.visibility = View.VISIBLE
                    isButtonShown = true
                    var position = player.currentPosition
                    var total = player.contentDuration
                    if (position < mFastForwardMillisecond) {
                        ivBackward.imageAlpha = 153
                        ivBackward.isClickable = false
                    } else {
                        ivBackward.imageAlpha = 255
                        ivBackward.isClickable = true
                    }
                    if (total - position < mFastForwardMillisecond) {
                        ivForward.imageAlpha = 153
                        ivForward.isClickable = false
                    } else {
                        ivForward.imageAlpha = 255
                        ivForward.isClickable = true
                    }
                }
                if (player.isPlaying) {
                    handler.postDelayed(runnable, 3000)
                }
//                openApp(context)
//                else {
//                    player?.play()
//                }
                return true
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                val layoutParams = spvPlayerView.layoutParams
                var width = layoutParams.width
                var height = layoutParams.height
                val i = mScreenWidth - (dip2px(mContext, 16f) * 2)
                var tempWidth = i * 4 / 5
                var tempX = wmParams.x
                var tempY = wmParams.y
                var tempHeight = 0
                if (width < tempWidth) {//放大
                    layoutParams.width = tempWidth
                    layoutParams.height = tempWidth * mHeight / mWidth
                    spvPlayerView.layoutParams = layoutParams
                    storeParams(layoutParams)
                    setWindowLocation()
                } else {//缩小
                    tempHeight = layoutParams.height * (i / mWidth)
                    layoutParams.width = mLastWidth
                    layoutParams.height = mLastHeight
                    spvPlayerView.layoutParams = layoutParams
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
//                    spvPlayerView.layoutParams = layoutParams
//                    isBig = false
//                } else {
//                    val layoutParams = spvPlayerView.layoutParams
//                    layoutParams.width = layoutParams.width * 3 / 2
//                    layoutParams.height = layoutParams.height * 3 / 2
//                    spvPlayerView.layoutParams = layoutParams
//
//                    isBig = true
//                }
                return true
            }

            override fun onDoubleTapEvent(e: MotionEvent): Boolean = false

        })
        clContainer.setOnTouchListener { v, event ->
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
        if (player!!.isPlaying) {
            player?.pause()
        }
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
        fun onPlayClick(b: Boolean)
    }

}