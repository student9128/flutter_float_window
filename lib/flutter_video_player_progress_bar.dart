import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_float_window/flutter_float_window.dart';
import 'package:flutter_float_window/flutter_video_player_engine.dart';
import 'package:flutter_float_window/flutter_video_player_event_handler.dart';

class FlutterVideoPlayerProgressBar extends StatefulWidget {
  FlutterVideoPlayerProgressBar(
      {Key? key,
      required this.barHeight,
      required this.handleHeight,
      required this.drawShadow,
      required this.position,
      required this.duration,
      required this.bufferedStart,
      required this.bufferedEnd,
      FlutterVideoPlayerProgressBarColors? colors,
      this.onDragEnd,
      this.onDragStart,
      this.onDragUpdate,
      this.onSeek,
      // required this.barWidth,
      this.drawHandle = true,
      this.drawBuffer = true})
      : colors = colors ?? FlutterVideoPlayerProgressBarColors(),
        super(key: key);

  final FlutterVideoPlayerProgressBarColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final Function(double position)? onSeek;

  // final double barWidth;
  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final bool drawHandle;
  final bool drawBuffer;

  final double position;
  final double duration;
  final double bufferedStart;
  final double bufferedEnd;

  @override
  _FlutterVideoPlayerProgressBarState createState() {
    return _FlutterVideoPlayerProgressBarState();
  }
}

class _FlutterVideoPlayerProgressBarState
    extends State<FlutterVideoPlayerProgressBar> {
  void listener() {
    if (!mounted) return;
    setState(() {});
  }

  bool isPlaying = true;

  @override
  void initState() {
    super.initState();
    // var handler = FlutterVideoPlayerEventHandler(onVideoProgress:
    //     (double position, double duration, double bufferedStart,
    //         double bufferedEnd) {
    //   if (mounted) {
    //     setState(() {
    //       this.position = position;
    //       this.duration = duration;
    //       this.bufferedStart = bufferedStart;
    //       this.bufferedEnd = bufferedEnd;
    //     });
    //   }
    // });
    // engine.setVideoPlayerEventHandler(handler);
    // FlutterFloatWindow.initVideoPlayerListener(engine.mHandler!);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void savePlayingStatus() async {
    var bool = await FlutterFloatWindow.isPlaying();
    setState(() {
      isPlaying = bool;
    });
    if (bool) {
      FlutterFloatWindow.pauseVideoIOS();
    }
  }

  void restorePlayingStatus() {
    if (isPlaying) {
      FlutterFloatWindow.playVideoIOS();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    // var position = duration * relative;
    widget.onSeek?.call(relative);
    // setState(() {
    //   this.position = position;
    //   this.bufferedStart = 0;
    //   this.bufferedEnd = 0;
    // });
    // FlutterFloatWindow.seekVideoIOS({'position': position.toInt()});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        print("onHorizontalDragStart");
        savePlayingStatus();
        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        print("onHorizontalDragUpdate");
        // if (duration == 0) {
        //   return;
        // }
        _seekToRelativePosition(details.globalPosition);

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        print("onHorizontalDragEnd");
        restorePlayingStatus();
        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        // if (duration == 0) {
        //   return;
        // }
        _seekToRelativePosition(details.globalPosition);
      },
      child: Center(
        child: Container(
          height: max(widget.handleHeight, widget.barHeight),
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
                position: widget.position,
                duration: widget.duration,
                bufferedStart: widget.bufferedStart,
                bufferedEnd: widget.bufferedEnd,
                colors: widget.colors,
                barHeight: widget.barHeight,
                handleHeight: widget.handleHeight,
                drawShadow: widget.drawShadow,
                drawHandle: widget.drawHandle,
                drawBuffer: widget.drawBuffer),
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(
      {required this.position,
      required this.duration,
      required this.bufferedStart,
      required this.bufferedEnd,
      required this.colors,
      required this.barHeight,
      required this.handleHeight,
      required this.drawShadow,
      required this.drawHandle,
      required this.drawBuffer});

  FlutterVideoPlayerProgressBarColors colors;
  final double position;
  final double duration;
  final double bufferedStart;
  final double bufferedEnd;
  final double barHeight;
  final double handleHeight;
  final bool drawShadow;
  final bool drawHandle;
  final bool drawBuffer;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (duration == 0) {
      return;
    }
    final double playedPartPercent = position / duration;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    final double start = bufferedStart / duration * size.width;
    final double end = bufferedEnd / duration * size.width;
    if (drawBuffer) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, baseOffset),
            Offset(end, baseOffset + barHeight),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    if (drawShadow) {
      final shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight,
          ),
        );

      canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    }

    if (drawHandle) {
      double offsetX = playedPart;
      if(playedPart+handleHeight/2>=size.width){
        offsetX = size.width-handleHeight/2;
      }else if(playedPart-handleHeight/2<=0){
        offsetX = handleHeight/2;
      }
      canvas.drawCircle(
        Offset(offsetX, baseOffset + barHeight / 2),
        handleHeight/2,
        colors.handlePaint,
      );
      canvas.drawLine(Offset(playedPart, 0),Offset(playedPart, handleHeight),colors.playedPaint);
    }
  }
}
