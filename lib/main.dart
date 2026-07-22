import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/nfc/phone_nfc_reader.dart';
import 'services/supabase/supabase_service.dart';
import 'services/eligibility/eligibility_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase - REPLACE WITH YOUR ACTUAL CREDENTIALS
  await Supabase.initialize(
    url: 'https://flevnphtltfanarrluyt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsZXZucGh0bHRmYW5hcnJsdXl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0MTQ3ODUsImV4cCI6MjA5Nzk5MDc4NX0.jLRysC70Hr1I3IXfS9JhWtRO3mzRtMRaA2QezfqNTk0',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Eligibility Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const EligibilityCheckerScreen(),
    );
  }
}

class EligibilityCheckerScreen extends StatefulWidget {
  const EligibilityCheckerScreen({super.key});

  @override
  State<EligibilityCheckerScreen> createState() => _EligibilityCheckerScreenState();
}

class _EligibilityCheckerScreenState extends State<EligibilityCheckerScreen> {
  late final EligibilityChecker _eligibilityChecker;
  bool _isScanning = false;
  EligibilityResult? _lastResult;
  String? _errorMessage;
  final TextEditingController _manualCardIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final nfcReader = PhoneNfcReader();
    final supabaseService = SupabaseService.instance;
    
    _eligibilityChecker = EligibilityChecker(
      nfcReader: nfcReader,
      supabaseService: supabaseService,
    );
    
    try {
      await nfcReader.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'NFC initialization failed: ${e.toString()}';
      });
    }
  }

  Future<void> _scanCard() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _lastResult = null;
    });

    try {
      final result = await _eligibilityChecker.checkEligibility();
      setState(() {
        _lastResult = result;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Scanning failed: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  Future<void> _checkManualCardId() async {
    final manualId = _manualCardIdController.text.trim();
    if (manualId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a card ID';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _lastResult = null;
    });

    try {
      print('Debug: Checking card ID: $manualId');
      print('Debug: Supabase client initialized: ${Supabase.instance.client != null}');
      
      final userData = await SupabaseService.instance.getUserByCardUid(manualId);
      print('Debug: User data received: $userData');
      
      if (userData == null) {
        setState(() {
          _lastResult = EligibilityResult(
            isEligible: false,
            status: EligibilityStatus.userNotFound,
            message: 'User not found for card ID: $manualId',
            cardUid: manualId,
            balance: null,
          );
          _isScanning = false;
        });
        return;
      }

      final balance = userData['balance'];
      final balanceValue = balance is num ? balance.toDouble() : 0.0;
      final isEligible = balanceValue >= 100.0;

      setState(() {
        _lastResult = EligibilityResult(
          isEligible: isEligible,
          status: isEligible ? EligibilityStatus.eligible : EligibilityStatus.insufficientBalance,
          message: isEligible 
              ? 'Eligible - Balance: ${balanceValue.toStringAsFixed(2)} birr'
              : 'Not Eligible - Balance: ${balanceValue.toStringAsFixed(2)} birr (Minimum: 100 birr)',
          cardUid: manualId,
          balance: balanceValue,
          userName: userData['name'] as String?,
        );
        _isScanning = false;
      });
    } catch (e) {
      print('Debug: Error occurred: $e');
      setState(() {
        _errorMessage = 'Check failed: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  Future<void> _debugShowAllUsers() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final users = await SupabaseService.instance.getAllUsers();
      setState(() {
        _errorMessage = 'Found ${users.length} users in database. Check console for details.';
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch users: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  Future<void> _debugCheckTables() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.debugCheckTables();
      setState(() {
        _errorMessage = 'Table check complete. Check console for details.';
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check tables: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('NFC Eligibility Checker'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.nfc,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tap an NFC card to check eligibility',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Minimum balance: 100 birr',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Manual Card ID Input for debugging
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Debug: Manual Card ID Check',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _manualCardIdController,
                        decoration: const InputDecoration(
                          hintText: 'Enter NFC card ID manually',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isScanning ? null : _checkManualCardId,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.grey[700],
                        ),
                        child: const Text('Check Manual ID'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isScanning ? null : _debugShowAllUsers,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.orange[700],
                        ),
                        child: const Text('Debug: Show All Users'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isScanning ? null : _debugCheckTables,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red[700],
                        ),
                        child: const Text('Debug: Check Tables'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_lastResult != null) ...[
                  _buildResultCard(_lastResult!),
                  const SizedBox(height: 24),
                ],
                ElevatedButton(
                  onPressed: _isScanning ? null : _scanCard,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isScanning
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Scanning...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.nfc),
                            SizedBox(width: 12),
                            Text('Scan NFC Card'),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(EligibilityResult result) {
    final isEligible = result.isEligible;
    final color = isEligible ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEligible ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isEligible ? Icons.check_circle : Icons.cancel,
                size: 48,
                color: color,
              ),
              const SizedBox(width: 16),
              Text(
                isEligible ? 'ELIGIBLE' : 'NOT ELIGIBLE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.userName != null) ...[
            Text(
              'Name: ${result.userName}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
          ],
          if (result.balance != null) ...[
            Text(
              'Balance: ${result.balance!.toStringAsFixed(2)} birr',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
          ],
          if (result.cardUid != null) ...[
            Text(
              'Card UID: ${result.cardUid}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eligibilityChecker.dispose();
    _manualCardIdController.dispose();
    super.dispose();
  }
}
