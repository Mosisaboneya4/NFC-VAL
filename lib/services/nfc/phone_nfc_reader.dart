import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'nfc_reader_interface.dart';

/// Implementation of NFC reader using the phone's built-in NFC capability
class PhoneNfcReader implements NfcReaderInterface {
  bool _isInitialized = false;
  bool _isScanning = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check if NFC is available
    final availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      throw Exception('NFC is not available on this device');
    }
    
    _isInitialized = true;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> scanCard() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    _isScanning = true;
    
    try {
      // Poll for NFC tag
      final tag = await FlutterNfcKit.poll();
      
      // Finish the session to allow multiple reads
      await FlutterNfcKit.finish();
      
      _isScanning = false;
      
      // Return UID as string
      return tag.id;
    } catch (e) {
      _isScanning = false;
      await FlutterNfcKit.finish();
      rethrow;
    }
  }

  @override
  Future<void> stopScanning() async {
    if (_isScanning) {
      _isScanning = false;
      await FlutterNfcKit.finish();
    }
  }

  @override
  Future<void> dispose() async {
    await stopScanning();
    _isInitialized = false;
  }
}
