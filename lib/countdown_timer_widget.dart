import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class CountdownTimerWidget extends StatefulWidget {
  final String startTime; // Example format: 'Nov 9, 2024 3:45 AM'

  const CountdownTimerWidget({Key? key, required this.startTime}) : super(key: key);

  @override
  _CountdownTimerWidgetState createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late DateTime startDateTime;
  late DateTime endDateTime;
  Duration remainingTime = Duration.zero;
  Timer? _timer;
  bool isExpired = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  void _initializeTimer() {
    // Parse the start time
    try {
      startDateTime = DateFormat("MMM d, yyyy h:mm a").parse(widget.startTime);

      // Calculate the end time by adding 20 minutes
      endDateTime = startDateTime.add(const Duration(minutes: 20));

      // Start the countdown
      _startCountdown();
    } catch (e) {
      print("Error parsing date: $e");
      setState(() {
        isExpired = true; // If parsing fails, mark as expired
      });
    }
  }

  void _startCountdown() {
    // Check if the time has already expired
    if (DateTime.now().isAfter(endDateTime)) {
      setState(() {
        isExpired = true;
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime = endDateTime.difference(DateTime.now());

        // Check if the time has expired
        if (remainingTime.isNegative) {
          isExpired = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isExpired
            ? "Expired"
            : "${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')} remaining",
        
      ),
    );
  }
}
