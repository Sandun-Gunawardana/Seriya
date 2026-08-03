import 'package:flutter/material.dart';

import '../widgets/seriya_map.dart';

const _navy = Color(0xFF10243E);
const _teal = Color(0xFF0F9D8B);
const _softTeal = Color(0xFFE4F6F2);
const _coral = Color(0xFFFF735F);

enum DailyShift { morning, evening }

extension DailyShiftDetails on DailyShift {
  String get title =>
      this == DailyShift.morning ? 'Morning to office' : 'Evening to home';

  String get time =>
      this == DailyShift.morning ? '6:30 – 9:00 AM' : '4:30 – 7:30 PM';

  IconData get icon => this == DailyShift.morning
      ? Icons.wb_sunny_rounded
      : Icons.nights_stay_rounded;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DailyShift _shift = DailyShift.morning;
  bool _isRiding = true;
  int _selectedTab = 0;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  Future<void> _selectShift() async {
    final selected = await showModalBottomSheet<DailyShift>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShiftPicker(selectedShift: _shift),
    );

    if (selected != null && selected != _shift) {
      setState(() => _shift = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SeriyaMap(shift: _shift),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                children: [
                  _DashboardHeader(
                    shift: _shift,
                    onShiftPressed: _selectShift,
                    onProfilePressed: () =>
                        _showMessage('Profile and settings'),
                    onNotificationPressed: () =>
                        _showMessage('You have no new notifications'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _RouteChip(shift: _shift),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: MediaQuery.paddingOf(context).top + 118,
            child: Column(
              children: [
                _MapActionButton(
                  icon: Icons.my_location_rounded,
                  label: 'Centre map',
                  onPressed: () => _showMessage('Map centred on your vehicle'),
                ),
                const SizedBox(height: 12),
                _MapActionButton(
                  icon: Icons.layers_rounded,
                  label: 'Map layers',
                  onPressed: () => _showMessage('Map layers'),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 254,
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: _isRiding
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    label: _isRiding ? "I'm riding" : 'Not riding',
                    isPrimary: true,
                    onPressed: () {
                      setState(() => _isRiding = !_isRiding);
                      _showMessage(
                        _isRiding
                            ? 'Attendance marked: travelling'
                            : 'Attendance marked: not travelling',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_location_alt_rounded,
                    label: 'Pickup point',
                    onPressed: () => _showMessage('Choose your pickup point'),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _TripPanel(
              shift: _shift,
              isRiding: _isRiding,
              selectedTab: _selectedTab,
              onTabSelected: (index) {
                setState(() => _selectedTab = index);
              },
              onContactDriver: () => _showMessage('Contacting your driver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.shift,
    required this.onShiftPressed,
    required this.onProfilePressed,
    required this.onNotificationPressed,
  });

  final DailyShift shift;
  final VoidCallback onShiftPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onNotificationPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          icon: Icons.person_rounded,
          semanticLabel: 'Profile',
          onPressed: onProfilePressed,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.white,
            elevation: 7,
            shadowColor: _navy.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onShiftPressed,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: _softTeal,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(shift.icon, color: _teal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shift.time,
                            style: TextStyle(
                              color: _navy.withValues(alpha: 0.56),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: _teal),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(
          icon: Icons.notifications_none_rounded,
          semanticLabel: 'Notifications',
          showBadge: true,
          onPressed: onNotificationPressed,
        ),
      ],
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({required this.shift});

  final DailyShift shift;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_rounded, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            shift == DailyShift.morning
                ? 'Route A · Kadawatha → Office'
                : 'Route A · Office → Kadawatha',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.showBadge = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          elevation: 7,
          shadowColor: _navy.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onPressed,
            tooltip: semanticLabel,
            icon: Icon(icon, color: _navy),
            iconSize: 25,
            padding: const EdgeInsets.all(13),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _coral,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: _navy.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        icon: Icon(icon, color: _teal),
        iconSize: 23,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? _teal : Colors.white,
      elevation: 7,
      shadowColor: _navy.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPrimary ? Colors.white : _teal, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripPanel extends StatelessWidget {
  const _TripPanel({
    required this.shift,
    required this.isRiding,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onContactDriver,
  });

  final DailyShift shift;
  final bool isRiding;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onContactDriver;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 238 + bottomPadding,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x260D233D),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE3E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 13),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _softTeal,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    color: _teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2FC27E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Vehicle is on the way',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shift.title} · Bus NB-4521',
                        style: TextStyle(
                          color: _navy.withValues(alpha: 0.56),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '12 min',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'estimated',
                      style: TextStyle(
                        color: _navy.withValues(alpha: 0.45),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isRiding ? _softTeal : const Color(0xFFFFECE8),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(
                    isRiding
                        ? Icons.event_available_rounded
                        : Icons.event_busy_rounded,
                    color: isRiding ? _teal : _coral,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      isRiding
                          ? 'You are marked as travelling today'
                          : 'You are not travelling on this shift',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onContactDriver,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.call_rounded, color: _teal, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE9EEEC))),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.location_on_rounded,
                  label: 'Live map',
                  isSelected: selectedTab == 0,
                  onTap: () => onTabSelected(0),
                ),
                _NavItem(
                  icon: Icons.route_rounded,
                  label: 'Trips',
                  isSelected: selectedTab == 1,
                  onTap: () => onTabSelected(1),
                ),
                _NavItem(
                  icon: Icons.fact_check_rounded,
                  label: 'Attendance',
                  isSelected: selectedTab == 2,
                  onTap: () => onTabSelected(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: selectedTab == 3,
                  onTap: () => onTabSelected(3),
                ),
              ],
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? _teal : const Color(0xFF82908C),
                size: 23,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _teal : const Color(0xFF82908C),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftPicker extends StatelessWidget {
  const _ShiftPicker({required this.selectedShift});

  final DailyShift selectedShift;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE3E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Choose today’s shift',
              style: TextStyle(
                color: _navy,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Attendance and locations are recorded separately for each trip.',
              style: TextStyle(
                color: _navy.withValues(alpha: 0.56),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            for (final shift in DailyShift.values)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: shift == selectedShift
                      ? _softTeal
                      : const Color(0xFFF5F7F6),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, shift),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(shift.icon, color: _teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shift.title,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  shift.time,
                                  style: TextStyle(
                                    color: _navy.withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (shift == selectedShift)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _teal,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
