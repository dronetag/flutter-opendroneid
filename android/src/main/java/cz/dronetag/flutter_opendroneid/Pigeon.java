// Autogenerated from Pigeon (v1.0.17), do not edit directly.
// See also: https://pub.dev/packages/pigeon

package cz.dronetag.flutter_opendroneid;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/** Generated class from Pigeon. */
@SuppressWarnings({"unused", "unchecked", "CodeBlock2Expr", "RedundantSuppression"})
public class Pigeon {

  public enum MessageType {
    BasicId(0),
    Location(1),
    Auth(2),
    SelfId(3),
    System(4),
    OperatorId(5);

    private int index;
    private MessageType(final int index) {
      this.index = index;
    }
  }

  public enum MessageSource {
    BluetoothLegacy(0),
    BluetoothLongRange(1),
    WifiNaN(2),
    WifiBeacon(3);

    private int index;
    private MessageSource(final int index) {
      this.index = index;
    }
  }

  public enum IdType {
    None(0),
    Serial_Number(1),
    CAA_Registration_ID(2),
    UTM_Assigned_ID(3),
    Specific_Session_ID(4);

    private int index;
    private IdType(final int index) {
      this.index = index;
    }
  }

  public enum UaType {
    None(0),
    Aeroplane(1),
    Helicopter_or_Multirotor(2),
    Gyroplane(3),
    Hybrid_Lift(4),
    Ornithopter(5),
    Glider(6),
    Kite(7),
    Free_balloon(8),
    Captive_balloon(9),
    Airship(10),
    Free_fall_parachute(11),
    Rocket(12),
    Tethered_powered_aircraft(13),
    Ground_obstacle(14),
    Other(15);

    private int index;
    private UaType(final int index) {
      this.index = index;
    }
  }

  public enum AircraftStatus {
    Undeclared(0),
    Ground(1),
    Airborne(2),
    Emergency(3);

    private int index;
    private AircraftStatus(final int index) {
      this.index = index;
    }
  }

  public enum HeightType {
    Takeoff(0),
    Ground(1);

    private int index;
    private HeightType(final int index) {
      this.index = index;
    }
  }

  public enum HorizontalAccuracy {
    Unknown(0),
    kilometers_18_52(1),
    kilometers_7_408(2),
    kilometers_3_704(3),
    kilometers_1_852(4),
    meters_926(5),
    meters_555_6(6),
    meters_185_2(7),
    meters_92_6(8),
    meters_30(9),
    meters_10(10),
    meters_3(11),
    meters_1(12);

    private int index;
    private HorizontalAccuracy(final int index) {
      this.index = index;
    }
  }

  public enum VerticalAccuracy {
    Unknown(0),
    meters_150(1),
    meters_45(2),
    meters_25(3),
    meters_10(4),
    meters_3(5),
    meters_1(6);

    private int index;
    private VerticalAccuracy(final int index) {
      this.index = index;
    }
  }

  public enum SpeedAccuracy {
    Unknown(0),
    meter_per_second_10(1),
    meter_per_second_3(2),
    meter_per_second_1(3),
    meter_per_second_0_3(4);

    private int index;
    private SpeedAccuracy(final int index) {
      this.index = index;
    }
  }

  public enum BluetoothState {
    Unknown(0),
    Resetting(1),
    Unsupported(2),
    Unauthorized(3),
    PoweredOff(4),
    PoweredOn(5);

    private int index;
    private BluetoothState(final int index) {
      this.index = index;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static class BasicIdMessage {
    private @NonNull Long receivedTimestamp;
    public @NonNull Long getReceivedTimestamp() { return receivedTimestamp; }
    public void setReceivedTimestamp(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"receivedTimestamp\" is null.");
      }
      this.receivedTimestamp = setterArg;
    }

