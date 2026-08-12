import 'store_model.dart';
import 'user_model.dart';

class VendorModel {
  const VendorModel({required this.user, this.store});

  final UserModel user;
  final StoreModel? store;

  int? get id => user.id;
  String get fullName => user.fullName;
  String get email => user.email;
  int? get storeId => user.storeId;
  String get createdAt => user.createdAt;
  bool get hasStoreAssignment => storeId != null;
  String get storeName => store?.name ?? 'Unassigned store';
  String get marketName => store?.marketName ?? 'No market assigned';

  factory VendorModel.fromUser({required UserModel user, StoreModel? store}) {
    if (!user.isVendor) {
      throw ArgumentError.value(
        user.role,
        'user.role',
        'VendorModel requires a user with the vendor role.',
      );
    }
    return VendorModel(user: user, store: store);
  }

  VendorModel copyWith({UserModel? user, StoreModel? store}) {
    return VendorModel(user: user ?? this.user, store: store ?? this.store);
  }
}
