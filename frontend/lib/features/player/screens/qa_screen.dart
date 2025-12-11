import 'package:flutter/material.dart';

class QAScreen extends StatelessWidget {
  const QAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101922),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ask about the Colosseum',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                AIMessage(
                  message:
                      'I am listening. Feel free to ask me anything about the architecture, history, or the gladiators who fought here.',
                ),
                UserMessage(message: 'Who built this structure?'),
                AIResponse(
                  title: 'Vespasian and Titus',
                  message:
                      'Construction began under Emperor Vespasian in AD 72 and was completed in AD 80 under his successor and heir, Titus. Further modifications were made during the reign of Domitian.',
                ),
              ],
            ),
          ),
          // Bottom Controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF101922),
              boxShadow: [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 20,
                  spreadRadius: -10,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Listening...',
                  style: TextStyle(
                    color: Color(0xFF137fec),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: const Color(0xFF137fec),
                  child: const Icon(Icons.mic, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AIMessage extends StatelessWidget {
  final String message;
  const AIMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF137fec),
            child: Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2732),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class UserMessage extends StatelessWidget {
  final String message;
  const UserMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF137fec),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AIResponse extends StatelessWidget {
  final String title;
  final String message;
  const AIResponse({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF137fec),
            child: Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2732),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF137fec),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
