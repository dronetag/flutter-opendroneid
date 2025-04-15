package cz.dronetag.flutter_opendroneid

class PluginNotInitializedException : Exception("Plugin was not initialized. Call the initialize method before first use") {}

class PluginNotAttachedException : Exception("Unable to initialize, plugin was not attached to activity") {}