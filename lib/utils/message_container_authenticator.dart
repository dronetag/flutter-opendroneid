import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter_opendroneid/models/constants.dart';
import 'package:flutter_opendroneid/models/message_container_authenticity_status.dart';
import 'package:flutter_opendroneid/models/message_container.dart';

class MessageContainerAuthenticator {
  /// Detectors that contribute to final score.
  static final detectors = [
    MacAddressSpooferDetector(),
    TimestampSpooferDetector(),
    AuthDataSpooferDetector(),
    BasicIdSpooferDetector(),
    OperatorIdSpooferDetector(),
    LocationSpooferDetector(),
    SelfIdSpooferDetector(),
    SystemDataSpooferDetector(),
  ];

  /// Check contents of message container using [detectors].
  /// Test known spoofer data traits, each detector returns probability that
  /// data were spoofed. Sum up the probablities and make final decision.
  /// Convert score into [MessageContainerAuthenticityStatus] according to inverval:
  ///   < max/2 - untrusted
  ///   max/2, max/4*3 - suspicious
  ///   > max/4*3 - counterfeit.
  static MessageContainerAuthenticityStatus determineAuthenticityStatus(
      MessageContainer container) {
    var score = 0.0;

    detectors.forEach((element) {
      score += element.calculateSpoofedProbability(container);
    });

    return _scoreToStatus(score);
  }

  static MessageContainerAuthenticityStatus _scoreToStatus(double score) {
    final maxScore = detectors.length;

    // if nothing can be decided, score is exactly half, when score is bigger
    // than half, at least one detector noticed suspisious data
    final noSuspisionScore = maxScore * 0.5;
    final counterfeitScore = maxScore * 0.75;

    if (score <= noSuspisionScore)
      return MessageContainerAuthenticityStatus.untrusted;
    if (score <= counterfeitScore)
      return MessageContainerAuthenticityStatus.suspicious;
    return MessageContainerAuthenticityStatus.counterfeit;
  }
}

abstract class SpooferDetector {
  const SpooferDetector();

  /// Return a probability that data are spoofed.
  ///   0 -> data are real
  /// 0.5 -> cannot decide
  ///   1 -> data are counterfeit
  double calculateSpoofedProbability(MessageContainer container);
}

class MacAddressSpooferDetector implements SpooferDetector {
  // spoofed data MAC addr always starts with a zero
  // if starts with 0, still doesn't have to be spoofed
  @override
  double calculateSpoofedProbability(MessageContainer container) =>
      container.macAddress.startsWith('0') ? 0.75 : 0;
}

/// Spoofer starts counting time from known timestamp.
/// If received timestamp is in short interval after that timestamp,
/// data are probably spoofed.
class TimestampSpooferDetector implements SpooferDetector {
  static final spooferTimestamp = DateTime(2022, 11, 16, 10);
  static const maxUptime = Duration(days: 10);

  bool _isNearSpooferTimestamp(DateTime timestamp) =>
      timestamp.isAfter(spooferTimestamp) &&
      timestamp.isBefore(spooferTimestamp.add(maxUptime));

  // returns true if any of timestamps within the interval
  // (spooferTimestamp, spooferTimestamp + maxUptime).
  @override
  double calculateSpoofedProbability(MessageContainer container) {
    final authTimestamp = container.authenticationMessage?.timestamp;
    final systemTimestamp = container.systemDataMessage?.timestamp;

    if (authTimestamp == null && systemTimestamp == null) return 0.5;

    return (authTimestamp != null && _isNearSpooferTimestamp(authTimestamp)) ||
            systemTimestamp != null && _isNearSpooferTimestamp(systemTimestamp)
        ? 1
        : 0;
  }
}

