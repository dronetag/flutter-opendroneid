import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter_opendroneid/extensions/list_extension.dart';

/// Conversions extensions
// TODO move to dart-opendroneid in the future(?)
const Map<HorizontalAccuracy, double?> _horizontalAccuracyConversionMap = {
  HorizontalAccuracy.unknown: null,
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
  VerticalAccuracy.unknown: null,
  VerticalAccuracy.meters_150: 150,
  VerticalAccuracy.meters_45: 45,
  VerticalAccuracy.meters_25: 25,
  VerticalAccuracy.meters_10: 10,
  VerticalAccuracy.meters_3: 3,
  VerticalAccuracy.meters_1: 1,
};

const Map<SpeedAccuracy, double?> _speedAccuracyConversionMap = {
  SpeedAccuracy.unknown: null,
  SpeedAccuracy.meterPerSecond_10: 10,
  SpeedAccuracy.meterPerSecond_3: 3,
  SpeedAccuracy.meterPerSecond_1: 1,
  SpeedAccuracy.meterPerSecond_0_3: 0.3,
};

const Map<IDType, String> _idTypeConversionMap = {
  IDType.none: 'None',
  IDType.serialNumber: 'Serial Number',
  IDType.CAARegistrationID: 'CAA Registration ID',
  IDType.UTMAssignedID: 'UTM Assigned ID',
  IDType.specificSessionID: 'Specific Session ID',
};

const Map<UAType, String> _uaTypeConversionMap = {
  UAType.none: 'None',
  UAType.aeroplane: 'Aeroplane',
  UAType.helicopterOrMultirotor: 'Helicopter Or Multirotor',
  UAType.gyroplane: 'Gyroplane',
  UAType.hybridLift: 'Hybrid Lift',
  UAType.ornithopter: 'Ornithopter',
  UAType.glider: 'Glider',
  UAType.kite: 'Kite',
  UAType.freeBalloon: 'Free Balloon',
  UAType.captiveBalloon: 'Captive Balloon',
  UAType.airship: 'Airship',
  UAType.freeFallParachute: 'Free Fall Parachute',
  UAType.rocket: 'Rocket',
  UAType.tetheredPoweredAircraft: 'Tethered Powered Aircraft',
  UAType.groundObstacle: 'Ground Obstacle',
  UAType.other: 'Other',
};

const Map<UAClassEurope, String> _uaClassEuropeConversionMap = {
  UAClassEurope.undefined: 'Undefined',
  UAClassEurope.EUClass_0: 'EU Class 0',
  UAClassEurope.EUClass_1: 'EU Class 1',
  UAClassEurope.EUClass_2: 'EU Class 2',
  UAClassEurope.EUClass_3: 'EU Class 3',
  UAClassEurope.EUClass_4: 'EU Class 4',
  UAClassEurope.EUClass_5: 'EU Class 5',
  UAClassEurope.EUClass_6: 'EU Class 6',
};

const Map<UACategoryEurope, String> _uaCategoryEuropeConversionMap = {
  UACategoryEurope.undefined: 'Undefined',
  UACategoryEurope.EUOpen: 'EU Open',
  UACategoryEurope.EUSpecific: 'EU Specific',
  UACategoryEurope.EUCertified: 'EU Certified',
};

const Map<OperatorLocationType, String> _operatorLocTypeConversionMap = {
  OperatorLocationType.fixed: 'Fixed',
  OperatorLocationType.takeOff: 'Take Off',
  OperatorLocationType.dynamic: 'Dynamic',
};

const Map<HeightType, String> _heightTypeConversionMap = {
  HeightType.aboveGroundLevel: 'Above Ground Level',
  HeightType.aboveTakeoff: 'Above Take Off',
};

const Map<OperationalStatus, String> _operationalStatusConversionMap = {
  OperationalStatus.ground: 'Grounded',
  OperationalStatus.airborne: 'Airborne',
  OperationalStatus.emergency: 'Emergency',
  OperationalStatus.none: 'Unknown',
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

extension UASIDConversion on UASID {
  String? asString() => switch (this.runtimeType) {
        IDNone() => null,
        SerialNumber(serialNumber: final sn) => sn,
        CAARegistrationID(registrationID: final regId) => regId,
        UTMAssignedID(id: final id) => id.toHexString(),
        SpecificSessionID(id: final id) => id.toHexString(),
        _ => null,
      };
}

extension IDTypeConversion on IDType {
  String? asString() => _idTypeConversionMap[this];
}

extension UATypeConversion on UAType {
  String? asString() => _uaTypeConversionMap[this];
}

extension UAClassificationConversion on UAClassification {
  bool isEuropeClassification() => this is UAClassificationEurope;
  String? uaClassEuropeString() => isEuropeClassification()
      ? (this as UAClassificationEurope).uaClassEurope.asString()
      : null;
  String? uaCategoryEuropeString() => isEuropeClassification()
      ? (this as UAClassificationEurope).uaCategoryEurope.asString()
      : null;
}

extension UACategoryEuropeConversion on UACategoryEurope {
  String? asString() => _uaCategoryEuropeConversionMap[this];
}

extension UAClassEuropeConversion on UAClassEurope {
  String? asString() => _uaClassEuropeConversionMap[this];
}

extension OperatorLocationTypeConversion on OperatorLocationType {
  String? asString() => _operatorLocTypeConversionMap[this];
}

extension HeightTypeConversion on HeightType {
  String? asString() => _heightTypeConversionMap[this];
}

extension OperationalStatusConversion on OperationalStatus {
  String? asString() => _operationalStatusConversionMap[this];
}
