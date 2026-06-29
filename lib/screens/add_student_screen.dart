import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/student.dart';

class AddStudentScreen extends StatefulWidget {
  final Student? student;
  const AddStudentScreen({super.key, this.student});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _parentCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _feeCtrl;
  DateTime _admissionDate = DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _parentCtrl = TextEditingController(text: s?.parentName ?? '');
    _phoneCtrl = TextEditingController(text: s?.whatsappNumber ?? '');
    _subjectCtrl = TextEditingController(text: s?.subject ?? '');
    _feeCtrl = TextEditingController(text: s?.monthlyFee.toStringAsFixed(0) ?? '');
    _admissionDate = s?.admissionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _parentCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _admissionDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final student = Student(
      id: widget.student?.id,
      name: _nameCtrl.text.trim(),
      parentName: _parentCtrl.text.trim(),
      whatsappNumber: _phoneCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      monthlyFee: double.parse(_feeCtrl.text.trim()),
      admissionDate: _admissionDate,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateStudent(student);
    } else {
      await DatabaseHelper.instance.insertStudent(student);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Student' : 'New Admission'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard([
                const _SectionLabel('Student Details'),
                _field(_nameCtrl, 'Student Name', Icons.person, required: true),
                const SizedBox(height: 12),
                _field(_subjectCtrl, 'Subject / Course', Icons.book, required: true),
              ]),
              const SizedBox(height: 14),
              _buildCard([
                const _SectionLabel('Parent Details'),
                _field(_parentCtrl, 'Parent / Guardian Name', Icons.family_restroom, required: true),
                const SizedBox(height: 12),
                _field(
                  _phoneCtrl,
                  'WhatsApp Number',
                  Icons.phone,
                  required: true,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
                    if (digits.length < 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 14),
              _buildCard([
                const _SectionLabel('Fee & Admission'),
                _field(
                  _feeCtrl,
                  'Monthly Fee (₹)',
                  Icons.currency_rupee,
                  required: true,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Admission Date',
                      prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_admissionDate)),
                  ),
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B1FA2).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Color(0xFF7B1FA2), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '3-day demo period starts from admission date',
                            style: TextStyle(fontSize: 12, color: Colors.purple[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEditing ? 'Update Student' : 'Register Admission',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1976D2), letterSpacing: 0.5),
      ),
    );
  }
}
