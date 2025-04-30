import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestPermissionButton extends StatefulWidget {
  final List<Permission> permissions;
  final String name;

  const RequestPermissionButton({
    super.key,
    required this.permissions,
    required this.name,
  });

  @override
  State<RequestPermissionButton> createState() =>
      _RequestPermissionButtonState();
}

class _RequestPermissionButtonState extends State<RequestPermissionButton>
    with WidgetsBindingObserver {
  List<PermissionStatus> _statuses = [];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _checkStatuses();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // check permission status when app is resumed
    if (state == AppLifecycleState.resumed) _checkStatuses();
  }

  void _checkStatuses() async {
    final newStatuses = await widget.permissions.map((e) => e.status).wait;
    if (!mounted) return;
    setState(() {
      _statuses = newStatuses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final granted = _statuses.isNotEmpty && _statuses.every((e) => e.isGranted);

    return ElevatedButton(
      onPressed: granted
          ? null
          : () async {
              await widget.permissions.request();
              if (!mounted) return;
              _checkStatuses();
            },
      child:
          Text(granted ? '${widget.name} Granted' : 'Request ${widget.name}'),
    );
  }
}
