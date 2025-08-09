import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lae_app/models/status_record.dart';
import 'package:lae_app/services/database_helper.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize the Supabase client.
  // Call this in main.dart
  static Future<void> initialize() async {
    await Supabase.initialize(
      // Replace with your actual Supabase URL and Anon Key
      url: 'https://vwryhiqjlclhkhczpyza.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3cnloaXFqbGNsaGtoY3pweXphIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTE3NDU1OSwiZXhwIjoyMDY2NzUwNTU5fQ.eaum2sXRrjfA-gAub9EcW_8vmnDXmiCljoxwKEhrnw4',
    );
  }

  /// Reads all local status records, transforms them, and uploads to Supabase.
  Future<void> uploadStatusRecords() async {
    // 1. Fetch all records from the local SQLite database.
    final List<StatusRecord> localRecords =
        await _dbHelper.getAllStatusRecords();

    if (localRecords.isEmpty) {
      print('No local records to upload.');
      return;
    }

    // 2. Fetch the 'record_time' of all existing records from Supabase.
    final List<dynamic> existingRecordsData = await _client
        .from('survey_records')
        .select('record_time')
        .eq('survey_type', 'daily_status_check');

    // A simpler and more robust way to parse timestamp strings from Supabase
    final Set<String> existingRecordTimes = existingRecordsData.map((record) {
      final timeStr = record['record_time'] as String;
      // DateTime.parse can handle various ISO 8601 formats.
      // toUtc().toIso8601String() canonicalizes it to the '...Z' format.
      return DateTime.parse(timeStr).toUtc().toIso8601String();
    }).toSet();

    // 3. Filter local records to find only the new ones.
    final List<StatusRecord> newRecords = localRecords.where((record) {
      // Compare using the same UTC ISO8601 string format.
      final localRecordTimeStr = record.recordTime.toUtc().toIso8601String();
      return !existingRecordTimes.contains(localRecordTimeStr);
    }).toList();

    if (newRecords.isEmpty) {
      print('All local records are already synced. Nothing to upload.');
      return;
    }

    // 4. Transform only the new records into the upload format.
    final List<Map<String, dynamic>> recordsToUpload = newRecords.map((record) {
      final Map<String, dynamic> answers = record.toMap();
      answers.remove('id'); // Remove local DB ID before upload.

      // --- THIS IS THE FIX ---
      // Generate the timestamp string in the *exact same way* as in the check.
      // Always convert to UTC first to ensure consistency.
      final recordTimeStr = record.recordTime.toUtc().toIso8601String();

      // Ensure the 'answers' map also has the canonical UTC time if needed elsewhere.
      answers['recordTime'] = recordTimeStr;

      return {
        'record_time': recordTimeStr,
        'survey_type': 'daily_status_check',
        'answers': answers,
      };
    }).toList();

    // 5. Insert only the new records into Supabase.
    try {
      await _client.from('survey_records').insert(recordsToUpload);
      print('Successfully uploaded ${recordsToUpload.length} new records.');
    } catch (e) {
      print('Error uploading new records: $e');
      // You might want to add more robust error handling here.
    }
  }
}
