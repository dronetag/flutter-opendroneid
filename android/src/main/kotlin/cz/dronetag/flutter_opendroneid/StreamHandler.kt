package cz.dronetag.flutter_opendroneid

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

open class StreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events != null) {
            eventSink = events
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun send(data: Any) {
        eventSink?.success(data)
    }

    companion object {
        fun bindMultipleHandlers(messenger: BinaryMessenger, bindings: Map<String, StreamHandler>) {
            for (binding in bindings) {
                EventChannel(messenger, binding.key).setStreamHandler(binding.value)
            }
        }
        fun clearMultipleHandlers(messenger: BinaryMessenger, names: List<String>) {
            for (name in names) {
                EventChannel(messenger, name).setStreamHandler(null)
            }
        }
    }
}
