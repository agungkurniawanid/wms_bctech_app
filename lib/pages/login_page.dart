// todo:✅ Clean Code checked
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_bctech/constants/app_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/controllers/auth_controller.dart';
import 'package:wms_bctech/controllers/firebase_controller.dart';
import 'package:wms_bctech/widgets/button_widget.dart';
import 'package:wms_bctech/widgets/text_field_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _usernameFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final FirebaseController _firebaseController = FirebaseController();
  final NewAuthController _authController = NewAuthController();

  String _username = '', _password = '', token = '';

  @override
  void initState() {
    super.initState();
    _firebaseController.initializeFirebaseMessaging();
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [hijauGojek, Colors.white],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(29.0),
                      child: Column(
                        children: [
                          Image.asset('data/images/bc-tech-logo.png'),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(
                              'IM MOBILE',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: hijauGojek,
                              ),
                            ),

                            const SizedBox(height: 20),
                            TextFieldWidget(
                              fieldKey: _usernameFieldKey,
                              keyboardType: TextInputType.text,
                              isPasswordField: false,
                              prefixIcon: const Icon(Icons.person),
                              labelText: 'Username',
                              validator: (input) => input?.isEmpty == true
                                  ? 'Username tidak boleh kosong'
                                  : null,
                              onSaved: (input) => _username = input ?? '',
                            ),

                            const SizedBox(height: 10),
                            TextFieldWidget(
                              fieldKey: _passwordFieldKey,
                              isPasswordField: true,
                              prefixIcon: const Icon(Icons.lock),
                              labelText: 'Password',
                              validator: (input) => input?.isEmpty == true
                                  ? 'Password tidak boleh kosong'
                                  : null,
                              onSaved: (input) => _password = input ?? '',
                            ),

                            const SizedBox(height: 20),
                            BtnWidget(
                              backgroundColor: hijauGojek,
                              onPressed: () {
                                if (_formKey.currentState?.validate() == true) {
                                  _formKey.currentState?.save();
                                  _authController.loginFunction(
                                    _username,
                                    _password,
                                    context,
                                  );
                                }
                              },
                              buttonText: 'LOGIN',
                            ),

                            const SizedBox(height: 20),
                            Text(
                              AppConstants.appVersion,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
