import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedDay = 1;
  bool _reminderEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final day = await NotificationService.instance.getSavedReminderDay();
    setState(() {
      if (day != null) {
        _selectedDay = day;
        _reminderEnabled = true;
      }
      _loading = false;
    });
  }

  Future<void> _saveReminder() async {
    if (_reminderEnabled) {
      await NotificationService.instance.scheduleMonthlyReminder(_selectedDay);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monthly reminder set for day $_selectedDay of every month at 9:00 AM'),
            backgroundColor: const Color(0xFF388E3C),
          ),
        );
      }
    } else {
      await NotificationService.instance.cancelReminder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder cancelled'), backgroundColor: Colors.grey),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Reminder Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Monthly Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Receive a notification on the selected day each month'),
                          value: _reminderEnabled,
                          activeColor: const Color(0xFF1976D2),
                          onChanged: (v) => setState(() => _reminderEnabled = v),
                        ),
                        if (_reminderEnabled) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('Send reminder on day:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(28, (i) => i + 1).map((day) {
                              final selected = day == _selectedDay;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedDay = day),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFF1976D2) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected ? const Color(0xFF1976D2) : Colors.grey[300]!,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF57C00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You will get a notification at 9:00 AM on day $_selectedDay of every month. Tap the notification to open the app and send WhatsApp reminders.',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFF57C00)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                        const SizedBox(height: 8),
                        const Text('TuitionPro v1.0.0', style: TextStyle(color: Colors.grey)),
                        const Text('Tuition Teacher Management App', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
