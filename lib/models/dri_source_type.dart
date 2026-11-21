/// Transport used to receive Direct Remote ID advertisements.
enum DriSourceType {
  /// Wi-Fi Beacon or Wi-Fi Aware (NAN). Android only.
  Wifi,

  /// Bluetooth LE legacy or long-range advertisements.
  Bluetooth,
}
