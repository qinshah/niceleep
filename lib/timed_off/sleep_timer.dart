import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niceleep/app/state_mgmt/sound_manager.dart';

class SleepTimer {
  SleepTimer._();

  static final i = SleepTimer._();

  Timer _timer = Timer(Duration.zero, () {});

  final _timerNotifier = ValueNotifier<Duration?>(null);

  ValueNotifier<Duration?> get timerNotifier => _timerNotifier;

  Duration? get _remainingTime => _timerNotifier.value;

  void set({required Duration duration, bool isExit = false}) {
    _timerNotifier.value = duration;
    _timer.cancel();
    _timer = Timer.periodic((const Duration(seconds: 1)), (timer) {
      _timerNotifier.value = _remainingTime! - Duration(seconds: 1);
      if (_remainingTime! <= Duration.zero) {
        timer.cancel();
        _timerNotifier.value = null;
        isExit ? exit(0) : SoundManager.i.stopAll();
      }
    });
  }

  void cancel() {
    _timer.cancel();
    _timerNotifier.value = null;
  }
}
