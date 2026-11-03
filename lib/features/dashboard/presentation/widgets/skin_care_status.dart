import 'package:flutter/material.dart';

/// 게이지 상태 enum
enum SkinCareStatus {
  veryBad,
  bad,
  normal,
  good,
  excellent;

  String get label {
    switch (this) {
      case SkinCareStatus.veryBad:
        return 'VERY BAD';
      case SkinCareStatus.bad:
        return 'BAD';
      case SkinCareStatus.normal:
        return 'NORMAL';
      case SkinCareStatus.good:
        return 'GOOD';
      case SkinCareStatus.excellent:
        return 'EXCELLENT';
    }
  }

  Color get color {
    switch (this) {
      case SkinCareStatus.veryBad:
        return Colors.red;
      case SkinCareStatus.bad:
        return Colors.orange;
      case SkinCareStatus.normal:
        return Colors.amber;
      case SkinCareStatus.good:
        return Colors.lightGreen;
      case SkinCareStatus.excellent:
        return Colors.green;
    }
  }

  String get emoji {
    switch (this) {
      case SkinCareStatus.veryBad:
        return '😢';
      case SkinCareStatus.bad:
        return '😐';
      case SkinCareStatus.normal:
        return '😑';
      case SkinCareStatus.good:
        return '🙂';
      case SkinCareStatus.excellent:
        return '😊';
    }
  }
}
