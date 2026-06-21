import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'package:scalesync_pro_ecosystem/screens/auth/register_screen.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncSocial/views/social_feed_view.dart';

class SocialLoginView extends StatefulWidget {
  const SocialLoginView({super.key});

  @override
  State<SocialLoginView> createState() => _SocialLoginViewState();
}

class _SocialLoginViewState extends State<SocialLoginView> with TickerProviderStateMixin {
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
  late Animation<double> _signInColorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Email animations
    _emailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Password animations
    _passwordAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back to ScaleSync Social!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SocialFeedView()),
          );
        }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back to ScaleSync Social!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SocialFeedView()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString();
        String errorMessage;

        if (err.contains('unauthorized-domain') || err.contains('auth/unauthorized-domain')) {
          errorMessage = 'This domain is not authorized for Google Sign-In. Contact support.';
        } else if (err.contains('cancelled-popup-request') || err.contains('popup-closed-by-user')) {
          errorMessage = 'Sign-in cancelled. Please try again.';
          setState(() { _isLoading = false; });
          return;
        } else if (err.contains('popup-blocked') || err.contains('popup')) {
          errorMessage = 'Popup was blocked. Please allow popups for this site.';
        } else if (err.contains('network-request-failed') || err.contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (err.contains('sign_in_failed')) {
          errorMessage = 'Sign in failed. Please try again.';
        } else if (err.contains('People API') || err.contains('SERVICE_DISABLED')) {
          errorMessage = 'Google Sign-In requires People API to be enabled. Contact administrator.';
        } else {
          errorMessage = 'Google sign in failed: $err';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 5),
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
    
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.yellow,
      Colors.green,
      AppTheme.bgPrimary,
    ];
    
    final colorIndex = (progress * (colors.length - 1)).floor();
    final nextColorIndex = (colorIndex + 1).clamp(0, colors.length - 1);
    final localProgress = (progress * (colors.length - 1)) - colorIndex;
    
    return Color.lerp(
      colors[colorIndex],
      colors[nextColorIndex],
      localProgress,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    
    final buttonHeight = isMobile ? 48.0 : 36.0;
    final buttonFontSize = isMobile ? 14.0 : 16.0;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Stack(
        children: [
          // Background solid dark
          Container(
            color: AppTheme.bgPrimary,
          ),
          
          // Glowing Orb 1 (Center-Left)
          Positioned(
            top: 120,
            left: -180,
            child: Container(
              width: 450,
              height: 450,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x2000D2FF), // AppTheme.primaryLight (cyan) with ~12% opacity
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Glowing Orb 2 (Top-Right)
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x2000E676), // AppTheme.primaryColor (green) with ~12% opacity
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Social Node 1 (Share Node - Top-Left)
          Positioned(
            top: 100,
            left: 100,
            child: Icon(
              Icons.share_outlined,
              color: AppTheme.primaryLight.withValues(alpha: 0.12),
              size: 44,
            ),
          ),

          // Social Node 2 (People Node - Top-Right)
          Positioned(
            top: 240,
            right: 120,
            child: Icon(
              Icons.people_outline,
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              size: 60,
            ),
          ),

          // Social Node 3 (Like Node - Bottom-Left)
          Positioned(
            bottom: 180,
            left: 80,
            child: Icon(
              Icons.thumb_up_outlined,
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
              size: 38,
            ),
          ),

          // Social Node 4 (Chat Node - Bottom-Right)
          Positioned(
            bottom: 120,
            right: 80,
            child: Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
              size: 52,
            ),
          ),
          
          // Content
          SafeArea(
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                            border: Border.all(
                              color: AppTheme.borderColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Auth Header
                          const Column(
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
                                  SizedBox(width: 10),
                                  Text(
                                    'ScaleSync Social',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
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
                              SizedBox(height: 10),
                              Text(
                                'Sign in to join the community and share updates',
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
                              const Text(
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
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: const InputDecoration(
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
                                            contentPadding: EdgeInsets.symmetric(
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
                              const Text(
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
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your password',
                                            hintStyle: const TextStyle(
                                              color: AppTheme.textLight,
                                              fontSize: 16,
                                            ),
                                            prefixIcon: const Icon(
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
                                    const Text(
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
                                child: const Text(
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
                                decoration: const BoxDecoration(
                                  color: AppTheme.bgPrimary,
                                ),
                                child: const Text(
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
                                      side: const BorderSide(color: AppTheme.borderColor),
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
                              const Text(
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
                                child: const Text(
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
    ),
  ],
),
);
  }
}
