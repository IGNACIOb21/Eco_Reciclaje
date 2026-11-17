import '../services/supabase_service.dart';
import 'acciones_repository.dart';
import 'acciones_repository_mock.dart';
import 'acciones_repository_supabase.dart';

/// Repositorio real si Supabase está configurado; si no, el mock (demo).
AccionesRepository accionesPorDefecto() => SupabaseService.disponible
    ? AccionesRepositorySupabase()
    : AccionesRepositoryMock();
