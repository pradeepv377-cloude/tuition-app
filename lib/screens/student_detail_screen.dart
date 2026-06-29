import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/student.dart';
import '../models/fee_record.dart';
import '../services/whatsapp_service.dart';
import 'add_student_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  List<FeeRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await DatabaseHelper.instance.getFeeRecordsForStudent(widget.student.id!);
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _togglePaid(FeeRecord record) async {
    final updated = record.copyWith(
      isPaid: !record.isPaid,
      paidDate: !record.isPaid ? DateTime.now() : null,
    );
    await DatabaseHelper.instance.upsertFeeRecord(updated);
    _load();
  }

  Future<void> _addThisMonthRecord() async {
    final now = DateTime.now();
    final existing = await DatabaseHelper.instance.getFeeRecord(widget.student.id!, now.month, now.year);
    if (existing == null) {
      await DatabaseHelper.instance.upsertFeeRecord(FeeRecord(
        studentId: widget.student.id!,
        month: now.month,
        year: now.year,
        amount: widget.student.monthlyFee,
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(s.name),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddStudentScreen(student: s)),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(student: s),
                  const SizedBox(height: 16),
                  if (s.isInDemoPeriod)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Color(0xFF7B1FA2)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Demo period: ${s.demoRemainingDays} day(s) remaining\n'
                              'Ends on ${DateFormat('dd MMM yyyy').format(s.admissionDate.add(const Duration(days: 3)))}',
                              style: const TextStyle(color: Color(0xFF7B1FA2), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fee History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      TextButton.icon(
                        onPressed: _addThisMonthRecord,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add This Month'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF1976D2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_records.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text('No fee records yet', style: TextStyle(color: Colors.grey[500])),
                      ),
                    )
                  else
                    ..._records.map((r) => _FeeRecordTile(
                          record: r,
                          student: s,
                          onToggle: () => _togglePaid(r),
                        )),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Student student;
  const _InfoCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF1976D2).withOpacity(0.12),
            child: Text(
              student.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
            ),
          ),
          const SizedBox(height: 10),
          Text(student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          _InfoRow(Icons.family_restroom, 'Parent', student.parentName),
          _InfoRow(Icons.phone, 'WhatsApp', student.whatsappNumber),
          _InfoRow(Icons.book, 'Subject', student.subject),
          _InfoRow(Icons.currency_rupee, 'Monthly Fee', '₹${student.monthlyFee.toStringAsFixed(0)}'),
          _InfoRow(Icons.calendar_today, 'Admission', DateFormat('dd MMM yyyy').format(student.admissionDate)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => WhatsAppService.sendReminderToStudent(
                student: student,
                month: DateTime.now().month,
                year: DateTime.now().year,
              ),
              icon: const Icon(Icons.message),
              label: const Text('Send WhatsApp Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _FeeRecordTile extends StatelessWidget {
  final FeeRecord record;
  final Student student;
  final VoidCallback onToggle;

  const _FeeRecordTile({required this.record, required this.student, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isPaid ? const Color(0xFF388E3C).withOpacity(0.3) : const Color(0xFFC62828).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            record.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: record.isPaid ? const Color(0xFF388E3C) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.monthYearLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  record.isPaid
                      ? 'Paid on ${DateFormat('dd MMM yyyy').format(record.paidDate!)}'
                      : 'Pending',
                  style: TextStyle(fontSize: 12, color: record.isPaid ? const Color(0xFF388E3C) : Colors.red[400]),
                ),
              ],
            ),
          ),
          Text('₹${record.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: record.isPaid
                    ? Colors.grey.withOpacity(0.1)
                    : const Color(0xFF388E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.isPaid ? 'Undo' : 'Mark Paid',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: record.isPaid ? Colors.grey : const Color(0xFF388E3C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
