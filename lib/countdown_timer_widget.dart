import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class CountdownTimerWidget extends StatefulWidget {
  final String startTime; // Example format: 'Dec 18, 2024 7:38 AM'

  const CountdownTimerWidget({super.key, required this.startTime});

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
    print(widget.startTime);
  }

 void _initializeTimer() {
  try {
    // Replace non-breaking spaces with regular spaces
    final sanitizedStartTime = widget.startTime.replaceAll('\u202F', ' ');

    // Parse the start time
    startDateTime =
        DateFormat("MMM d, yyyy h:mm a").parse(sanitizedStartTime).toLocal();

    // Calculate the end time by adding 20 minutes
    endDateTime = startDateTime.add(const Duration(minutes: 20));

    print("Start Time: $startDateTime");
    print("End Time: $endDateTime");

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
    if (DateTime.now().isAfter(endDateTime)) {
      setState(() {
        isExpired = true;
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime = endDateTime.difference(DateTime.now());

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
            : "${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}",
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

