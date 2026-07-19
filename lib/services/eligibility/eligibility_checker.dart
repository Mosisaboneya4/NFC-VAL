import '../nfc/nfc_reader_interface.dart';
import '../supabase/supabase_service.dart';

/// Business logic for checking user eligibility based on NFC card and balance
class EligibilityChecker {
  final NfcReaderInterface _nfcReader;
  final SupabaseService supabaseService;
  
  // Minimum balance required for eligibility (in birr)
  static const double minimumBalance = 100.0;

  EligibilityChecker({
    required this._nfcReader,
    required this.supabaseService,
  });
  
  /// Dispose resources
  Future<void> dispose() async {
    await _nfcReader.dispose();
  }

  /// Check if a user is eligible by scanning their NFC card
  /// Returns a result containing the eligibility status and relevant details
  Future<EligibilityResult> checkEligibility() async {
    try {
      // Scan the NFC card to get the UID
      final cardUid = await _nfcReader.scanCard();
      
      // Query Supabase for user data
      final userData = await supabaseService.getUserByCardUid(cardUid);
      
      if (userData == null) {
        return EligibilityResult(
          isEligible: false,
          status: EligibilityStatus.userNotFound,
          message: 'User not found for this card',
          cardUid: cardUid,
          balance: null,
        );
      }
      
      // Extract balance from user data
      final balance = userData['balance'];
      final balanceValue = balance is num ? balance.toDouble() : 0.0;
      
      // Check if balance meets the minimum requirement
      final isEligible = balanceValue >= minimumBalance;
      
      return EligibilityResult(
        isEligible: isEligible,
        status: isEligible ? EligibilityStatus.eligible : EligibilityStatus.insufficientBalance,
        message: isEligible 
            ? 'Eligible - Balance: ${balanceValue.toStringAsFixed(2)} birr'
            : 'Not Eligible - Balance: ${balanceValue.toStringAsFixed(2)} birr (Minimum: $minimumBalance birr)',
        cardUid: cardUid,
        balance: balanceValue,
        userName: userData['name'] as String?,
      );
    } catch (e) {
      return EligibilityResult(
        isEligible: false,
        status: EligibilityStatus.error,
        message: 'Error: ${e.toString()}',
        cardUid: null,
        balance: null,
      );
    }
  }
}

/// Result of an eligibility check
class EligibilityResult {
  final bool isEligible;
  final EligibilityStatus status;
  final String message;
  final String? cardUid;
  final double? balance;
  final String? userName;

  EligibilityResult({
    required this.isEligible,
    required this.status,
    required this.message,
    this.cardUid,
    this.balance,
    this.userName,
  });
}

/// Status of eligibility check
enum EligibilityStatus {
  eligible,
  insufficientBalance,
  userNotFound,
  error,
}
