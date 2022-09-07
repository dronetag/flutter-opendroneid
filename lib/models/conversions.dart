import 'package:flutter_opendroneid/pigeon.dart';

/// Conversions extensions

const Map<HorizontalAccuracy, double?> _horizontalAccuracyConversionMap = {
  HorizontalAccuracy.Unknown: null,
  HorizontalAccuracy.kilometers_18_52: 18520,
  HorizontalAccuracy.kilometers_7_408: 7408,
  HorizontalAccuracy.kilometers_3_704: 3704,
  HorizontalAccuracy.kilometers_1_852: 1852,
  HorizontalAccuracy.meters_926: 926,
  HorizontalAccuracy.meters_555_6: 555.6,
  HorizontalAccuracy.meters_185_2: 185.2,
  HorizontalAccuracy.meters_92_6: 92.6,
  HorizontalAccuracy.meters_30: 30,
  HorizontalAccuracy.meters_10: 10,
  HorizontalAccuracy.meters_3: 3,
  HorizontalAccuracy.meters_1: 1,
};

const Map<VerticalAccuracy, double?> _verticalAccuracyConversionMap = {
  VerticalAccuracy.Unknown: null,
  VerticalAccuracy.meters_150: 150,
  VerticalAccuracy.meters_45: 45,
  VerticalAccuracy.meters_25: 25,
  VerticalAccuracy.meters_10: 10,
  VerticalAccuracy.meters_3: 3,
  VerticalAccuracy.meters_1: 1,
};

const Map<SpeedAccuracy, double?> _speedAccuracyConversionMap = {
  SpeedAccuracy.Unknown: null,
  SpeedAccuracy.meter_per_second_10: 10,
  SpeedAccuracy.meter_per_second_3: 3,
  SpeedAccuracy.meter_per_second_1: 1,
  SpeedAccuracy.meter_per_second_0_3: 0.3,
};

extension HorizontalAccuracyConversion on HorizontalAccuracy {
  double? toMeters() => _horizontalAccuracyConversionMap[this];
}

extension VerticalAccuracyConversion on VerticalAccuracy {
  double? toMeters() => _verticalAccuracyConversionMap[this];
}

extension SpeedAccuracyConversion on SpeedAccuracy {
  double? toMetersPerSecond() => _speedAccuracyConversionMap[this];
}
