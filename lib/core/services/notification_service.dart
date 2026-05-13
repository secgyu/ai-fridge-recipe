import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';

/// 로컬 알림 시스템의 단일 진입점.
///
/// 책임:
/// - 앱 시작 시 [initialize]로 timezone DB와 native 플랫폼 핸들러 설정
/// - 재료의 D-3 / D-1 / D-Day 만료 알림 스케줄링 ([scheduleForIngredient])
/// - 재료 삭제·수정·만료 시 기존 알림 취소 ([cancelForIngredient])
/// - 사용자가 설정에서 OFF 시 [cancelAll]로 전체 정리
///
/// 알림 ID 규칙: `hash(ingredient.id + step)`로 결정적 → 같은 재료의
/// 같은 step에 대해 멱등 스케줄링 가능.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 알림 시간(매일 오전 9시). 디바이스 로컬 시각 기준.
  static const int _notifyHour = 9;
  static const int _notifyMinute = 0;

  static const String _channelId = 'expiry_channel';
  static const String _channelName = '유통기한 알림';
  static const String _channelDesc = '재료의 유통기한이 임박했을 때 알려줘요';

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // 디바이스 로컬 타임존을 신뢰. Flutter 18+ 환경에선 별도 lookup 가능하지만
    // 일반적으로 `tz.local` fallback이 정상 동작한다.

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 알림 권한 요청 (Android 13+ POST_NOTIFICATIONS, iOS APNS).
  ///
  /// 사용자가 거부해도 앱은 동작하며, 거부 시 false 반환.
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final bool androidOk =
        await android?.requestNotificationsPermission() ?? true;
    final bool iosOk = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidOk && iosOk;
  }

  /// 재료 하나에 대해 D-3 / D-1 / D-Day 3개 알림을 등록.
  ///
  /// - 이미 지난 시각은 자동으로 skip.
  /// - 같은 재료에 대해 다시 호출되면 [cancelForIngredient] 후 재등록.
  Future<void> scheduleForIngredient(Ingredient ingredient) async {
    if (!_initialized) await initialize();
    await cancelForIngredient(ingredient.id);
    final DateTime? expiry = ingredient.expiryDate;
    if (expiry == null) return;

    for (final _ExpiryStep step in _ExpiryStep.values) {
      final DateTime targetDate =
          expiry.subtract(Duration(days: step.daysBefore));
      final DateTime fire = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        _notifyHour,
        _notifyMinute,
      );
      if (fire.isBefore(DateTime.now())) continue;

      try {
        await _plugin.zonedSchedule(
          _idFor(ingredient.id, step),
          step.title,
          step.body(ingredient.name),
          tz.TZDateTime.from(fire, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        // 권한 거부, exact alarm 미허용 등은 조용히 무시. 디버그 로깅만.
        debugPrint('[Notification] schedule failed: $e');
      }
    }
  }

  /// 한 재료에 등록된 모든 step 알림을 취소.
  Future<void> cancelForIngredient(String ingredientId) async {
    for (final _ExpiryStep step in _ExpiryStep.values) {
      await _plugin.cancel(_idFor(ingredientId, step));
    }
  }

  /// 사용자가 설정에서 알림 OFF 했을 때 호출. 등록된 모든 알림 제거.
  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  /// 여러 재료를 일괄 재등록. 설정 ON 또는 알림 권한 회복 시 호출.
  Future<void> rescheduleAll(List<Ingredient> ingredients) async {
    await cancelAll();
    for (final Ingredient i in ingredients) {
      await scheduleForIngredient(i);
    }
  }

  int _idFor(String ingredientId, _ExpiryStep step) {
    // 32비트 안전 범위로 클램프. step은 하위 2비트에 결합.
    final int base = ingredientId.hashCode & 0x3FFFFFFF;
    return (base << 2) | step.index;
  }
}

enum _ExpiryStep {
  d3(3, '유통기한 3일 전'),
  d1(1, '유통기한 하루 전'),
  dDay(0, '오늘이 유통기한이에요');

  const _ExpiryStep(this.daysBefore, this.title);

  final int daysBefore;
  final String title;

  String body(String ingredientName) {
    switch (this) {
      case _ExpiryStep.d3:
        return '$ingredientName이(가) 3일 뒤에 상해요. 미리 활용해요!';
      case _ExpiryStep.d1:
        return '$ingredientName이(가) 내일까지예요. 오늘 메뉴로 추천해요!';
      case _ExpiryStep.dDay:
        return '$ingredientName 유통기한이 오늘까지예요. 서둘러 사용해요!';
    }
  }
}
