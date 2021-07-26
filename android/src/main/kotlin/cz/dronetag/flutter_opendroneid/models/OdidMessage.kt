package cz.dronetag.flutter_opendroneid.models

interface OdidMessage {
    enum class Type {
        BASIC_ID, LOCATION, AUTH, SELF_ID, SYSTEM, OPERATOR_ID;
    }

    enum class Source {
        BLUETOOTH_LEGACY, BLUETOOTH_LONG_RANGE, WIFI_NAN, WIFI_BEACON;
    }

    class Header {
        var type: Type? = null
        var version: Int? = null
    }

    val type: Type

    fun toJson(): MutableMap<String, Any>
}