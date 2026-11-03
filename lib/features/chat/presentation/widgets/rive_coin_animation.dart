import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;

/// 동전 떨어지는 애니메이션을 위한 Rive 위젯
class RiveCoinAnimation extends StatefulWidget {
  final String assetPath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Alignment alignment;

  const RiveCoinAnimation({
    super.key,
    required this.assetPath,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  State<RiveCoinAnimation> createState() => _RiveCoinAnimationState();
}

class _RiveCoinAnimationState extends State<RiveCoinAnimation> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;

  @override
  void initState() {
    super.initState();
    _loadRiveAnimation();
  }

  /// Rive 애니메이션 로드
  void _loadRiveAnimation() async {
    try {
      debugPrint('Rive 동전 애니메이션 로드 시도: ${widget.assetPath}');
      
      final data = await RiveFile.asset(widget.assetPath);
      final artboard = data.mainArtboard;
      debugPrint('Rive 동전 애니메이션 로드 성공');
      
      // State Machine이 있는지 확인
      StateMachineController? controller;
      if (artboard.stateMachines.isNotEmpty) {
        debugPrint('State Machine 발견: ${artboard.stateMachines.first.name}');
        controller = StateMachineController.fromArtboard(
          artboard,
          artboard.stateMachines.first.name,
        );
        if (controller != null) {
          artboard.addController(controller);
          debugPrint('State Machine Controller 추가됨');
          
          // 동전 애니메이션 입력값 설정
          for (final input in controller.inputs) {
            debugPrint('입력 발견: ${input.name} (${input.runtimeType})');
            // 동전 애니메이션 트리거 입력 처리
            // trigger, play, start 등의 이름을 가진 입력을 활성화
            if (input.name.toLowerCase().contains('trigger') || 
                input.name.toLowerCase().contains('play') ||
                input.name.toLowerCase().contains('start')) {
              if (input is SMIBool) {
                input.value = true;
                debugPrint('${input.name} = true로 설정');
              }
            }
          }
        }
      } else {
        debugPrint('State Machine이 없습니다. SimpleAnimation 사용');
      }
      
      if (mounted) {
        setState(() {
          _riveArtboard = artboard;
          _controller = controller;
        });
        debugPrint('Rive 동전 애니메이션 상태 업데이트 완료');
      }
    } catch (e, stackTrace) {
      debugPrint('Rive 동전 애니메이션 로드 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _riveArtboard = null; // dispose 후 렌더링 방지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // mounted 체크 추가 (dispose된 후 build 호출 방지)
    if (!mounted || _riveArtboard == null) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Align(
        alignment: widget.alignment,
        child: Rive(
          artboard: _riveArtboard!,
          fit: widget.fit,
        ),
      ),
    );
  }
}