    private @NonNull String macAddress;
    public @NonNull String getMacAddress() { return macAddress; }
    public void setMacAddress(@NonNull String setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"macAddress\" is null.");
      }
      this.macAddress = setterArg;
    }

    private @NonNull MessageSource source;
    public @NonNull MessageSource getSource() { return source; }
    public void setSource(@NonNull MessageSource setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"source\" is null.");
      }
      this.source = setterArg;
    }

    private @Nullable Long rssi;
    public @Nullable Long getRssi() { return rssi; }
    public void setRssi(@Nullable Long setterArg) {
      this.rssi = setterArg;
    }

    private @NonNull String uasId;
    public @NonNull String getUasId() { return uasId; }
    public void setUasId(@NonNull String setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"uasId\" is null.");
      }
      this.uasId = setterArg;
    }

    private @NonNull IdType idType;
    public @NonNull IdType getIdType() { return idType; }
    public void setIdType(@NonNull IdType setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"idType\" is null.");
      }
      this.idType = setterArg;
    }

    private @NonNull UaType uaType;
    public @NonNull UaType getUaType() { return uaType; }
    public void setUaType(@NonNull UaType setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"uaType\" is null.");
      }
      this.uaType = setterArg;
    }

    /** Constructor is private to enforce null safety; use Builder. */
    private BasicIdMessage() {}
    public static class Builder {
      private @Nullable Long receivedTimestamp;
      public @NonNull Builder setReceivedTimestamp(@NonNull Long setterArg) {
        this.receivedTimestamp = setterArg;
        return this;
      }
      private @Nullable String macAddress;
      public @NonNull Builder setMacAddress(@NonNull String setterArg) {
        this.macAddress = setterArg;
        return this;
      }
      private @Nullable MessageSource source;
      public @NonNull Builder setSource(@NonNull MessageSource setterArg) {
        this.source = setterArg;
        return this;
      }
      private @Nullable Long rssi;
      public @NonNull Builder setRssi(@Nullable Long setterArg) {
        this.rssi = setterArg;
        return this;
      }
      private @Nullable String uasId;
      public @NonNull Builder setUasId(@NonNull String setterArg) {
        this.uasId = setterArg;
        return this;
      }
      private @Nullable IdType idType;
      public @NonNull Builder setIdType(@NonNull IdType setterArg) {
        this.idType = setterArg;
        return this;
      }
      private @Nullable UaType uaType;
      public @NonNull Builder setUaType(@NonNull UaType setterArg) {
        this.uaType = setterArg;
        return this;
      }
      public @NonNull BasicIdMessage build() {
        BasicIdMessage pigeonReturn = new BasicIdMessage();
        pigeonReturn.setReceivedTimestamp(receivedTimestamp);
        pigeonReturn.setMacAddress(macAddress);
        pigeonReturn.setSource(source);
        pigeonReturn.setRssi(rssi);
        pigeonReturn.setUasId(uasId);
        pigeonReturn.setIdType(idType);
        pigeonReturn.setUaType(uaType);
        return pigeonReturn;
      }
    }
    @NonNull Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("receivedTimestamp", receivedTimestamp);
      toMapResult.put("macAddress", macAddress);
      toMapResult.put("source", source == null ? null : source.index);
      toMapResult.put("rssi", rssi);
      toMapResult.put("uasId", uasId);
      toMapResult.put("idType", idType == null ? null : idType.index);
      toMapResult.put("uaType", uaType == null ? null : uaType.index);
      return toMapResult;
    }
    static @NonNull BasicIdMessage fromMap(@NonNull Map<String, Object> map) {
      BasicIdMessage pigeonResult = new BasicIdMessage();
      Object receivedTimestamp = map.get("receivedTimestamp");
      pigeonResult.setReceivedTimestamp((receivedTimestamp == null) ? null : ((receivedTimestamp instanceof Integer) ? (Integer)receivedTimestamp : (Long)receivedTimestamp));
      Object macAddress = map.get("macAddress");
      pigeonResult.setMacAddress((String)macAddress);
      Object source = map.get("source");
      pigeonResult.setSource(source == null ? null : MessageSource.values()[(int)source]);
      Object rssi = map.get("rssi");
      pigeonResult.setRssi((rssi == null) ? null : ((rssi instanceof Integer) ? (Integer)rssi : (Long)rssi));
      Object uasId = map.get("uasId");
      pigeonResult.setUasId((String)uasId);
      Object idType = map.get("idType");
      pigeonResult.setIdType(idType == null ? null : IdType.values()[(int)idType]);
      Object uaType = map.get("uaType");
      pigeonResult.setUaType(uaType == null ? null : UaType.values()[(int)uaType]);
      return pigeonResult;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static class LocationMessage {
    private @NonNull Long receivedTimestamp;
    public @NonNull Long getReceivedTimestamp() { return receivedTimestamp; }
    public void setReceivedTimestamp(@NonNull Long setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"receivedTimestamp\" is null.");
      }
      this.receivedTimestamp = setterArg;
    }

    private @NonNull String macAddress;
    public @NonNull String getMacAddress() { return macAddress; }
    public void setMacAddress(@NonNull String setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"macAddress\" is null.");
      }
      this.macAddress = setterArg;
    }

    private @NonNull MessageSource source;
    public @NonNull MessageSource getSource() { return source; }
    public void setSource(@NonNull MessageSource setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"source\" is null.");
      }
      this.source = setterArg;
    }

    private @Nullable Long rssi;
    public @Nullable Long getRssi() { return rssi; }
    public void setRssi(@Nullable Long setterArg) {
      this.rssi = setterArg;
    }

    private @NonNull AircraftStatus status;
    public @NonNull AircraftStatus getStatus() { return status; }
    public void setStatus(@NonNull AircraftStatus setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"status\" is null.");
      }
      this.status = setterArg;
    }

    private @NonNull HeightType heightType;
    public @NonNull HeightType getHeightType() { return heightType; }
    public void setHeightType(@NonNull HeightType setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"heightType\" is null.");
      }
      this.heightType = setterArg;
    }

    private @Nullable Long direction;
    public @Nullable Long getDirection() { return direction; }
    public void setDirection(@Nullable Long setterArg) {
      this.direction = setterArg;
    }

    private @Nullable Double speedHorizontal;
    public @Nullable Double getSpeedHorizontal() { return speedHorizontal; }
    public void setSpeedHorizontal(@Nullable Double setterArg) {
      this.speedHorizontal = setterArg;
    }

    private @Nullable Double speedVertical;
    public @Nullable Double getSpeedVertical() { return speedVertical; }
    public void setSpeedVertical(@Nullable Double setterArg) {
      this.speedVertical = setterArg;
    }

    private @Nullable Double latitude;
    public @Nullable Double getLatitude() { return latitude; }
    public void setLatitude(@Nullable Double setterArg) {
      this.latitude = setterArg;
    }

    private @Nullable Double longitude;
    public @Nullable Double getLongitude() { return longitude; }
    public void setLongitude(@Nullable Double setterArg) {
      this.longitude = setterArg;
    }

    private @Nullable Double altitudePressure;
    public @Nullable Double getAltitudePressure() { return altitudePressure; }
    public void setAltitudePressure(@Nullable Double setterArg) {
      this.altitudePressure = setterArg;
    }

    private @Nullable Double altitudeGeodetic;
    public @Nullable Double getAltitudeGeodetic() { return altitudeGeodetic; }
    public void setAltitudeGeodetic(@Nullable Double setterArg) {
      this.altitudeGeodetic = setterArg;
    }

    private @Nullable Double height;
    public @Nullable Double getHeight() { return height; }
    public void setHeight(@Nullable Double setterArg) {
      this.height = setterArg;
    }

    private @NonNull HorizontalAccuracy horizontalAccuracy;
    public @NonNull HorizontalAccuracy getHorizontalAccuracy() { return horizontalAccuracy; }
    public void setHorizontalAccuracy(@NonNull HorizontalAccuracy setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"horizontalAccuracy\" is null.");
      }
      this.horizontalAccuracy = setterArg;
    }

    private @NonNull VerticalAccuracy verticalAccuracy;
    public @NonNull VerticalAccuracy getVerticalAccuracy() { return verticalAccuracy; }
    public void setVerticalAccuracy(@NonNull VerticalAccuracy setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"verticalAccuracy\" is null.");
      }
      this.verticalAccuracy = setterArg;
    }

    private @NonNull VerticalAccuracy baroAccuracy;
    public @NonNull VerticalAccuracy getBaroAccuracy() { return baroAccuracy; }
    public void setBaroAccuracy(@NonNull VerticalAccuracy setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"baroAccuracy\" is null.");
      }
      this.baroAccuracy = setterArg;
    }

    private @NonNull SpeedAccuracy speedAccuracy;
    public @NonNull SpeedAccuracy getSpeedAccuracy() { return speedAccuracy; }
    public void setSpeedAccuracy(@NonNull SpeedAccuracy setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"speedAccuracy\" is null.");
      }
      this.speedAccuracy = setterArg;
    }

    private @Nullable Long time;
    public @Nullable Long getTime() { return time; }
    public void setTime(@Nullable Long setterArg) {
      this.time = setterArg;
    }

    private @Nullable Double timeAccuracy;
    public @Nullable Double getTimeAccuracy() { return timeAccuracy; }
    public void setTimeAccuracy(@Nullable Double setterArg) {
      this.timeAccuracy = setterArg;
    }

    /** Constructor is private to enforce null safety; use Builder. */
    private LocationMessage() {}
    public static class Builder {
      private @Nullable Long receivedTimestamp;
      public @NonNull Builder setReceivedTimestamp(@NonNull Long setterArg) {
        this.receivedTimestamp = setterArg;
        return this;
      }
      private @Nullable String macAddress;
      public @NonNull Builder setMacAddress(@NonNull String setterArg) {
        this.macAddress = setterArg;
        return this;
      }
      private @Nullable MessageSource source;
      public @NonNull Builder setSource(@NonNull MessageSource setterArg) {
        this.source = setterArg;
        return this;
      }
      private @Nullable Long rssi;
      public @NonNull Builder setRssi(@Nullable Long setterArg) {
        this.rssi = setterArg;
        return this;
      }
      private @Nullable AircraftStatus status;
      public @NonNull Builder setStatus(@NonNull AircraftStatus setterArg) {
        this.status = setterArg;
        return this;
      }
      private @Nullable HeightType heightType;
      public @NonNull Builder setHeightType(@NonNull HeightType setterArg) {
        this.heightType = setterArg;
        return this;
      }
      private @Nullable Long direction;
      public @NonNull Builder setDirection(@Nullable Long setterArg) {
        this.direction = setterArg;
        return this;
      }
      private @Nullable Double speedHorizontal;
      public @NonNull Builder setSpeedHorizontal(@Nullable Double setterArg) {
        this.speedHorizontal = setterArg;
        return this;
      }
      private @Nullable Double speedVertical;
      public @NonNull Builder setSpeedVertical(@Nullable Double setterArg) {
        this.speedVertical = setterArg;
        return this;
      }
      private @Nullable Double latitude;
      public @NonNull Builder setLatitude(@Nullable Double setterArg) {
        this.latitude = setterArg;
        return this;
      }
      private @Nullable Double longitude;
      public @NonNull Builder setLongitude(@Nullable Double setterArg) {
        this.longitude = setterArg;
        return this;
      }
      private @Nullable Double altitudePressure;
      public @NonNull Builder setAltitudePressure(@Nullable Double setterArg) {
        this.altitudePressure = setterArg;
        return this;
      }
      private @Nullable Double altitudeGeodetic;
      public @NonNull Builder setAltitudeGeodetic(@Nullable Double setterArg) {
        this.altitudeGeodetic = setterArg;
        return this;
      }
      private @Nullable Double height;
      public @NonNull Builder setHeight(@Nullable Double setterArg) {
        this.height = setterArg;
        return this;
      }
      private @Nullable HorizontalAccuracy horizontalAccuracy;
      public @NonNull Builder setHorizontalAccuracy(@NonNull HorizontalAccuracy setterArg) {
        this.horizontalAccuracy = setterArg;
        return this;
      }
      private @Nullable VerticalAccuracy verticalAccuracy;
      public @NonNull Builder setVerticalAccuracy(@NonNull VerticalAccuracy setterArg) {
        this.verticalAccuracy = setterArg;
        return this;
      }
      private @Nullable VerticalAccuracy baroAccuracy;
      public @NonNull Builder setBaroAccuracy(@NonNull VerticalAccuracy setterArg) {
        this.baroAccuracy = setterArg;
        return this;
      }
      private @Nullable SpeedAccuracy speedAccuracy;
      public @NonNull Builder setSpeedAccuracy(@NonNull SpeedAccuracy setterArg) {
        this.speedAccuracy = setterArg;
        return this;
      }
      private @Nullable Long time;
      public @NonNull Builder setTime(@Nullable Long setterArg) {
        this.time = setterArg;
        return this;
      }
      private @Nullable Double timeAccuracy;
      public @NonNull Builder setTimeAccuracy(@Nullable Double setterArg) {
        this.timeAccuracy = setterArg;
        return this;
      }
      public @NonNull LocationMessage build() {
        LocationMessage pigeonReturn = new LocationMessage();
        pigeonReturn.setReceivedTimestamp(receivedTimestamp);
        pigeonReturn.setMacAddress(macAddress);
        pigeonReturn.setSource(source);
        pigeonReturn.setRssi(rssi);
        pigeonReturn.setStatus(status);
        pigeonReturn.setHeightType(heightType);
        pigeonReturn.setDirection(direction);
        pigeonReturn.setSpeedHorizontal(speedHorizontal);
        pigeonReturn.setSpeedVertical(speedVertical);
        pigeonReturn.setLatitude(latitude);
        pigeonReturn.setLongitude(longitude);
        pigeonReturn.setAltitudePressure(altitudePressure);
        pigeonReturn.setAltitudeGeodetic(altitudeGeodetic);
        pigeonReturn.setHeight(height);
        pigeonReturn.setHorizontalAccuracy(horizontalAccuracy);
        pigeonReturn.setVerticalAccuracy(verticalAccuracy);
        pigeonReturn.setBaroAccuracy(baroAccuracy);
        pigeonReturn.setSpeedAccuracy(speedAccuracy);
        pigeonReturn.setTime(time);
        pigeonReturn.setTimeAccuracy(timeAccuracy);
        return pigeonReturn;
      }
    }
    @NonNull Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("receivedTimestamp", receivedTimestamp);
      toMapResult.put("macAddress", macAddress);
      toMapResult.put("source", source == null ? null : source.index);
      toMapResult.put("rssi", rssi);
      toMapResult.put("status", status == null ? null : status.index);
      toMapResult.put("heightType", heightType == null ? null : heightType.index);
      toMapResult.put("direction", direction);
      toMapResult.put("speedHorizontal", speedHorizontal);
      toMapResult.put("speedVertical", speedVertical);
      toMapResult.put("latitude", latitude);
      toMapResult.put("longitude", longitude);
      toMapResult.put("altitudePressure", altitudePressure);
      toMapResult.put("altitudeGeodetic", altitudeGeodetic);
      toMapResult.put("height", height);
      toMapResult.put("horizontalAccuracy", horizontalAccuracy == null ? null : horizontalAccuracy.index);
      toMapResult.put("verticalAccuracy", verticalAccuracy == null ? null : verticalAccuracy.index);
      toMapResult.put("baroAccuracy", baroAccuracy == null ? null : baroAccuracy.index);
      toMapResult.put("speedAccuracy", speedAccuracy == null ? null : speedAccuracy.index);
      toMapResult.put("time", time);
      toMapResult.put("timeAccuracy", timeAccuracy);
      return toMapResult;
    }
    static @NonNull LocationMessage fromMap(@NonNull Map<String, Object> map) {
      LocationMessage pigeonResult = new LocationMessage();
      Object receivedTimestamp = map.get("receivedTimestamp");
      pigeonResult.setReceivedTimestamp((receivedTimestamp == null) ? null : ((receivedTimestamp instanceof Integer) ? (Integer)receivedTimestamp : (Long)receivedTimestamp));
      Object macAddress = map.get("macAddress");
      pigeonResult.setMacAddress((String)macAddress);
      Object source = map.get("source");
      pigeonResult.setSource(source == null ? null : MessageSource.values()[(int)source]);
      Object rssi = map.get("rssi");
      pigeonResult.setRssi((rssi == null) ? null : ((rssi instanceof Integer) ? (Integer)rssi : (Long)rssi));
      Object status = map.get("status");
      pigeonResult.setStatus(status == null ? null : AircraftStatus.values()[(int)status]);
      Object heightType = map.get("heightType");
      pigeonResult.setHeightType(heightType == null ? null : HeightType.values()[(int)heightType]);
      Object direction = map.get("direction");
      pigeonResult.setDirection((direction == null) ? null : ((direction instanceof Integer) ? (Integer)direction : (Long)direction));
      Object speedHorizontal = map.get("speedHorizontal");
      pigeonResult.setSpeedHorizontal((Double)speedHorizontal);
      Object speedVertical = map.get("speedVertical");
      pigeonResult.setSpeedVertical((Double)speedVertical);
      Object latitude = map.get("latitude");
      pigeonResult.setLatitude((Double)latitude);
      Object longitude = map.get("longitude");
      pigeonResult.setLongitude((Double)longitude);
      Object altitudePressure = map.get("altitudePressure");
      pigeonResult.setAltitudePressure((Double)altitudePressure);
      Object altitudeGeodetic = map.get("altitudeGeodetic");
      pigeonResult.setAltitudeGeodetic((Double)altitudeGeodetic);
      Object height = map.get("height");
      pigeonResult.setHeight((Double)height);
      Object horizontalAccuracy = map.get("horizontalAccuracy");
      pigeonResult.setHorizontalAccuracy(horizontalAccuracy == null ? null : HorizontalAccuracy.values()[(int)horizontalAccuracy]);
      Object verticalAccuracy = map.get("verticalAccuracy");
      pigeonResult.setVerticalAccuracy(verticalAccuracy == null ? null : VerticalAccuracy.values()[(int)verticalAccuracy]);
      Object baroAccuracy = map.get("baroAccuracy");
      pigeonResult.setBaroAccuracy(baroAccuracy == null ? null : VerticalAccuracy.values()[(int)baroAccuracy]);
      Object speedAccuracy = map.get("speedAccuracy");
      pigeonResult.setSpeedAccuracy(speedAccuracy == null ? null : SpeedAccuracy.values()[(int)speedAccuracy]);
      Object time = map.get("time");
      pigeonResult.setTime((time == null) ? null : ((time instanceof Integer) ? (Integer)time : (Long)time));
      Object timeAccuracy = map.get("timeAccuracy");
      pigeonResult.setTimeAccuracy((Double)timeAccuracy);
      return pigeonResult;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static class OperatorIdMessage {
    private @NonNull String macAddress;
    public @NonNull String getMacAddress() { return macAddress; }
    public void setMacAddress(@NonNull String setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"macAddress\" is null.");
      }
      this.macAddress = setterArg;
    }

    private @Nullable MessageSource source;
    public @Nullable MessageSource getSource() { return source; }
    public void setSource(@Nullable MessageSource setterArg) {
      this.source = setterArg;
    }

    private @Nullable Long rssi;
    public @Nullable Long getRssi() { return rssi; }
    public void setRssi(@Nullable Long setterArg) {
      this.rssi = setterArg;
    }

    private @NonNull String operatorId;
    public @NonNull String getOperatorId() { return operatorId; }
    public void setOperatorId(@NonNull String setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"operatorId\" is null.");
      }
      this.operatorId = setterArg;
    }

    /** Constructor is private to enforce null safety; use Builder. */
    private OperatorIdMessage() {}
    public static class Builder {
      private @Nullable String macAddress;
      public @NonNull Builder setMacAddress(@NonNull String setterArg) {
        this.macAddress = setterArg;
        return this;
      }
      private @Nullable MessageSource source;
      public @NonNull Builder setSource(@Nullable MessageSource setterArg) {
        this.source = setterArg;
        return this;
      }
      private @Nullable Long rssi;
      public @NonNull Builder setRssi(@Nullable Long setterArg) {
        this.rssi = setterArg;
        return this;
      }
      private @Nullable String operatorId;
      public @NonNull Builder setOperatorId(@NonNull String setterArg) {
        this.operatorId = setterArg;
        return this;
      }
      public @NonNull OperatorIdMessage build() {
        OperatorIdMessage pigeonReturn = new OperatorIdMessage();
        pigeonReturn.setMacAddress(macAddress);
        pigeonReturn.setSource(source);
        pigeonReturn.setRssi(rssi);
        pigeonReturn.setOperatorId(operatorId);
        return pigeonReturn;
      }
    }
    @NonNull Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("macAddress", macAddress);
      toMapResult.put("source", source == null ? null : source.index);
      toMapResult.put("rssi", rssi);
      toMapResult.put("operatorId", operatorId);
      return toMapResult;
    }
    static @NonNull OperatorIdMessage fromMap(@NonNull Map<String, Object> map) {
      OperatorIdMessage pigeonResult = new OperatorIdMessage();
      Object macAddress = map.get("macAddress");
      pigeonResult.setMacAddress((String)macAddress);
      Object source = map.get("source");
      pigeonResult.setSource(source == null ? null : MessageSource.values()[(int)source]);
      Object rssi = map.get("rssi");
      pigeonResult.setRssi((rssi == null) ? null : ((rssi instanceof Integer) ? (Integer)rssi : (Long)rssi));
      Object operatorId = map.get("operatorId");
      pigeonResult.setOperatorId((String)operatorId);
      return pigeonResult;
    }
  }
  private static class ApiCodec extends StandardMessageCodec {
    public static final ApiCodec INSTANCE = new ApiCodec();
    private ApiCodec() {}
  }

  /** Generated interface from Pigeon that represents a handler of messages from Flutter.*/
  public interface Api {
    void startScan();
    void stopScan();
    void setAutorestart(Boolean enable);
    Boolean isScanning();
    Long bluetoothState();

    /** The codec used by Api. */
    static MessageCodec<Object> getCodec() {
      return ApiCodec.INSTANCE;
    }

    /** Sets up an instance of `Api` to handle messages through the `binaryMessenger`. */
    static void setup(BinaryMessenger binaryMessenger, Api api) {
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.Api.startScan", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              api.startScan();
              wrapped.put("result", null);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.Api.stopScan", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              api.stopScan();
              wrapped.put("result", null);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.Api.setAutorestart", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              Boolean enableArg = (Boolean)args.get(0);
              if (enableArg == null) {
                throw new NullPointerException("enableArg unexpectedly null.");
              }
              api.setAutorestart(enableArg);
              wrapped.put("result", null);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.Api.isScanning", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              Boolean output = api.isScanning();
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.Api.bluetoothState", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              Long output = api.bluetoothState();
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
    }
  }
  private static class MessageApiCodec extends StandardMessageCodec {
    public static final MessageApiCodec INSTANCE = new MessageApiCodec();
    private MessageApiCodec() {}
    @Override
    protected Object readValueOfType(byte type, ByteBuffer buffer) {
      switch (type) {
        case (byte)128:         
          return BasicIdMessage.fromMap((Map<String, Object>) readValue(buffer));
        
        case (byte)129:         
          return LocationMessage.fromMap((Map<String, Object>) readValue(buffer));
        
        case (byte)130:         
          return OperatorIdMessage.fromMap((Map<String, Object>) readValue(buffer));
        
        default:        
          return super.readValueOfType(type, buffer);
        
      }
    }
    @Override
    protected void writeValue(ByteArrayOutputStream stream, Object value)     {
      if (value instanceof BasicIdMessage) {
        stream.write(128);
        writeValue(stream, ((BasicIdMessage) value).toMap());
      } else 
      if (value instanceof LocationMessage) {
        stream.write(129);
        writeValue(stream, ((LocationMessage) value).toMap());
      } else 
      if (value instanceof OperatorIdMessage) {
        stream.write(130);
        writeValue(stream, ((OperatorIdMessage) value).toMap());
      } else 
{
        super.writeValue(stream, value);
      }
    }
  }

  /** Generated interface from Pigeon that represents a handler of messages from Flutter.*/
  public interface MessageApi {
    Long determineMessageType(byte[] payload, Long offset);
    BasicIdMessage fromBufferBasic(byte[] payload, Long offset);
    LocationMessage fromBufferLocation(byte[] payload, Long offset);
    OperatorIdMessage fromBufferOperatorId(byte[] payload, Long offset);

    /** The codec used by MessageApi. */
    static MessageCodec<Object> getCodec() {
      return MessageApiCodec.INSTANCE;
    }

    /** Sets up an instance of `MessageApi` to handle messages through the `binaryMessenger`. */
    static void setup(BinaryMessenger binaryMessenger, MessageApi api) {
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.MessageApi.determineMessageType", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              byte[] payloadArg = (byte[])args.get(0);
              if (payloadArg == null) {
                throw new NullPointerException("payloadArg unexpectedly null.");
              }
              Number offsetArg = (Number)args.get(1);
              if (offsetArg == null) {
                throw new NullPointerException("offsetArg unexpectedly null.");
              }
              Long output = api.determineMessageType(payloadArg, offsetArg.longValue());
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.MessageApi.fromBufferBasic", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              byte[] payloadArg = (byte[])args.get(0);
              if (payloadArg == null) {
                throw new NullPointerException("payloadArg unexpectedly null.");
              }
              Number offsetArg = (Number)args.get(1);
              if (offsetArg == null) {
                throw new NullPointerException("offsetArg unexpectedly null.");
              }
              BasicIdMessage output = api.fromBufferBasic(payloadArg, offsetArg.longValue());
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.MessageApi.fromBufferLocation", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              byte[] payloadArg = (byte[])args.get(0);
              if (payloadArg == null) {
                throw new NullPointerException("payloadArg unexpectedly null.");
              }
              Number offsetArg = (Number)args.get(1);
              if (offsetArg == null) {
                throw new NullPointerException("offsetArg unexpectedly null.");
              }
              LocationMessage output = api.fromBufferLocation(payloadArg, offsetArg.longValue());
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.MessageApi.fromBufferOperatorId", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              byte[] payloadArg = (byte[])args.get(0);
              if (payloadArg == null) {
                throw new NullPointerException("payloadArg unexpectedly null.");
              }
              Number offsetArg = (Number)args.get(1);
              if (offsetArg == null) {
                throw new NullPointerException("offsetArg unexpectedly null.");
              }
              OperatorIdMessage output = api.fromBufferOperatorId(payloadArg, offsetArg.longValue());
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
    }
  }
  private static Map<String, Object> wrapError(Throwable exception) {
    Map<String, Object> errorMap = new HashMap<>();
    errorMap.put("message", exception.toString());
    errorMap.put("code", exception.getClass().getSimpleName());
    errorMap.put("details", "Cause: " + exception.getCause() + ", Stacktrace: " + Log.getStackTraceString(exception));
    return errorMap;
  }
}
