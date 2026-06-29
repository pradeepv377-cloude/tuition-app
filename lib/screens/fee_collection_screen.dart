import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/student.dart';
import '../models/fee_record.dart';
import '../services/whatsapp_service.dart';

class FeeCollectionScreen extends StatefulWidget {
  const FeeCollectionScreen({super.key});

  @override
  State<FeeCollectionScreen> createState() => _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends State<FeeCollectionScreen> {
  List<Student> _students = [];
  Map<int, FeeRecord?> _records = {};
  bool _loading = true;
  late int _month;
  late int _year;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await DatabaseHelper.instance.getAllStudents();
    final feeRecords = await DatabaseHelper.instance.getFeeRecordsForMonth(_month, _year);

    final recordMap = <int, FeeRecord?>{};
    for (final s in students) {
      recordMap[s.id!] = feeRecords.firstWhere(
        (r) => r.studentId == s.id,
        orElse: () => FeeRecord(studentId: s.id!, month: _month, year: _year, amount: s.monthlyFee),
      );
    }

    setState(() {
      _students = students;
      _records = recordMap;
      _loading = false;
    });
  }

  Future<void> _togglePaid(Student student) async {
    final current = _records[student.id!];
    if (current == null) return;

    final updated = current.copyWith(
      isPaid: !(current.isPaid),
      paidDate: !current.isPaid ? DateTime.now() : null,
    );
    await DatabaseHelper.instance.upsertFeeRecord(updated);
    _load();
  }

  Future<void> _sendReminder(Student student) async {
    await WhatsAppService.sendReminderToStudent(
      student: student,
      month: _month,
      year: _year,
    );
  }

  Future<void> _sendAllReminders() async {
    final unpaid = _students.where((s) {
      final r = _records[s.id!];
      return r == null || !r.isPaid;
    }).toList();

    if (unpaid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fees are collected! 🎉'), backgroundColor: Color(0xFF388E3C)),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send WhatsApp Reminders'),
        content: Text('Send reminders to ${unpaid.length} parent(s) with pending fees?\n\nWhatsApp will open for each parent one by one.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
            child: const Text('Send All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final student in unpaid) {
      await _sendReminder(student);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1; _year++; }
      if (_month < 1) { _month = 12; _year--; }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final paid = _students.where((s) => _records[s.id!]?.isPaid == true).length;
    final total = _students.length;
    final pending = total - paid;
    final totalAmount = _students.fold<double>(0, (sum, s) => sum + s.monthlyFee);
    final collectedAmount = _students
        .where((s) => _records[s.id!]?.isPaid == true)
        .fold<double>(0, (sum, s) => sum + s.monthlyFee);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Fee Collection'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: const Color(0xFF1976D2),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Text(
                            '${_monthNames[_month - 1]} $_year',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SummaryChip(label: 'Collected', value: '$paid/$total', color: const Color(0xFF81C784)),
                          const SizedBox(width: 8),
                          _SummaryChip(label: 'Pending', value: '$pending', color: const Color(0xFFEF9A9A)),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: 'Amount',
                            value: '₹${collectedAmount.toStringAsFixed(0)}/₹${totalAmount.toStringAsFixed(0)}',
                            color: const Color(0xFFFFCC80),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No students found', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _students.length,
                          itemBuilder: (_, i) {
                            final s = _students[i];
                            final r = _records[s.id!];
                            final isPaid = r?.isPaid ?? false;
                            return _FeeStudentTile(
                              student: s,
                              isPaid: isPaid,
                              onToggle: () => _togglePaid(s),
                              onSendWhatsApp: () => _sendReminder(s),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _sendAllReminders,
                        icon: const Icon(Icons.send),
                        label: Text('Send Reminders to All ($pending Pending)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: color.withOpacity(0.9), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FeeStudentTile extends StatelessWidget {
  final Student student;
  final bool isPaid;
  final VoidCallback onToggle;
  final VoidCallback onSendWhatsApp;

  const _FeeStudentTile({
    required this.student,
    required this.isPaid,
    required this.onToggle,
    required this.onSendWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid ? const Color(0xFF388E3C).withOpacity(0.3) : const Color(0xFFC62828).withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isPaid ? const Color(0xFF388E3C) : Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(student.parentName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFF388E3C).withOpacity(0.1) : Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending ₹${student.monthlyFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? const Color(0xFF388E3C) : Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isPaid)
            IconButton(
              onPressed: onSendWhatsApp,
              icon: const Icon(Icons.message, color: Color(0xFF25D366)),
              tooltip: 'Send WhatsApp',
            ),
        ],
      ),
    );
  }
}
