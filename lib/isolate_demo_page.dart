import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// A simple, top-level function that represents our heavy, CPU-intensive task.
// Isolates require a top-level function or a static method as an entry point.
double heavyComputationTask(int cycles) {
  double result = 0.0;
  for (int i = 0; i < cycles; i++) {
    // This is a dummy calculation to simulate CPU work
    result += (i + 1) * 0.5;
    result -= i * 0.25;
  }
  print('Computation finished!');
  return result;
}


class IsolateDemoPage extends StatefulWidget {
  const IsolateDemoPage({super.key});

  @override
  State<IsolateDemoPage> createState() => _IsolateDemoPageState();
}

class _IsolateDemoPageState extends State<IsolateDemoPage> {
  String _resultText = "Press a button to start.";
  bool _isLoading = false;
  final int _computationCycles = 1000000000; // A large number for heavy work

  // --- Method 1: Run on the Main Thread (UI will freeze) ---
  Future<void> _runOnMainThread() async {
    setState(() {
      _isLoading = true;
      _resultText = "Running on Main Thread...\nUI will freeze!";
    });

    // A small delay to allow the UI to update before it freezes.
    await Future.delayed(const Duration(milliseconds: 100));

    final result = heavyComputationTask(_computationCycles);

    setState(() {
      _resultText = "Main Thread Result: ${result.toStringAsFixed(2)}";
      _isLoading = false;
    });
  }

  // --- Method 2: Run with an Isolate (UI stays responsive) ---
  Future<void> _runWithIsolate() async {
    setState(() {
      _isLoading = true;
      _resultText = "Running with Isolate...\nUI is responsive!";
    });

    // 'compute' is a helper that runs a function in a new isolate
    // and returns the result. It's the easiest way to use isolates.
    final result = await compute(heavyComputationTask, _computationCycles);

    setState(() {
      _resultText = "Isolate Result: ${result.toStringAsFixed(2)}";
      _isLoading = false;
    });
  }

  Future<void> _runWithIsolateManually() async {
    setState(() {
      _isLoading = true;
      _resultText = "Running with Isolate...\nUI is responsive!";
    });

    // 1. Create a ReceivePort to receive messages from the new isolate.
    final receivePort = ReceivePort();

    // 2. Spawn a new isolate.
    // We pass our entry function and a message containing two things:
    //    - The SendPort the new isolate can use to communicate back.
    //    - The data needed for the computation (_computationCycles).
    await Isolate.spawn(
      manualIsolateEntry,
      [receivePort.sendPort, _computationCycles],
    );

    // 3. Listen for the first message from the new isolate.
    // `receivePort.first` returns a Future that completes with the first message sent.
    final result = await receivePort.first;

    setState(() {
      _resultText = "Isolate Result: ${result.toStringAsFixed(2)}";
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Thread vs. Isolate'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // A loading indicator to visualize UI responsiveness
             // if (_isLoading)
              Center(child: CircularProgressIndicator()),
              // else
              //   const SizedBox(height: 48.0), // Placeholder to maintain layout

              const SizedBox(height: 40),

              // Display the result
              Text(
                _resultText,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Button to run the task on the main thread
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade300),
                onPressed: _isLoading ? null : _runOnMainThread,
                child: const Text('Run on Main Thread (Freezes UI)'),
              ),

              const SizedBox(height: 16),

              // Button to run the task with an isolate
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade300),
                onPressed: _isLoading ? null : _runWithIsolate,
                child: const Text('Run with Isolate (Keeps UI Smooth)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}