/// Following detectors check the contents of messages and compare them with
/// known values for spoofed data.
class AuthDataSpooferDetector implements SpooferDetector {
  @override
  double calculateSpoofedProbability(MessageContainer container) {
    final message = container.authenticationMessage;
    // message not received, cannot decide
    if (message == null) return 0.5;

    // if len and type are not as expected, data are not spoofed
    if (message.authData.authData.length != maxAuthDataPages ||
        message.authType != AuthType.none) return 0.1;

    // spoofed auth data contain indexes
    for (var index = 0; index < message.authData.authData.length; index++) {
      if (message.authData.authData[index] != index) return 0.2;
    }
    return 0.8;
  }
}

class BasicIdSpooferDetector implements SpooferDetector {
  @override
  double calculateSpoofedProbability(MessageContainer container) {
    final messages = container.basicIdMessages;

    if (messages == null || messages.isEmpty) return 0.5;

    // spofed data always have 1 basic id with types set to .none
    return (messages.length == 1 &&
            messages.values.first.uaType == UAType.none &&
            messages.values.first.uasID.type == IDType.none)
        ? 0.8
        : 0.2;
  }
}

class OperatorIdSpooferDetector implements SpooferDetector {
  @override
  double calculateSpoofedProbability(MessageContainer container) {
    final message = container.operatorIdMessage;
    // message not received, cannot decide
    if (message == null) return 0.5;

    // spofed DATA have 16 random chars in Operator IDm
    // [OperatorIDTypeOperatorID] type and len 16
    if (message.operatorIDType is! OperatorIDTypeOperatorID ||
        message.operatorID.length != 16) return 0.3;
    // check that country code cantains only capital letters
    // if not, data are spoofed
    final countryCode = message.operatorID.substring(0, 3);
    if (countryCode != countryCode.toUpperCase()) return 0.9;
    // country code contains capital letters,
    // data can still be spoofed
    return 0.4;
  }
}

class LocationSpooferDetector implements SpooferDetector {
  @override
  double calculateSpoofedProbability(MessageContainer container) {
    final message = container.locationMessage;
    // message not received, cannot decide
    if (message == null) return 0.5;

    // spoofed if all values are set as expected
    final spoofed = message.status == OperationalStatus.none &&
        (message.verticalSpeed == null ||
            message.verticalSpeed == INV_SPEED_V) &&
        message.heightType == HeightType.aboveTakeoff &&
        message.horizontalAccuracy == HorizontalAccuracy.meters_10 &&
        message.verticalAccuracy == VerticalAccuracy.meters_10 &&
        message.baroAltitudeAccuracy == VerticalAccuracy.meters_10 &&
        message.speedAccuracy == SpeedAccuracy.meterPerSecond_10 &&
        // spoofed data have acc 1.5
        message.timestampAccuracy?.compareTo(Duration(milliseconds: 1500)) == 0;
    return spoofed ? 1 : 0.2;
  }
}

class SelfIdSpooferDetector implements SpooferDetector {
  @override
  double calculateSpoofedProbability(MessageContainer container) {
    final message = container.selfIdMessage;
    // message not received, cannot decide
    if (message == null) return 0.5;

    // spoofed if all values are set as expected
    return message.descriptionType is DescriptionTypeText &&
            message.description == "Recreational"
        ? 1
        : 0.2;
  }
}

class SystemDataSpooferDetector implements SpooferDetector {
  @override
  double calculateSpoofedProbability(MessageContainer container) {
    final message = container.systemDataMessage;
    // message not received, cannot decide
    if (message == null) return 0.5;

    // spoofed if all values are set as expected
    final spoofed = message.operatorLocationType ==
            OperatorLocationType.takeOff &&
        message.uaClassification is UAClassificationEurope &&
        (message.uaClassification as UAClassificationEurope).uaCategoryEurope ==
            UACategoryEurope.EUOpen &&
        (message.uaClassification as UAClassificationEurope).uaClassEurope ==
            UAClassEurope.EUClass_4 &&
        message.areaCount == 1 &&
        message.areaRadius == 500 &&
        message.areaCeiling == null &&
        message.areaFloor == null;
    return spoofed ? 1 : 0.2;
  }
}
