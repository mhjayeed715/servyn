import 'package:flutter/material.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  double _serviceRadius = 15.0;
  
  final List<TimeSlot> _timeSlots = [
    TimeSlot('09:00', '10:00', false),
    TimeSlot('11:00', '12:00', false),
    TimeSlot('14:00', '15:00', true), // Booked
  ];

  void _addTimeSlot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Time Slot'),
        content: const Text('Time slot picker coming soon!\n\nYou will be able to select start and end times for your availability.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _timeSlots.add(TimeSlot('16:00', '17:00', false));
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF136DEC)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeTimeSlot(int index) {
    if (!_timeSlots[index].isBooked) {
      setState(() {
        _timeSlots.removeAt(index);
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    return List.generate(lastDay.day, (index) => DateTime(_focusedMonth.year, _focusedMonth.month, index + 1));
  }

  int _getFirstWeekdayOfMonth() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    return firstDay.weekday % 7; // 0 = Sunday, 6 = Saturday
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName() {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF111418)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Availability',
          style: TextStyle(color: Color(0xFF111418), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF6F7F8),
              child: const Icon(Icons.account_circle, color: Color(0xFF111418)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // Calendar Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Date',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDay = DateTime.now();
                                _focusedMonth = DateTime.now();
                              });
                            },
                            child: const Text('Today', style: TextStyle(color: Color(0xFF136DEC), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            // Month Navigation
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: _previousMonth,
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  Text(
                                    _getMonthName(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: _nextMonth,
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Weekday Headers
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                  .map((day) => SizedBox(
                                        width: 40,
                                        child: Center(
                                          child: Text(
                                            day,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 4),
                            // Calendar Grid
                            _buildCalendarGrid(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Time Slots Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Working Hours',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                          ),
                          Text(
                            '${_timeSlots.length} slots configured',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.asMap().entries.map((entry) {
                          final index = entry.key;
                          final slot = entry.value;
                          return _buildTimeSlotChip(slot, index);
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _addTimeSlot,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Time Slot'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          side: const BorderSide(color: Colors.grey, style: BorderStyle.solid),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Service Area Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Service Area',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111418)),
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF136DEC), size: 18),
                              SizedBox(width: 4),
                              Text('Dhaka', style: TextStyle(color: Color(0xFF136DEC), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Map Placeholder
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                              height: 220,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.map, size: 80, color: Colors.grey),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                                ),
                                child: const Icon(Icons.my_location, size: 20, color: Color(0xFF111418)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Radius Slider
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Service Radius', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('${_serviceRadius.toInt()} km', style: const TextStyle(color: Color(0xFF136DEC), fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Slider(
                              value: _serviceRadius,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              activeColor: const Color(0xFF136DEC),
                              onChanged: (value) {
                                setState(() {
                                  _serviceRadius = value;
                                });
                              },
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1 km', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('50 km', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: const Border(top: BorderSide(color: Color(0xFFE6E1DB))),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Availability updated successfully!')),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Update Availability'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF136DEC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _getDaysInMonth();
    final firstWeekday = _getFirstWeekdayOfMonth();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: days.length + firstWeekday,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return const SizedBox();
        }
        
        final dayIndex = index - firstWeekday;
        final day = days[dayIndex];
        final isSelected = _isSameDay(day, _selectedDay);
        final isToday = _isSameDay(day, DateTime.now());
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF136DEC) : (isToday ? const Color(0xFF136DEC).withOpacity(0.1) : null),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF111418),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSlotChip(TimeSlot slot, int index) {
    if (slot.isBooked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${slot.start} - ${slot.end}',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('BOOKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _removeTimeSlot(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: index == 0 ? const Color(0xFF136DEC).withOpacity(0.1) : const Color(0xFFF0F2F4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: index == 0 ? const Color(0xFF136DEC).withOpacity(0.2) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 16, color: index == 0 ? const Color(0xFF136DEC) : const Color(0xFF111418)),
            const SizedBox(width: 4),
            Text(
              '${slot.start} - ${slot.end}',
              style: TextStyle(
                color: index == 0 ? const Color(0xFF136DEC) : const Color(0xFF111418),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSlot {
  final String start;
  final String end;
  final bool isBooked;

  TimeSlot(this.start, this.end, this.isBooked);
}
