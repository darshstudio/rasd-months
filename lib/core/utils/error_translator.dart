class ErrorTranslator {
  static String translate(Object error) {
    final str = error.toString();
    if (str.contains('UNIQUE constraint failed: academic_years.name')) {
      return "هذا العام الدراسي مسجل بالفعل بنفس الاسم، يرجى كتابة اسم آخر!";
    }
    if (str.contains('UNIQUE constraint failed: students.seating_number')) {
      return "رقم الجلوس هذا مسجل بالفعل لطالب آخر في هذا العام الدراسي!";
    }
    if (str.contains('UNIQUE constraint failed: school_classes')) {
      return "اسم هذا الفصل مسجل بالفعل لهذه المرحلة!";
    }
    if (str.contains('UNIQUE constraint failed: subjects')) {
      return "هذه المادة مسجلة بالفعل لهذا الصف!";
    }
    if (str.contains('UNIQUE constraint failed')) {
      return "هذه البيانات مسجلة بالفعل وتوجد في قاعدة البيانات!";
    }
    if (str.contains('FOREIGN KEY constraint failed')) {
      return "تعذر حذف أو تعديل العنصر لوجود بيانات مرتبطة به!";
    }
    if (str.contains('SqfliteFfiException') || str.contains('DatabaseException')) {
      return "حدث خطأ أثناء الوصول لقاعدة البيانات، يرجى التأكد من البيانات وإعادة المحاولة.";
    }
    return "تنبيه: تعذر إتمام العملية، يرجى التأكد من المدخلات.";
  }
}
