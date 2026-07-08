import 'package:flutter/material.dart';

class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final double beginScale = 0.95;
            final double endScale = 1.0;

            final scaleAnimation = Tween<double>(
              begin: beginScale,
              end: endScale,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            );

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeIn,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({required this.page, this.direction = AxisDirection.left})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset beginOffset;
            switch (direction) {
              case AxisDirection.left:
                beginOffset = const Offset(1.0, 0.0);
                break;
              case AxisDirection.right:
                beginOffset = const Offset(-1.0, 0.0);
                break;
              case AxisDirection.up:
                beginOffset = const Offset(0.0, 1.0);
                break;
              case AxisDirection.down:
                beginOffset = const Offset(0.0, -1.0);
                break;
            }

            final slideAnimation = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            );

            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
        );
}
