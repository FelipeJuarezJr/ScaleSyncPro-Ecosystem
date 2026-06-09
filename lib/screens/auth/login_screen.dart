import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../utils/theme.dart';
import '../main_app_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isRememberMe = false;
  bool _isLoading = false;
  
  // Focus and hover states
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isEmailHovered = false;
  bool _isPasswordHovered = false;
  bool _isSignInHovered = false;
  bool _isGoogleButtonAnimating = false;

  // Animation controllers
  late AnimationController _emailAnimationController;
  late AnimationController _passwordAnimationController;
  late AnimationController _signInAnimationController;
  late AnimationController _googleButtonAnimationController;
  late Animation<double> _emailBorderAnimation;
  late Animation<double> _passwordBorderAnimation;
  late Animation<double> _emailShadowAnimation;
  late Animation<double> _passwordShadowAnimation;
  late Animation<double> _signInColorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Email animations
    _emailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _emailBorderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emailAnimationController,
      curve: Curves.easeInOut,
    ));
    _emailShadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emailAnimationController,
      curve: Curves.easeInOut,
    ));

    // Password animations
    _passwordAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _passwordBorderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _passwordAnimationController,
      curve: Curves.easeInOut,
    ));
    _passwordShadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _passwordAnimationController,
      curve: Curves.easeInOut,
    ));

    // Sign In button animations
    _signInAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _signInColorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _signInAnimationController,
      curve: Curves.easeInOut,
    ));

    // Google button animation
    _googleButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailAnimationController.dispose();
    _passwordAnimationController.dispose();
    _signInAnimationController.dispose();
    _googleButtonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Navigate directly to dashboard on successful sign in
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainAppScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();

      // Navigate directly to dashboard on successful Google sign in
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainAppScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Google sign in failed';
        
        // Provide more user-friendly error messages
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('sign_in_failed')) {
          errorMessage = 'Sign in failed. Please try again.';
        } else if (e.toString().contains('popup')) {
          errorMessage = 'Popup was blocked. Please allow popups for this site.';
        } else if (e.toString().contains('People API') || e.toString().contains('SERVICE_DISABLED')) {
          errorMessage = 'Google Sign-In requires People API to be enabled. Please contact administrator.';
          if (kDebugMode) {
            print('People API not enabled. Enable at: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=373955522567');
          }
        } else {
          errorMessage = 'Google sign in failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getBorderColor(bool isFocused, bool isHovered) {
    if (isFocused) {
      return const Color(0xFF00FF00); // Green on focus
    } else if (isHovered) {
      return const Color(0xFF00FF00); // Green on hover
    }
    return AppTheme.borderColor; // Default border color
  }

  Color _getSignInButtonColor() {
    if (_isSignInHovered) {
      return Color.lerp(AppTheme.primaryColor, AppTheme.primaryLight, _signInColorAnimation.value)!;
    }
    return AppTheme.primaryColor; // Default green color
  }

  void _handleEmailHover(bool isHovered) {
    setState(() => _isEmailHovered = isHovered);
    if (isHovered) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isEmailHovered) {
          _emailAnimationController.forward();
        }
      });
    } else {
      _emailAnimationController.reverse();
    }
  }

  void _handlePasswordHover(bool isHovered) {
    setState(() => _isPasswordHovered = isHovered);
    if (isHovered) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isPasswordHovered) {
          _passwordAnimationController.forward();
        }
      });
    } else {
      _passwordAnimationController.reverse();
    }
  }

  void _handleEmailFocus(bool hasFocus) {
    setState(() => _isEmailFocused = hasFocus);
    if (hasFocus) {
      _emailAnimationController.forward();
    } else if (!_isEmailHovered) {
      _emailAnimationController.reverse();
    }
  }

  void _handlePasswordFocus(bool hasFocus) {
    setState(() => _isPasswordFocused = hasFocus);
    if (hasFocus) {
      _passwordAnimationController.forward();
    } else if (!_isPasswordHovered) {
      _passwordAnimationController.reverse();
    }
  }

  void _handleSignInHover(bool isHovered) {
    setState(() => _isSignInHovered = isHovered);
    if (isHovered) {
      _signInAnimationController.forward();
    } else {
      _signInAnimationController.reverse();
    }
  }

  void _startGoogleButtonAnimation() {
    if (!_isGoogleButtonAnimating) {
      setState(() => _isGoogleButtonAnimating = true);
      _googleButtonAnimationController.forward().then((_) {
        setState(() => _isGoogleButtonAnimating = false);
        _googleButtonAnimationController.reset();
      });
    }
  }

  Color _getGoogleButtonColor() {
    if (!_isGoogleButtonAnimating) {
      return AppTheme.bgPrimary;
    }
    
    final progress = _googleButtonAnimationController.value;
    
    // Define the color sequence
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.yellow,
      Colors.green,
      AppTheme.bgPrimary, // Return to original color
    ];
    
    // Calculate which color pair we're between
    final colorIndex = (progress * (colors.length - 1)).floor();
    final nextColorIndex = (colorIndex + 1).clamp(0, colors.length - 1);
    
    // Calculate the interpolation factor within the current color pair
    final localProgress = (progress * (colors.length - 1)) - colorIndex;
    
    // Smoothly interpolate between the two colors
    return Color.lerp(
      colors[colorIndex],
      colors[nextColorIndex],
      localProgress,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDarkMode = themeService.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    
    // Responsive button height
    final buttonHeight = isMobile ? 48.0 : 36.0;
    final buttonFontSize = isMobile ? 14.0 : 16.0;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  elevation: 20,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.bgPrimary, AppTheme.bgSecondary],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Auth Header
                          Column(
                            children: [
                              // Brand
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.drag_indicator,
                                    size: 44,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'ScaleSyncPro',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Title
                              Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sign in to manage your reptile collection',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Email Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MouseRegion(
                                onEnter: (_) => _handleEmailHover(true),
                                onExit: (_) => _handleEmailHover(false),
                                child: Focus(
                                  onFocusChange: _handleEmailFocus,
                                  child: AnimatedBuilder(
                                    animation: _emailAnimationController,
                                    builder: (context, child) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _getBorderColor(_isEmailFocused, _isEmailHovered),
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                          color: AppTheme.bgPrimary,
                                        ),
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your email',
                                            hintStyle: TextStyle(
                                              color: AppTheme.textLight,
                                              fontSize: 16,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: AppTheme.textLight,
                                              size: 18,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            filled: true,
                                            fillColor: Colors.transparent,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MouseRegion(
                                onEnter: (_) => _handlePasswordHover(true),
                                onExit: (_) => _handlePasswordHover(false),
                                child: Focus(
                                  onFocusChange: _handlePasswordFocus,
                                  child: AnimatedBuilder(
                                    animation: _passwordAnimationController,
                                    builder: (context, child) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _getBorderColor(_isPasswordFocused, _isPasswordHovered),
                                            width: 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                          color: AppTheme.bgPrimary,
                                        ),
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: !_isPasswordVisible,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your password',
                                            hintStyle: TextStyle(
                                              color: AppTheme.textLight,
                                              fontSize: 16,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outlined,
                                              color: AppTheme.textLight,
                                              size: 18,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isPasswordVisible 
                                                  ? Icons.visibility_off 
                                                  : Icons.visibility,
                                                color: AppTheme.textLight,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordVisible = !_isPasswordVisible;
                                                });
                                              },
                                              style: IconButton.styleFrom(
                                                padding: const EdgeInsets.all(8),
                                                minimumSize: const Size(32, 32),
                                              ),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            filled: true,
                                            fillColor: Colors.transparent,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Custom Checkbox
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isRememberMe = !_isRememberMe;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _isRememberMe 
                                            ? AppTheme.primaryColor 
                                            : AppTheme.borderColor,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: _isRememberMe 
                                          ? AppTheme.primaryColor 
                                          : Colors.transparent,
                                      ),
                                      child: _isRememberMe
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          )
                                        : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password
                                },
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Sign In Button
                          MouseRegion(
                            onEnter: (_) => _handleSignInHover(true),
                            onExit: (_) => _handleSignInHover(false),
                            child: AnimatedBuilder(
                              animation: _signInAnimationController,
                              builder: (context, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _getSignInButtonColor(),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.login, size: 18, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: buttonFontSize,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgPrimary,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppTheme.borderColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Social Sign In Buttons
                          MouseRegion(
                            onEnter: (_) => _startGoogleButtonAnimation(),
                            child: AnimatedBuilder(
                              animation: _googleButtonAnimationController,
                              builder: (context, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _signInWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppTheme.borderColor),
                                      backgroundColor: _getGoogleButtonColor(),
                                      foregroundColor: AppTheme.textPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                      ),
                                    ),
                                    icon: _isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                                            ),
                                          )
                                        : const Icon(Icons.g_mobiledata, size: 18),
                                    label: Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 