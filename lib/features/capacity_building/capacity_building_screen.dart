
import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/features/capacity_building/screens/training_attended_screen.dart';
import 'package:cohv/features/capacity_building/screens/training_imparted_screen.dart';

import 'data/capacity_building_api_service.dart';

const Color capacityGreen = Color(0xFF176B57);
const Color capacityBackground = Color(0xFFF3F8F6);
const Color capacityBorder = Color(0xFFDCE8E2);
const Color capacityMuted = Color(0xFF80918B);

class CapacityBuildingScreen extends StatefulWidget {
final String? volunteerId;

const CapacityBuildingScreen({
super.key,
this.volunteerId,
});

@override
State<CapacityBuildingScreen> createState() =>
_CapacityBuildingScreenState();
}

class _CapacityBuildingScreenState extends State<CapacityBuildingScreen> {
final CapacityBuildingApiService _apiService =
CapacityBuildingApiService();

int _impartedCount = 0;
int _attendedCount = 0;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadCounts();
}

Future<void> _loadCounts() async {
try {
final impartedFuture = _apiService.fetchTrainingImpartedList();
final attendedFuture = _apiService.fetchTrainingAttendedList();

final results = await Future.wait([
impartedFuture,
attendedFuture,
]);

if (!mounted) return;

setState(() {
_impartedCount = results[0].length;
_attendedCount = results[1].length;
_isLoading = false;
});
} catch (_) {
if (!mounted) return;

setState(() {
_isLoading = false;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: capacityBackground,
appBar: AuthenticatedAppBar(
title: 'Capacity Building',
backgroundColor: capacityGreen,
volunteerId: widget.volunteerId ?? '',
onBackPressed: () => Navigator.pop(context),
),
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(16),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(26),
border: Border.all(
color: capacityBorder,
),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const SizedBox(height: 12),

_buildOption(
context: context,
title: 'Training imparted',
count: _isLoading ? null : _impartedCount,
onTap: () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => TrainingImpartedScreen(
volunteerId: widget.volunteerId,
),
),
);

_loadCounts();
},
),

_buildOption(
context: context,
title: 'Training attended',
count: _isLoading ? null : _attendedCount,
onTap: () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => TrainingAttendedScreen(
volunteerId: widget.volunteerId,
),
),
);

_loadCounts();
},
),

const SizedBox(height: 12),
],
),
),
),
),
bottomNavigationBar: _bottomNavigation(),
);
}

Widget _buildOption({
required BuildContext context,
required String title,
required int? count,
required VoidCallback onTap,
}) {
return InkWell(
onTap: onTap,
child: Container(
padding: const EdgeInsets.symmetric(vertical: 18),
decoration: const BoxDecoration(
border: Border(
top: BorderSide(
color: capacityBorder,
width: 1.5,
),
),
),
child: Row(
children: [
Expanded(
child: Text(
title,
style: const TextStyle(
color: Color(0xFF243832),
fontSize: 16,
fontWeight: FontWeight.w600,
),
),
),

Text(
count != null ? '$count' : '...',
style: const TextStyle(
color: capacityMuted,
fontSize: 14,
fontWeight: FontWeight.w600,
),
),

const SizedBox(width: 5),

const Icon(
Icons.chevron_right,
color: capacityMuted,
size: 20,
),
],
),
),
);
}

Widget _bottomNavigation() {
return Container(
decoration: const BoxDecoration(
color: Colors.white,
border: Border(
top: BorderSide(
color: capacityBorder,
),
),
),
child: SafeArea(
top: false,
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 10),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: const [
_NavigationItem(
icon: Icons.home,
label: 'Dashboard',
),
_NavigationItem(
icon: Icons.grid_view_rounded,
label: 'Actions',
),
_NavigationItem(
icon: Icons.article,
label: 'Reports',
),
_NavigationItem(
icon: Icons.person,
label: 'Profile',
),
],
),
),
),
);
}
}

class _NavigationItem extends StatelessWidget {
final IconData icon;
final String label;

const _NavigationItem({
required this.icon,
required this.label,
});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: () {
Navigator.popUntil(
context,
(route) => route.isFirst,
);
},
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
color: capacityMuted,
size: 23,
),

const SizedBox(height: 5),

Text(
label,
style: const TextStyle(
color: capacityMuted,
fontSize: 11,
fontWeight: FontWeight.w500,
),
),
],
),
);
}
}
