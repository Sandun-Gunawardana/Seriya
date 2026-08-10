import 'package:flutter/material.dart';

enum RequestedRole { passenger, driver }

extension RequestedRoleDetails on RequestedRole {
  String get title => this == RequestedRole.passenger ? 'Passenger' : 'Driver';

  String get description => this == RequestedRole.passenger
      ? 'View your assigned vehicle and submit attendance'
      : 'Manage assigned trips and passenger pickups';

  IconData get icon => this == RequestedRole.passenger
      ? Icons.airline_seat_recline_normal_rounded
      : Icons.airport_shuttle_rounded;
}
