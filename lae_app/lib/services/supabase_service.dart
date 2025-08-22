import 'dart:convert';
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
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3cnloaXFqbGNsaGtoY3pweXphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNzQ1NTksImV4cCI6MjA2Njc1MDU1OX0.eKRdsQ6zXsUGhhAGQ6ByVjYmBcdlEiCVnPTE5wlJT3A',
    );
  }

  // Add a helper function to sanitize records for SQLite
  Map<String, dynamic> _sanitizeRecordForSqlite(Map<String, dynamic> record) {
    final sanitizedRecord = <String, dynamic>{};
    record.forEach((key, value) {
      if (value is Map || value is List) {
        sanitizedRecord[key] =
            jsonEncode(value); // Convert maps/lists to JSON strings
      } else if (value is bool) {
        sanitizedRecord[key] = value ? 1 : 0; // Convert booleans to integers
      } else {
        sanitizedRecord[key] = value;
      }
    });
    return sanitizedRecord;
  }

  /// Fetches planning data from Supabase and stores it locally.
  Future<void> syncPlanningData() async {
    try {
      print('Starting planning data sync...');
      // Fetch data from all relevant tables in parallel.
      // Using lowercase names as they are likely folded to lowercase in PostgreSQL.
      final responses = await Future.wait([
        _client.from('reminders').select(),
        _client.from('schedules').select(),
        _client.from('quests').select(),
        _client.from('routine_plan').select(),
      ]);

      // The 'responses' list contains the result for each query.
      final reminders = responses[0] as List<dynamic>;
      final schedules = responses[1] as List<dynamic>;
      final quests = responses[2] as List<dynamic>;
      final routinePlans = responses[3] as List<dynamic>;

      // Use the generic 'replaceAll' method to update local DB.
      // Sanitize the data before inserting it into the local database
      await _dbHelper.replaceAll('Reminders',
          reminders.map((e) => _sanitizeRecordForSqlite(e)).toList());
      await _dbHelper.replaceAll('Schedules',
          schedules.map((e) => _sanitizeRecordForSqlite(e)).toList());
      await _dbHelper.replaceAll(
          'Quests', quests.map((e) => _sanitizeRecordForSqlite(e)).toList());
      await _dbHelper.replaceAll('Routine_Plan',
          routinePlans.map((e) => _sanitizeRecordForSqlite(e)).toList());

      print(
          'Successfully synced ${reminders.length} reminders, ${schedules.length} schedules, ${quests.length} quests, and ${routinePlans.length} routine plans.');
    } catch (e) {
      print('Error syncing planning data: $e');
    }
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
