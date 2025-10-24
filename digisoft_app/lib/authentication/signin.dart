import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digisoft_app/services/auth_service.dart';
import 'package:digisoft_app/utils/jwt_decoder.dart';
import 'package:digisoft_app/dashboard/main_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('rememberedEmail');
    final rememberedPassword = prefs.getString('rememberedPassword');
    final shouldRemember = prefs.getBool('shouldRemember') ?? false;

    if (mounted) {
      setState(() {
        if (rememberedEmail != null) {
          emailController.text = rememberedEmail;
        }
        if (rememberedPassword != null && shouldRemember) {
          passwordController.text = rememberedPassword;
        }
        _rememberMe = shouldRemember;
      });
    }

    // Auto-login if token exists and is valid
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty && shouldRemember) {
      _tryAutoLogin(token);
    }
  }

  Future<void> _tryAutoLogin(String token) async {
    try {
      // Verify token is still valid by checking expiration
      final decodedData = decodeJwtPayload(token);
      final exp = decodedData['exp'] ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (exp > currentTime) {
        // Token is still valid, auto-login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Dashboard(userData: decodedData, token: token),
            ),
          );
        }
      } else {
        // Token expired, clear it
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
      }
    } catch (e) {
      print('❌ Auto-login failed: $e');
      // Clear invalid token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
  }

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter both email and password"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService().login(email, password);
      setState(() => isLoading = false);

      if (result['success'] == true && result['token'] != null) {
        final token = result['token'];
        final decodedData = decodeJwtPayload(token);

        print('🔓 DECODED JWT DATA:');
        print('   UserID: ${decodedData['UserID']}');
        print('   CompanyID: ${decodedData['CompanyID']}');
        print('   EmployeeID: ${decodedData['EmployeeID']}');
        print('   UserName: ${decodedData['UserName']}');

        await _saveUserData(decodedData, token);
        await _saveRememberMeCredentials();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Login successful!"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(userData: decodedData, token: token),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid email or password'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      String errorMessage = 'Something went wrong. Please try again.';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

 Future<void> _saveUserData(Map<String, dynamic> userData, String token) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('token', token);
  
  // Save from JWT payload - note the exact key names from your JWT
  await prefs.setInt('employeeID', int.tryParse(userData['EmployeeID']?.toString() ?? '') ?? 0);
  await prefs.setInt('companyID', int.tryParse(userData['CompanyID']?.toString() ?? '') ?? 0);
  await prefs.setString('companyName', userData['CompanyName']?.toString() ?? '');
  await prefs.setString('createdBy', userData['UserName']?.toString() ?? 'hrm');
  await prefs.setString('email', userData['Email']?.toString() ?? '');
  await prefs.setString('GeoFenceID', userData['GeoFenceID']?.toString() ?? '');
  
  // ✅ ADD THIS LINE to save EmployeeThumbnail
  await prefs.setString('employeeThumbnail', userData['EmployeeThumbnail']?.toString() ?? '');

  // Debug print to verify data is saved
  print('💾 SAVED USER DATA TO SHARED PREFERENCES:');
  print('   EmployeeID: ${prefs.getInt('employeeID')}');
  print('   CompanyID: ${prefs.getInt('companyID')}');
  print('   CompanyName: ${prefs.getString('companyName')}');
  print('   CreatedBy: ${prefs.getString('createdBy')}');
  print('   Email: ${prefs.getString('email')}');
  print('   EmployeeThumbnail: ${prefs.getString('employeeThumbnail')}'); 
  print('   Token length: ${prefs.getString('token')?.length}');
  print('GeoFenceID: ${prefs.getString('GeoFenceID')}');
}

  Future<void> _saveRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_rememberMe) {
      // Save credentials for auto-login
      await prefs.setString('rememberedEmail', emailController.text.trim());
      await prefs.setString('rememberedPassword', passwordController.text.trim());
      await prefs.setBool('shouldRemember', true);
      print('💾 Remember Me: Credentials saved');
    } else {
      // Clear saved credentials
      await prefs.remove('rememberedEmail');
      await prefs.remove('rememberedPassword');
      await prefs.setBool('shouldRemember', false);
      print('💾 Remember Me: Credentials cleared');
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleRememberMe() {
    setState(() {
      _rememberMe = !_rememberMe;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Welcome Back',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.inputDecorationTheme.labelStyle?.color,
                    ),
                    border: theme.inputDecorationTheme.border,
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: theme.inputDecorationTheme.filled,
                    fillColor: theme.inputDecorationTheme.fillColor,
                    contentPadding: theme.inputDecorationTheme.contentPadding,
                    labelStyle: theme.inputDecorationTheme.labelStyle,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.inputDecorationTheme.labelStyle?.color,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: theme.inputDecorationTheme.labelStyle?.color,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                    border: theme.inputDecorationTheme.border,
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: theme.inputDecorationTheme.filled,
                    fillColor: theme.inputDecorationTheme.fillColor,
                    contentPadding: theme.inputDecorationTheme.contentPadding,
                    labelStyle: theme.inputDecorationTheme.labelStyle,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember Me Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            _toggleRememberMe();
                          },
                          activeColor: colorScheme.primary,
                        ),
                        Text(
                          'Remember me',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    
                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Forgot password feature coming soon!'),
                            backgroundColor: colorScheme.primary,
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: theme.textButtonTheme.style?.textStyle?.resolve({}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.disabled)) {
                            return colorScheme.primary.withOpacity(0.5);
                          }
                          return colorScheme.primary;
                        },
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: theme.elevatedButtonTheme.style?.textStyle?.resolve({})?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
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