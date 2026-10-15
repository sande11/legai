import '../../../../core/usecase/usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class LoadSettings implements UseCase<AppSettings, NoParams> {
  const LoadSettings(this._repository);
  final SettingsRepository _repository;

  @override
  Future<AppSettings> call(NoParams params) => _repository.load();
}

class SaveSettings implements UseCase<void, AppSettings> {
  const SaveSettings(this._repository);
  final SettingsRepository _repository;

  @override
  Future<void> call(AppSettings settings) => _repository.save(settings);
}
