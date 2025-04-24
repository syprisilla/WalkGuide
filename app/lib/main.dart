import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

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
  int _steps = 0;
  int? _initialSteps;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    requestPermission(); // 권한 요청 먼저
  }

  Future<void> requestPermission() async {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      await Permission.activityRecognition.request();
    }


    startPedometer();
  }

  void startPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);
    _startTime = DateTime.now();
  }

  void onStepCount(StepCount event) {
    debugPrint("걸음 수 이벤트 발생: ${event.steps}");

    _initialSteps ??= event.steps;

    setState(() {
      _steps = event.steps - _initialSteps!;
    });
  }

  void onStepCountError(error) {
    debugPrint('걸음 수 측정 오류: $error');
  }

  double getSpeed() {
    if (_startTime == null || _steps == 0) return 0;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration == 0) return 0;
    double stepLength = 0.7; // 평균 보폭
    double distance = _steps * stepLength;
    return distance / duration; // m/s
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
}
