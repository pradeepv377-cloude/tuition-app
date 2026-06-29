import 'package:url_launcher/url_launcher.dart';
import '../models/student.dart';
import 'package:intl/intl.dart';

class WhatsAppService {
  static String buildFeeMessage({
    required String studentName,
    required String parentName,
    required double amount,
    required int month,
    required int year,
  }) {
    final monthName = DateFormat('MMMM').format(DateTime(year, month));
    final formatted = amount.toStringAsFixed(0);

    return '''Dear $parentName,

Hope your child $studentName is doing well! 🙏

This is a gentle reminder that the *tuition fee of ₹$formatted* for *$monthName $year* is now due.

Kindly arrange the payment at your earliest convenience.

For any queries, please feel free to contact us.

Thank you for your continued trust and support! 😊

Warm Regards,
Tuition Teacher''';
  }

  static Future<bool> openWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final number = cleaned.startsWith('91') ? cleaned : '91$cleaned';
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$number?text=$encoded');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  static Future<void> sendReminderToStudent({
    required Student student,
    required int month,
    required int year,
  }) async {
    final message = buildFeeMessage(
      studentName: student.name,
      parentName: student.parentName,
      amount: student.monthlyFee,
      month: month,
      year: year,
    );
    await openWhatsApp(
      phoneNumber: student.whatsappNumber,
      message: message,
    );
  }
}
