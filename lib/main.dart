import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color brandGreen = Color(0xFF188653);
const String whatsappNumber = '967778777643';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ytdihxsnpklplytvrft.supabase.co',
    anonKey: 'sb_publishable_mI0C1H9xxd-ycsbVZR2G9A_JbEf0Yyk',
  );

  runApp(const AlShaalanApp());
}

class AlShaalanApp extends StatelessWidget {
  const AlShaalanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وكالة الشعلان',
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brandGreen),
        appBarTheme: const AppBarTheme(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<void> sendWhatsApp(String message) async {
  final uri = Uri.parse(
    'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
  );

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('تعذر فتح واتساب');
  }
}

String newOrderNumber() {
  return 'SH-${DateTime.now().millisecondsSinceEpoch}';
}

String errorText(Object error) {
  if (error is PostgrestException) {
    return error.message;
  }
  if (error is AuthException) {
    return error.message;
  }
  return 'حدث خطأ. تحقق من الإنترنت وحاول مرة أخرى.';
}

// التحقق من جلسة المستخدم
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession == null) {
          return const AuthScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

// تسجيل الدخول وإنشاء الحساب
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegister = false;
  bool loading = false;
  bool hidePassword = true;

  Future<void> submit() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage(context, 'أدخل البريد الإلكتروني وكلمة المرور');
      return;
    }

    if (isRegister && (name.isEmpty || phone.isEmpty)) {
      showMessage(context, 'أدخل الاسم ورقم الهاتف');
      return;
    }

    if (password.length < 6) {
      showMessage(context, 'كلمة المرور يجب ألا تقل عن 6 أحرف');
      return;
    }

    setState(() => loading = true);

    try {
      if (isRegister) {
        final result = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
            'phone': phone,
          },
        );

        if (!mounted) return;

        if (result.session == null) {
          showMessage(
            context,
            'تم إنشاء الحساب. أكّد بريدك الإلكتروني ثم سجّل الدخول.',
          );
          setState(() => isRegister = false);
          return;
        }

        await ensureCustomerProfile(name: name, phone: phone);

        if (!mounted) return;
        showMessage(context, 'تم إنشاء الحساب بنجاح');
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        await ensureCustomerProfile();

        if (!mounted) return;
        showMessage(context, 'تم تسجيل الدخول بنجاح');
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وكالة الشعلان - حساب المستخدم')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_bus,
                  size: 65,
                  color: brandGreen,
                ),
                const SizedBox(height: 12),
                Text(
                  isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (isRegister) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => hidePassword = !hidePassword);
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const CircularProgressIndicator()
                        : Text(isRegister ? 'إنشاء الحساب' : 'دخول'),
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => setState(() => isRegister = !isRegister),
                  child: Text(
                    isRegister
                        ? 'لدي حساب بالفعل - تسجيل الدخول'
                        : 'ليس لدي حساب - إنشاء حساب جديد',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// إنشاء سجل العميل وربطه بحسابه
Future<void> ensureCustomerProfile({
  String? name,
  String? phone,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

  final existing = await supabase
      .from('customers')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (existing != null) return;

  final metadata = user.userMetadata ?? {};
  final fullName = (name ?? metadata['full_name'] ?? '').toString().trim();
  final userPhone = (phone ?? metadata['phone'] ?? '').toString().trim();

  if (fullName.isEmpty || userPhone.isEmpty) {
    throw Exception(
      'تعذر العثور على اسمك ورقم هاتفك. تواصل مع الإدارة لإكمال بيانات الحساب.',
    );
  }

  await supabase.from('customers').insert({
    'user_id': user.id,
    'full_name': fullName,
    'phone': userPhone,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      ('قطع تذاكر البر', Icons.directions_bus, 'road_ticket'),
      ('قطع الجوازات', Icons.menu_book, 'passport'),
      ('العمرة', Icons.mosque, 'umrah'),
      ('الحج', Icons.flight_takeoff, 'hajj'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('وكالة الشعلان للسفريات'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF126342), Color(0xFF239B66)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وكالة الشعلان للسفريات والسياحة وخدمات الحج والعمرة',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'مع الشعلان ثقة والتزام',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 5),
                Text(
                  'صنعاء - شارع تعز، أمام بريد شميلة، جوار جامع الخير',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceRequestScreen(
                        title: service.$1,
                        serviceType: service.$3,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(service.$2, color: brandGreen, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        service.$1,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('طلباتي'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminGate()),
            ),
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('لوحة الإدارة'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await sendWhatsApp(
                  'السلام عليكم، أريد الاستفسار عن خدمات وكالة الشعلان.',
                );
              } catch (e) {
                if (context.mounted) showMessage(context, errorText(e));
              }
            },
            icon: const Icon(Icons.chat),
            label: const Text('تواصل واتساب'),
          ),
        ],
      ),
    );
  }
}

// نموذج موحد لحفظ الطلبات حسب أعمدة قاعدة البيانات الحالية
class ServiceRequestScreen extends StatefulWidget {
  final String title;
  final String serviceType;

  const ServiceRequestScreen({
    super.key,
    required this.title,
    required this.serviceType,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();

  DateTime? travelDate;
  int persons = 1;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final metadata = supabase.auth.currentUser?.userMetadata ?? {};
    nameController.text = (metadata['full_name'] ?? '').toString();
    phoneController.text = (metadata['phone'] ?? '').toString();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      showMessage(context, 'أدخل الاسم ورقم الهاتف');
      return;
    }

    if (persons < 1) {
      showMessage(context, 'عدد الأشخاص يجب أن يكون واحداً على الأقل');
      return;
    }

    setState(() => loading = true);

    try {
      await ensureCustomerProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );

      final user = supabase.auth.currentUser!;

      final customer = await supabase
          .from('customers')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final orderNumber = newOrderNumber();

      await supabase.from('orders').insert({
        'order_number': orderNumber,
        'customer_id': customer['id'],
        'order_type': widget.serviceType,
        'service_name': widget.title,
        'status': 'new',
        'travel_date': travelDate == null
            ? null
            : '${travelDate!.year.toString().padLeft(4, '0')}-'
              '${travelDate!.month.toString().padLeft(2, '0')}-'
              '${travelDate!.day.toString().padLeft(2, '0')}',
        'persons': persons,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      });

      if (!mounted) return;
      showMessage(context, 'تم إرسال طلبك بنجاح: $orderNumber');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'اسم صاحب الطلب',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey),
            ),
            title: Text(
              travelDate == null
                  ? 'اختر تاريخ السفر (اختياري)'
                  : '${travelDate!.year}-${travelDate!.month}-${travelDate!.day}',
            ),
            trailing: const Icon(Icons.date_range),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime(2035),
                initialDate: DateTime.now(),
              );
              if (date != null) setState(() => travelDate = date);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: persons,
            decoration: const InputDecoration(
              labelText: 'عدد الأشخاص',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              20,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text('${i + 1}'),
              ),
            ),
            onChanged: (value) {
              if (value != null) setState(() => persons = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظات أو تفاصيل الطلب (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: loading ? null : submit,
            child: loading
                ? const CircularProgressIndicator()
                : const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
  }
}

// عرض طلبات المستخدم الحالي
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> ordersFuture;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void loadOrders() {
    ordersFuture = _fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final customer = await supabase
        .from('customers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (customer == null) return [];

    final result = await supabase
        .from('orders')
        .select()
        .eq('customer_id', customer['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> deleteOrder(String id) async {
    try {
      await supabase.from('orders').delete().eq('id', id);
      if (!mounted) return;
      showMessage(context, 'تم حذف الطلب');
      setState(loadOrders);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('تعذر تحميل الطلبات: ${errorText(snapshot.error!)}'),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('لا توجد طلبات حتى الآن'));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(loadOrders),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      '${order['service_name'] ?? 'طلب خدمة'}',
                    ),
                    subtitle: Text(
                      'رقم الطلب: ${order['order_number'] ?? ''}\n'
                      'الحالة: ${order['status'] ?? 'new'}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('تأكيد الحذف'),
                            content: const Text(
                              'هل تريد حذف هذا الطلب؟',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('حذف'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await deleteOrder(order['id'].toString());
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// لا يسمح بدخول لوحة الإدارة إلا لمن له دور admin في قاعدة البيانات
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late Future<bool> adminFuture;

  @override
  void initState() {
    super.initState();
    adminFuture = checkAdmin();
  }

  Future<bool> checkAdmin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final result = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    return result?['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: adminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('صلاحيات الدخول')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'عذراً، هذه الصفحة مخصصة لمدير الوكالة فقط.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const AdminDashboard();
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      '1- الأسعار',
      '2- الشركات',
      '3- مدن المغادرة',
      '4- الوجهات',
      '5- المقاعد',
      '6- الجوازات',
      '7- الحج والعمرة',
      '8- الطلبات',
      '9- المدراء',
      '10- الواتساب',
      '11- العملاء',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة - 11 تبويب'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tabs.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            title: Text(tabs[index]),
            leading: const Icon(Icons.settings),
            subtitle: const Text('واجهة التبويب قيد التطوير'),
          ),
        ),
      ),
    );
  }
}