import '../services/supabase_service.dart';
import 'beneficios_repository.dart';
import 'beneficios_repository_mock.dart';
import 'beneficios_repository_supabase.dart';

/// Repositorio real si Supabase está configurado; si no, el mock (demo).
BeneficiosRepository beneficiosPorDefecto() => SupabaseService.disponible
    ? BeneficiosRepositorySupabase()
    : BeneficiosRepositoryMock();
