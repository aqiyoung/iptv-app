import 'package:flutter/material.dart';

void main() {
  runApp(const IptvApp());
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC96442),
        ),
        useMaterial3: true,
      ),
      home: const IptvHomePage(),
    );
  }
}

class IptvHomePage extends StatelessWidget {
  const IptvHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IPTV'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Scaffold ready - awaiting features'),
      ),
    );
  }
}
