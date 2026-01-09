import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waste_provider.dart';
import '../providers/auth_provider.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: const Center(
        child: Text(
          'Orders functionality coming soon',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}