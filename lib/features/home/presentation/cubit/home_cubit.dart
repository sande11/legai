import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/usecases/get_recent_activity.dart';

class HomeState extends Equatable {
  const HomeState({this.user, this.recent = const [], this.loading = true});

  final AppUser? user;
  final List<RecentActivity> recent;
  final bool loading;

  @override
  List<Object?> get props => [user, recent, loading];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetCurrentUser getCurrentUser,
    required GetRecentActivity getRecentActivity,
    this.limit = 3,
  }) : _user = getCurrentUser,
       _recent = getRecentActivity,
       super(const HomeState());

  final GetCurrentUser _user;
  final GetRecentActivity _recent;
  final int? limit;

  Future<void> load() async {
    final user = await _user(const NoParams());
    final recent = await _recent(limit);
    if (!isClosed) emit(HomeState(user: user, recent: recent, loading: false));
  }
}
