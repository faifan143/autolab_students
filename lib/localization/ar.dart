const Map<String, String> arTranslations = {
  // General
  'app_title': 'تطبيق أوتولاب للطلاب',
  'ok': 'حسناً',
  'cancel': 'إلغاء',
  'error': 'خطأ',
  'success': 'نجح',
  'loading': 'جاري التحميل...',
  'no_data': 'لا توجد بيانات',
  'retry': 'إعادة المحاولة',

  // Roles / labels
  'student': 'طالب',
  'role_student': 'طالب',

  // Auth
  'login': 'تسجيل الدخول',
  'register': 'إنشاء حساب',
  'email': 'البريد الإلكتروني',
  'password': 'كلمة المرور',
  'name': 'الاسم',
  'logout': 'تسجيل الخروج',
  'app_subtitle_students': 'بوابة الطالب للمعامل والجلسات والدرجات',
  'sign_in_title': 'تسجيل الدخول',
  'sign_in_subtitle': 'الوصول إلى المعامل والجلسات والتقدم الدراسي',
  'email_required': 'البريد الإلكتروني مطلوب',
  'email_invalid': 'يرجى إدخال بريد إلكتروني صالح',
  'password_required': 'كلمة المرور مطلوبة',
  'password_too_short': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
  'forgot_password': 'هل نسيت كلمة المرور؟',
  'no_account_register': 'ليس لديك حساب؟ أنشئ حساباً',
  'register_subtitle_students': 'انضم إلى الدورات والمعامل في أوتولاب',
  'create_account_title': 'إنشاء حساب',
  'create_account_subtitle': 'سجل كطالب للوصول إلى معاملك',
  'name_required': 'الاسم مطلوب',
  'already_have_account_login': 'لديك حساب بالفعل؟ سجّل الدخول',

  // Home
  'home_dashboard': 'الصفحة الرئيسية',
  'home': 'الرئيسية',
  'my_labs': 'معاملي',
  'sessions': 'الجلسات',
  'attendance': 'الحضور',
  'grades': 'الدرجات',
  'files': 'الملفات',
  'chat': 'المحادثة',
  'settings': 'الإعدادات',
  'see_all': 'عرض الكل',
  'greeting_generic': 'مرحباً بعودتك',
  'today_overview': 'اليوم',
  'today_overview_subtitle': 'اطّلع على الجلسات القادمة وآخر الأنشطة',
  'tap_to_open': 'اضغط للفتح',

  // Settings
  'theme': 'السمة',
  'language': 'اللغة',
  'server_ip': 'عنوان الخادم',
  'light': 'فاتح',
  'dark': 'داكن',
  'theme_light': 'سمة فاتحة',
  'theme_dark': 'سمة داكنة',
  'account_section': 'الحساب',
  'app_section': 'التطبيق',
  'about_section': 'حول',
  'profile_details': 'بيانات الملف الشخصي',
  'about_app': 'حول التطبيق',
  'about_app_description': 'تطبيق أوتولاب للطلاب يساعدك على متابعة المعامل والجلسات والدرجات.',
  'privacy_policy': 'سياسة الخصوصية',
  'logout_title': 'تسجيل الخروج؟',
  'logout_message': 'سيتم تسجيل خروجك من هذا الجهاز.',

  // Streaming
  'watch_live_stream': 'مشاهدة البث المباشر',
  'watching_live_stream_of_session': 'مشاهدة البث المباشر للجلسة',
  'connecting': 'جاري الاتصال...',
  'waiting_for_stream': 'في انتظار بدء البث...',
  'receiving_stream': 'استقبال عرض البث...',
  'stream_connected': 'تم الاتصال بالبث',
  'stream_ended': 'انتهى البث',
  'connection_error': 'خطأ في الاتصال',
  'stream_not_available': 'البث غير متاح',
  'live_stream_placeholder': 'بث مباشر\n(مشغل فيديو تجريبي)',
  'reconnect': 'إعادة الاتصال',

  // Attendance
  'scan_qr': 'مسح رمز QR',
  'attendance_history': 'سجل الحضور',

  // Grades
  'all_grades': 'كل الدرجات',
  'filter_by_lab': 'تصفية حسب المعمل',

  // Files
  'open_file': 'فتح الملف',
  'file_details': 'تفاصيل الملف',

  // Chat
  'type_message': 'اكتب رسالة',
  'send': 'إرسال',

  // IP config
  'configure_server_ip': 'إعداد عنوان الخادم',
  'server_configuration': 'إعدادات الخادم',
  'server_configuration_description':
      'سيتم استخدام هذا العنوان لجميع طلبات الـ API واتصالات WebSocket.',
  'server_config_saved': 'تم حفظ إعدادات الخادم بنجاح',
  'ip_segment_1': 'الجزء الأول من IP',
  'ip_segment_2': 'الجزء الثاني من IP',
  'ip_segment_3': 'الجزء الثالث من IP',
  'ip_segment_4': 'الجزء الرابع من IP',
  'port': 'المنفذ',
  'save': 'حفظ',
  
  // Labs
  'lab_details': 'تفاصيل المعمل',
  'view_sessions': 'عرض الجلسات',
  'teacher': 'المعلم',
  'description': 'الوصف',
  
  // Sessions
  'session_details': 'تفاصيل الجلسة',
  'start_time': 'وقت البدء',
  'end_time': 'وقت الانتهاء',
  'streaming': 'بث مباشر',
  'not_streaming': 'لا يوجد بث',
  'recorded_video': 'فيديو مسجل',
  'no_recorded_video': 'لا يوجد فيديو مسجل',
  
  // Attendance
  'present': 'حاضر',
  'late': 'متأخر',
  'absent': 'غائب',
  'attendance_submitted': 'تم تسجيل الحضور بنجاح',
  'attendance_submit_error': 'فشل تسجيل الحضور',
  
  // Grades
  'score': 'الدرجة',
  'max_score': 'الدرجة الكاملة',
  'percentage': 'النسبة المئوية',
  'comment': 'تعليق',
  
  // Files
  'file_name': 'اسم الملف',
  'file_size': 'حجم الملف',
  'created_at': 'تاريخ الإنشاء',
  'no_files': 'لا توجد ملفات',
  
  // Chat
  'no_messages': 'لا توجد رسائل بعد',
  'chat_history': 'سجل المحادثة',
  
  // General / auth status
  'checking_authentication': 'جارٍ التحقق من المصادقة...',
  
  // Token expiration
  'token_expired': 'انتهت الجلسة',
  'token_refresh_failed': 'فشل تحديث الجلسة. يرجى تسجيل الدخول مرة أخرى.',
  'session_expired_message': 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.',
  'refreshing_token': 'جارٍ تحديث الجلسة...',
};


