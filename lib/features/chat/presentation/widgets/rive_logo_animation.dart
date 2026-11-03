import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;

/// 재사용 가능한 Rive 로고 애니메이션 위젯
class RiveLogoAnimation extends StatefulWidget {
  final String assetPath;
  final double? height;
  final double? width;
  final BoxFit fit;

  const RiveLogoAnimation({
    super.key,
    required this.assetPath,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  State<RiveLogoAnimation> createState() => _RiveLogoAnimationState();
}

class _RiveLogoAnimationState extends State<RiveLogoAnimation> {
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
      debugPrint('Rive 애니메이션 로드 시도: ${widget.assetPath}');
      
      final data = await RiveFile.asset(widget.assetPath);
      final artboard = data.mainArtboard;
      debugPrint('Rive 애니메이션 로드 성공');
      
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
          
          // 입력값 설정 (이미지에서 본 입력들)
          // agz so, agz sa, hvr ic, Boolean 1
          for (final input in controller.inputs) {
            debugPrint('입력 발견: ${input.name} (${input.runtimeType})');
            if (input.name == 'agz so' || input.name == 'agz sa' || input.name == 'hvr ic') {
              if (input is SMIBool) {
                input.value = true;
                debugPrint('${input.name} = true로 설정');
              }
            } else if (input.name == 'Boolean 1') {
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
        debugPrint('Rive 애니메이션 상태 업데이트 완료');
      }
    } catch (e, stackTrace) {
      debugPrint('Rive 애니메이션 로드 오류: $e');
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
    // mounted 체크 및 artboard null 체크 추가 (dispose된 후 build 호출 방지)
    if (!mounted || _riveArtboard == null) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 원형 크기
    final size = widget.height ?? widget.width ?? 150.0;
    // 애니메이션을 더 크게 렌더링하여 확대 효과 (2.0배)
    final animationSize = size * 2.0;
    
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: OverflowBox(
          maxWidth: animationSize,
          maxHeight: animationSize,
          child: Rive(
            artboard: _riveArtboard!,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

