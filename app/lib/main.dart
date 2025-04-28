import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StepCounterPage(),
    );
  }
}

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});
  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  late Stream<StepCount> _stepCountStream;
  StreamSubscription<StepCount>? _stepCountSubscription;
  Timer? _checkTimer;
  int _steps = 0;
  int? _initialSteps;
  DateTime? _startTime;
  DateTime? _lastStepTime;

  @override
  void initState() {
    super.initState();
    requestPermission();
    startCheckingMovement();
  }

  Future<void> requestPermission() async {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
    }

    if (status.isGranted) {
      startPedometer();
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('권한 필요'),
            content: const Text('걸음 측정을 위해 권한이 필요합니다. 설정에서 권한을 허용해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }

  void startPedometer() {
    _stepCountSubscription?.cancel();

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream.listen(
      onStepCount,
      onError: onStepCountError,
      cancelOnError: true,
    );
    _startTime = DateTime.now();
    _lastStepTime = DateTime.now();
  }

  void onStepCount(StepCount event) {
    debugPrint("걸음 수 이벤트 발생: ${event.steps}");

    _initialSteps ??= event.steps;

    setState(() {
      _steps = event.steps - _initialSteps!;
      _lastStepTime = DateTime.now();
    });
  }

  void onStepCountError(error) {
    debugPrint('걸음 수 측정 오류: $error');
    Future.delayed(const Duration(seconds: 2), () {
      debugPrint('걸음 측정 재시도');
      startPedometer();
    });
  }

  double getSpeed() {
    if (_startTime == null || _steps == 0) return 0;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration == 0) return 0;
    double stepLength = 0.7;
    double distance = _steps * stepLength;
    return distance / duration;
  }

  void startCheckingMovement() {
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lastStepTime != null) {
        final diff = DateTime.now().difference(_lastStepTime!).inSeconds;
        if (diff >= 3) {

          setState(() {
            _steps = 0;
            _startTime = DateTime.now();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('걸음 속도 측정')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('걸음 수: $_steps'),
            Text('추정 속도: ${getSpeed().toStringAsFixed(2)} m/s'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }
}
