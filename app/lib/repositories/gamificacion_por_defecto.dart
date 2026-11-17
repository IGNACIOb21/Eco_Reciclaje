import '../services/supabase_service.dart';
import 'gamificacion_repository.dart';
import 'gamificacion_repository_mock.dart';
import 'gamificacion_repository_supabase.dart';

/// Repositorio real si Supabase está configurado; si no, el mock (demo).
GamificacionRepository gamificacionPorDefecto() => SupabaseService.disponible
    ? GamificacionRepositorySupabase()
    : GamificacionRepositoryMock();
