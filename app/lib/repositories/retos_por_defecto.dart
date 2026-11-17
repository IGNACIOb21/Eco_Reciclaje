import '../services/supabase_service.dart';
import 'retos_repository.dart';
import 'retos_repository_mock.dart';
import 'retos_repository_supabase.dart';

/// Repositorio real si Supabase está configurado; si no, el mock (demo).
RetosRepository retosPorDefecto() => SupabaseService.disponible
    ? RetosRepositorySupabase()
    : RetosRepositoryMock();
