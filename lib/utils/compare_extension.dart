import 'package:dart_opendroneid/src/types.dart';

// extensions to check whether messages have the same data
// The messages may not necessarily be the same, timestamp, rssi are ignored
// compares just relevant data fields
extension LocationMessageCompareExtension on LocationMessage {
  // consider location  with same timestamp equal
  bool containsEqualData(LocationMessage other) {
    return timestamp == other.timestamp &&
        location?.latitude == other.location?.latitude &&
        location?.longitude == other.location?.longitude;
  }
}

extension BasicIDCompareExtension on BasicIDMessage {
  bool containsEqualData(BasicIDMessage other) {
    return uasID == other.uasID && uaType == other.uaType;
  }
}

extension OperatorIDMessageCompareExtension on OperatorIDMessage {
  bool containsEqualData(OperatorIDMessage other) {
    return operatorID == other.operatorID;
  }
}

extension SystemMessageCompareExtension on SystemMessage {
  bool containsEqualData(SystemMessage other) {
    return areaCeiling == other.areaCeiling &&
        areaCount == other.areaCount &&
        areaFloor == other.areaFloor &&
        areaRadius == other.areaRadius &&
        uaClassification == other.uaClassification &&
        timestamp == other.timestamp &&
        operatorAltitude == other.operatorAltitude &&
        operatorLocationType == other.operatorLocationType &&
        operatorLocation == other.operatorLocation;
  }
}

extension AuthenticationCompareExtension on AuthMessage {
  bool containsEqualData(AuthMessage other) {
    return rawContent == other.rawContent;
  }
}

extension SelfIDCompareExtension on SelfIDMessage {
  bool containsEqualData(SelfIDMessage other) {
    return descriptionType == other.descriptionType &&
        description == other.description;
  }
}
