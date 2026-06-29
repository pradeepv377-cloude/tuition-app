class FeeRecord {
  final int? id;
  final int studentId;
  final int month;
  final int year;
  final double amount;
  final bool isPaid;
  final DateTime? paidDate;
  final String? notes;

  FeeRecord({
    this.id,
    required this.studentId,
    required this.month,
    required this.year,
    required this.amount,
    this.isPaid = false,
    this.paidDate,
    this.notes,
  });

  String get monthYearLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $year';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'month': month,
      'year': year,
      'amount': amount,
      'is_paid': isPaid ? 1 : 0,
      'paid_date': paidDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory FeeRecord.fromMap(Map<String, dynamic> map) {
    return FeeRecord(
      id: map['id'],
      studentId: map['student_id'],
      month: map['month'],
      year: map['year'],
      amount: map['amount'].toDouble(),
      isPaid: map['is_paid'] == 1,
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      notes: map['notes'],
    );
  }

  FeeRecord copyWith({
    int? id,
    int? studentId,
    int? month,
    int? year,
    double? amount,
    bool? isPaid,
    DateTime? paidDate,
    String? notes,
  }) {
    return FeeRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
    );
  }
}
