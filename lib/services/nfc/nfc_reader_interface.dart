/// Abstract interface for NFC readers
/// This abstraction allows easy switching between different NFC reader implementations
/// (e.g., built-in phone NFC, external USB/Bluetooth readers)
abstract class NfcReaderInterface {
  /// Initialize the NFC reader
  Future<void> initialize();
  
  /// Check if NFC is available on the device
  Future<bool> isAvailable();
  
  /// Start scanning for NFC cards and return the UID when a card is tapped
  /// Returns the unique identifier (UID) of the NFC card
  Future<String> scanCard();
  
  /// Stop scanning for NFC cards
  Future<void> stopScanning();
  
  /// Clean up resources
  Future<void> dispose();
}
