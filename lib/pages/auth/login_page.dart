import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:wms_bctech/constants/app_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/auth/auth_controller.dart';
import 'package:wms_bctech/controllers/firebase_controller.dart';
import 'package:wms_bctech/components/button_widget.dart';
import 'package:wms_bctech/components/text_field_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final FirebaseController _firebaseController = FirebaseController();
  final NewAuthController _authController = NewAuthController();

  final List<Map<String, String>> _divisions = [
    {
      'name': 'PT Bina Cipta Technology',
      'logo': 'data/images/bc-tech-logo.png',
    },
    {'name': 'PT BISI International Tbk', 'logo': 'assets/icons/bisi.png'},
    {'name': 'PT Multi Sarana Indotani', 'logo': 'assets/icons/msi.png'},
    {'name': 'PT Tanindo Intertraco', 'logo': 'assets/icons/tanindo.png'},
  ];

  String _email = '', _password = '', token = '';
  String? _selectedDivision;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _firebaseController.initializeFirebaseMessaging();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
            systemStatusBarContrastEnforced: false,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hijauGojek,
                  hijauGojek.withValues(alpha: 0.8),
                  Colors.white,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(30),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: hijauGojek.withValues(alpha: 0.2),
                              spreadRadius: 0,
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildLogoContainer(
                                      'data/images/bc-tech-logo.png',
                                    ),
                                    _buildLogoDivider(),
                                    _buildLogoContainer(
                                      'assets/icons/bisi.png',
                                    ),
                                    _buildLogoDivider(),
                                    _buildLogoContainer('assets/icons/msi.png'),
                                    _buildLogoDivider(),
                                    _buildLogoContainer(
                                      'assets/icons/tanindo.png',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    hijauGojek,
                                    hijauGojek.withValues(alpha: 0.7),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'IM MOBILE',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Warehouse Management System',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 60,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      hijauGojek.withValues(alpha: 0.3),
                                      hijauGojek,
                                      hijauGojek.withValues(alpha: 0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 35),
                              _buildFieldLabel('Division'),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedDivision,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.business_outlined,
                                      color: hijauGojek,
                                      size: 22,
                                    ),
                                    hintText: 'Select your division',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: hijauGojek,
                                  ),
                                  dropdownColor: Colors.white,
                                  isExpanded: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a division';
                                    }
                                    return null;
                                  },
                                  items: _divisions.map((division) {
                                    return DropdownMenuItem<String>(
                                      value: division['name'],
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Image.asset(
                                              division['logo']!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              division['name']!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDivision = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildFieldLabel('Email Address'),
                              const SizedBox(height: 8),
                              TextFieldWidget(
                                fieldKey: _emailFieldKey,
                                keyboardType: TextInputType.emailAddress,
                                isPasswordField: false,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: hijauGojek,
                                ),
                                labelText: 'Enter your email',
                                validator: (input) => input?.isEmpty == true
                                    ? 'Email tidak boleh kosong'
                                    : null,
                                onSaved: (input) => _email = input ?? '',
                              ),
                              const SizedBox(height: 10),
                              _buildFieldLabel('Password'),
                              const SizedBox(height: 8),
                              TextFieldWidget(
                                fieldKey: _passwordFieldKey,
                                isPasswordField: true,
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: hijauGojek,
                                ),
                                labelText: 'Enter your password',
                                validator: (input) => input?.isEmpty == true
                                    ? 'Password tidak boleh kosong'
                                    : null,
                                onSaved: (input) => _password = input ?? '',
                              ),
                              const SizedBox(height: 35),
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      hijauGojek,
                                      hijauGojek.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: hijauGojek.withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: BtnWidget(
                                  backgroundColor: Colors.transparent,
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ==
                                        true) {
                                      _formKey.currentState?.save();
                                      _authController.loginFunction(
                                        _email,
                                        _password,
                                        context,
                                      );
                                      Logger().i(
                                        'Selected Division: $_selectedDivision',
                                      );
                                    }
                                  },
                                  buttonText: 'LOGIN',
                                ),
                              ),
                              const SizedBox(height: 25),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppConstants.appVersion,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoContainer(String assetPath) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          assetPath,
          height: 50,
          width: 60,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildLogoDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
