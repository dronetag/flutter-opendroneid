import 'package:flutter_opendroneid/pigeon.dart';

// extensions to check whether messages have the same data
// The messages may not necessarily be the same, timestamp, rssi are ignored
// compares just relevant data fields
extension LocationCompareExtension on LocationMessage {
  // consider location  with same timestamp equal
  bool containsEqualData(LocationMessage other) {
    return time == other.time &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }
}

extension BasicIdCompareExtension on BasicIdMessage {
  bool containsEqualData(BasicIdMessage other) {
    return uasId == other.uasId &&
        idType == other.idType &&
        uaType == other.uaType;
  }
}

extension OperatorIdCompareExtension on OperatorIdMessage {
  bool containsEqualData(OperatorIdMessage other) {
    return operatorId == other.operatorId;
  }
}

extension SystemDataCompareExtension on SystemDataMessage {
  bool containsEqualData(SystemDataMessage other) {
    return areaCeiling == other.areaCeiling &&
        areaCount == other.areaCount &&
        areaFloor == other.areaFloor &&
        areaRadius == other.areaRadius &&
        category == other.category &&
        classValue == other.classValue &&
        classificationType == other.classificationType &&
        operatorAltitudeGeo == other.operatorAltitudeGeo &&
        operatorLatitude == other.operatorLatitude &&
        operatorLocationType == other.operatorLocationType &&
        operatorLongitude == other.operatorLongitude;
  }
}

extension AuthenticationCompareExtension on AuthenticationMessage {
  bool containsEqualData(AuthenticationMessage other) {
    return authData == other.authData &&
        authDataPage == other.authDataPage &&
        authLastPageIndex == other.authLastPageIndex &&
        authLength == other.authLength &&
        authTimestamp == other.authTimestamp &&
        authType == other.authType;
  }
}

extension SelfIdCompareExtension on SelfIdMessage {
  bool containsEqualData(SelfIdMessage other) {
    return descriptionType == other.descriptionType &&
        operationDescription == other.operationDescription;
  }
}
