class Student {
  final int? id;
  final String name;
  final String parentName;
  final String whatsappNumber;
  final String subject;
  final double monthlyFee;
  final DateTime admissionDate;
  final bool isActive;

  Student({
    this.id,
    required this.name,
    required this.parentName,
    required this.whatsappNumber,
    required this.subject,
    required this.monthlyFee,
    required this.admissionDate,
    this.isActive = true,
  });

  bool get isInDemoPeriod {
    final demoEnd = admissionDate.add(const Duration(days: 3));
    return DateTime.now().isBefore(demoEnd);
  }

  int get demoRemainingDays {
    final demoEnd = admissionDate.add(const Duration(days: 3));
    final remaining = demoEnd.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_name': parentName,
      'whatsapp_number': whatsappNumber,
      'subject': subject,
      'monthly_fee': monthlyFee,
      'admission_date': admissionDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      parentName: map['parent_name'],
      whatsappNumber: map['whatsapp_number'],
      subject: map['subject'],
      monthlyFee: map['monthly_fee'].toDouble(),
      admissionDate: DateTime.parse(map['admission_date']),
      isActive: map['is_active'] == 1,
    );
  }

  Student copyWith({
    int? id,
    String? name,
    String? parentName,
    String? whatsappNumber,
    String? subject,
    double? monthlyFee,
    DateTime? admissionDate,
    bool? isActive,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      parentName: parentName ?? this.parentName,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      subject: subject ?? this.subject,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      admissionDate: admissionDate ?? this.admissionDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
