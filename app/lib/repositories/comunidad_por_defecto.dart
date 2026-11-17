import '../services/supabase_service.dart';
import 'comunidad_repository.dart';
import 'comunidad_repository_mock.dart';
import 'comunidad_repository_supabase.dart';

/// Repositorio real si Supabase está configurado; si no, el mock (demo).
ComunidadRepository comunidadPorDefecto() => SupabaseService.disponible
    ? ComunidadRepositorySupabase()
    : ComunidadRepositoryMock();
