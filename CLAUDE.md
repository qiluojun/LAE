# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Initialization

**IMPORTANT**: At the beginning of each conversation session, always read `docs/current_development_status.md` to understand:
- Current development phase and progress
- Recent attempts and their results
- Known issues and technical challenges
- Next planned actions

This ensures continuity across conversation sessions and prevents repeating failed approaches.

## Project Overview

LAE (Live And Enjoy) is a personal self-regulation system implementing a complete "Record → Analyze → Predict → Intervene" loop. The system uses a multi-platform architecture with Python backend, Flutter mobile app, and cloud synchronization via Supabase.

**Core principle**: Focus on logic, not data pipeline complexity. Manual input is acceptable during the concept validation phase.

## Architecture

### Data Flow
1. **Obsidian notes** → `ob_quest.py` → Local SQLite (Quests table)
2. **Local SQLite** → `supabase_client.py` → Supabase cloud (one-way sync)
3. **Mobile app** → Supabase (user inputs) → Python backend analysis → Supabase (system outputs) → Mobile app

### Core Components

- **Python Backend** (`src/`): Core decision engine running on Windows PC
  - `supabase_client.py`: Main sync engine between local SQLite and Supabase
  - `ob_quest.py`: Obsidian vault integration for quest management
- **Flutter Mobile App** (`lae_app/`): Primary user interface for data input and intervention display
- **Local Database** (`database/data_base.db`): SQLite database for offline operations
- **Cloud Database**: Supabase PostgreSQL for cross-device communication

## Development Commands

### Flutter Mobile App
```bash
cd lae_app

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build for Android
flutter build apk

# Run tests
flutter test

# Analyze code (lint)
flutter analyze
```

### Python Backend
```bash
# Activate virtual environment (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt  # Note: requirements.txt may need to be created

# Run main sync engine
python src/supabase_client.py

# Run Obsidian integration
python src/ob_quest.py
```

### Database Management
```bash
# View database schema
sqlite3 database/data_base.db ".schema"

# Execute SQL queries
sqlite3 database/data_base.db "SELECT * FROM Quests LIMIT 5;"
```

## Key Database Tables

### Local SQLite (`database/data_base.db`)
- **Activities**: Personal activity definitions with multi-dimensional attributes
- **Quests**: Main/side quests from Obsidian vault (managed by `ob_quest.py`)
- **Schedules**: Concrete action plans and scheduling
- **Routine_Plan**: Daily routine rules and time blocks
- **Reminders**: Specific reminder events
- **Event_Log**: Core event recording for analysis
- **Risk_Patterns**: Risk behavior pattern definitions
- **System_Triggers**: System trigger configurations

### Supabase Cloud
- **quests, schedules, routine_plan, reminders**: Planning data synced from local
- **survey_records**: User questionnaire responses from mobile app
- **user_inputs**: Mobile app user interaction data
- **system_outputs**: System intervention commands for mobile display
- **risk_patterns, system_triggers**: Cloud-synced configurations

## Development Notes

### Flutter App Structure
- **Models** (`lib/models/`): Data structures (e.g., `status_record.dart`)
- **Pages** (`lib/pages/`): UI screens for surveys, records, and planning data
- **Services** (`lib/services/`): Database, notifications, and Supabase integration

### Python Dependencies
Current Python scripts use:
- `supabase-py`: Cloud database client
- `sqlite3`: Local database operations (built-in)
- Standard libraries: `os`, `json`, `pathlib`, `re`

### Configuration
- **Supabase credentials**: Stored in environment variables (SUPABASE_SERVICE_KEY)
- **Database paths**: Relative paths from script locations
- **Obsidian paths**: Configured in `ob_quest.py` ROOT_PATHS

## Testing and Quality

### Flutter
- Uses `flutter_lints: ^3.0.0` for code analysis
- Test files in `lae_app/test/`
- Run `flutter analyze` before commits

### Python
- Manual testing currently used
- Database operations should be tested with sample data
- Consider adding unit tests for critical sync logic

## Important Considerations

1. **Security**: Supabase keys should use environment variables in production
2. **Data Sync**: One-way sync from local to cloud (local is source of truth for planning data)
3. **Error Handling**: Both Python scripts include basic error handling for database operations
4. **File Paths**: Windows-specific paths used; adjust for cross-platform deployment
5. **Manual Input Phase**: System designed to accept manual input as placeholder for future automated sensors

## Common Tasks

- **Add new quest**: Use Obsidian vault structure, then run `ob_quest.py`
- **Sync to cloud**: Run `supabase_client.py`
- **Update mobile app**: Modify Flutter code in `lae_app/lib/`
- **Add new survey type**: Update mobile app models and Supabase `survey_records` handling
- **Modify database schema**: Update `database/schema.sql` and handle migrations in both SQLite and Supabase