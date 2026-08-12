import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/store_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchController = TextEditingController();
  String _roleFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<AdminController>();
      await controller.loadUsers();
      await controller.loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final webLayout = useAdminWebLayout(context);
    final vendors = controller.users.where((item) => item.isVendor).length;
    final admins = controller.users.where((item) => item.isAdmin).length;
    final query = _searchController.text.trim().toLowerCase();
    final visibleUsers = controller.users.where((user) {
      final matchesQuery =
          query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      return matchesQuery && (_roleFilter == 'all' || user.role == _roleFilter);
    }).toList();

    return Scaffold(
      appBar: webLayout ? null : AppBar(title: const Text('Manage Users')),
      floatingActionButton: webLayout
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openUserDialog(role: 'vendor'),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add vendor'),
            ),
      body: AppBackground(
        showTopGlow: false,
        child: controller.isLoading && controller.users.isEmpty
            ? const ListLoadingView(cardCount: 6)
            : AdminPageFrame(
                maxWidth: 1280,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    AdminPageHeader(
                      title: 'Users',
                      subtitle:
                          'Create vendor logins only after the shop is verified as a legitimate Lingayen Municipal Market seller. One vendor account should be linked to one shop.',
                      icon: Icons.people_alt_rounded,
                      action: webLayout
                          ? FilledButton.icon(
                              onPressed: () => _openUserDialog(role: 'vendor'),
                              icon: const Icon(Icons.storefront_rounded),
                              label: const Text('Add vendor'),
                            )
                          : null,
                      metrics: [
                        AdminHeaderMetric(
                          label: 'Total users',
                          value: '${controller.users.length}',
                          icon: Icons.people_outline_rounded,
                        ),
                        AdminHeaderMetric(
                          label: 'Vendors',
                          value: '$vendors',
                          icon: Icons.storefront_outlined,
                          accent: AppColors.warning,
                        ),
                        AdminHeaderMetric(
                          label: 'Admins',
                          value: '$admins',
                          icon: Icons.admin_panel_settings_outlined,
                          accent: AppColors.sky,
                        ),
                      ],
                    ),
                    if (controller.error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AdminErrorBanner(message: controller.error!),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _UserFilters(
                      controller: _searchController,
                      role: _roleFilter,
                      onChanged: (role) => setState(() => _roleFilter = role),
                      onSearch: () => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    visibleUsers.isEmpty
                        ? const AppSurfaceCard(
                            radius: 28,
                            child: EmptyStateView(
                              title: 'No users found',
                              message:
                                  'User accounts will appear here once community users sign up or an admin creates vendor access.',
                              icon: Icons.people_outline_rounded,
                            ),
                          )
                        : webLayout
                        ? _UsersTable(
                            users: visibleUsers,
                            stores: controller.stores,
                            currentUserId: context
                                .read<AuthController>()
                                .currentUser
                                ?.id,
                            onEdit: (user) => _openUserDialog(user: user),
                            onDelete: _confirmDelete,
                          )
                        : AppSurfaceCard(
                            radius: 28,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < controller.users.length;
                                  i++
                                ) ...[
                                  _UserRow(
                                    user: controller.users[i],
                                    stores: controller.stores,
                                    currentUserId: context
                                        .read<AuthController>()
                                        .currentUser
                                        ?.id,
                                    onEdit: () => _openUserDialog(
                                      user: controller.users[i],
                                    ),
                                    onDelete: controller.users[i].isAdmin
                                        ? null
                                        : () => _confirmDelete(
                                            controller.users[i],
                                          ),
                                  ),
                                  if (i != controller.users.length - 1)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSpacing.md,
                                      ),
                                      child: Divider(height: 1),
                                    ),
                                ],
                              ],
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Remove ${user.fullName} from the system? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || user.id == null) {
      return;
    }
    await context.read<AdminController>().deleteUser(user.id!);
  }

  Future<void> _openUserDialog({UserModel? user, String role = 'user'}) async {
    final formKey = GlobalKey<FormState>();
    final currentUserId = context.read<AuthController>().currentUser?.id;
    final isEditingSelf = user?.id != null && user!.id == currentUserId;
    final fullNameController = TextEditingController(
      text: user?.fullName ?? '',
    );
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    var selectedRole = user?.role ?? role;
    var selectedStoreId = user?.storeId;
    var obscurePassword = true;
    final stores = context.read<AdminController>().stores;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isVendor = selectedRole == 'vendor';

            return AlertDialog(
              title: Text(user == null ? 'Add user' : 'Edit user'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: (value) => Validators.requiredField(
                            value,
                            label: 'Full name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: const [
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('Community user'),
                            ),
                            DropdownMenuItem(
                              value: 'vendor',
                              child: Text('Vendor'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: isEditingSelf
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    selectedRole = value;
                                    if (selectedRole != 'vendor') {
                                      selectedStoreId = null;
                                    } else if (selectedStoreId == null &&
                                        stores.isNotEmpty) {
                                      selectedStoreId = stores.first.id;
                                    }
                                  });
                                },
                        ),
                        if (isVendor) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: selectedStoreId,
                            decoration: const InputDecoration(
                              labelText: 'Verified shop assignment',
                            ),
                            items: stores
                                .map(
                                  (store) => DropdownMenuItem<int>(
                                    value: store.id,
                                    child: Text(
                                      store.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (value) => isVendor && value == null
                                ? 'A verified shop is required for each vendor.'
                                : null,
                            onChanged: (value) =>
                                setState(() => selectedStoreId = value),
                          ),
                        ],
                        if (isVendor) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Vendor rule: 1 account = 1 verified shop/vendor. Confirm the seller is legitimate before saving.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryFor(context),
                                  height: 1.35,
                                ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: user == null
                                ? 'Password'
                                : 'New password (optional)',
                            suffixIcon: IconButton(
                              tooltip: obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (user == null) {
                              return Validators.password(value);
                            }
                            if ((value ?? '').trim().isEmpty) {
                              return null;
                            }
                            return Validators.password(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    await context.read<AdminController>().saveUser(
                      id: user?.id,
                      fullName: fullNameController.text,
                      email: emailController.text,
                      role: selectedRole,
                      storeId: selectedRole == 'vendor'
                          ? selectedStoreId
                          : null,
                      password: passwordController.text.trim().isEmpty
                          ? null
                          : passwordController.text,
                    );
                    if (context.mounted && isEditingSelf) {
                      await context.read<AuthController>().refreshUser();
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(user == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _UserFilters extends StatelessWidget {
  const _UserFilters({
    required this.controller,
    required this.role,
    required this.onChanged,
    required this.onSearch,
  });
  final TextEditingController controller;
  final String role;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final search = TextField(
        controller: controller,
        onChanged: (_) => onSearch(),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Search name or email',
        ),
      );
      final filter = DropdownButtonFormField<String>(
        initialValue: role,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.manage_accounts_outlined),
          labelText: 'Role',
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All roles')),
          DropdownMenuItem(value: 'admin', child: Text('Admins')),
          DropdownMenuItem(value: 'vendor', child: Text('Vendors')),
          DropdownMenuItem(value: 'user', child: Text('Community users')),
        ],
        onChanged: (value) => onChanged(value ?? 'all'),
      );
      if (constraints.maxWidth < 700) {
        return Column(children: [search, const SizedBox(height: 12), filter]);
      }
      return Row(
        children: [
          Expanded(flex: 3, child: search),
          const SizedBox(width: 12),
          Expanded(child: filter),
        ],
      );
    },
  );
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.stores,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UserModel> users;
  final List<StoreModel> stores;
  final int? currentUserId;
  final ValueChanged<UserModel> onEdit;
  final ValueChanged<UserModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminDataTableCard(
      minWidth: 1040,
      columns: const ['User', 'Role', 'Shop assignment', 'Joined', 'Actions'],
      rows: [
        for (final user in users)
          DataRow(
            cells: [
              DataCell(_UserIdentityCell(user: user)),
              DataCell(_RoleChip(role: user.role)),
              DataCell(
                Text(
                  _storeNameFor(user.storeId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppFormatters.date(user.createdAt)),
                    if (user.id == currentUserId)
                      Text(
                        'Current admin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.sky,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onEdit(user),
                      tooltip: 'Edit user',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    if (!user.isAdmin)
                      IconButton(
                        onPressed: () => onDelete(user),
                        tooltip: 'Delete user',
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _storeNameFor(int? storeId) {
    if (storeId == null) {
      return 'Not assigned';
    }
    final store = stores.cast<StoreModel?>().firstWhere(
      (item) => item?.id == storeId,
      orElse: () => null,
    );
    return store?.name ?? 'Unknown shop';
  }
}

class _UserIdentityCell extends StatelessWidget {
  const _UserIdentityCell({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(user.role);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(roleIcon(user.role), color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.stores,
    required this.currentUserId,
    required this.onEdit,
    this.onDelete,
  });

  final UserModel user;
  final List<StoreModel> stores;
  final int? currentUserId;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final assignedStore = stores.cast<StoreModel?>().firstWhere(
      (item) => item?.id == user.storeId,
      orElse: () => null,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: roleColor(user.role).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(roleIcon(user.role), color: roleColor(user.role)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoleChip(role: user.role),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                assignedStore == null
                    ? 'Joined ${AppFormatters.date(user.createdAt)}'
                    : 'Store: ${assignedStore.name} • Joined ${AppFormatters.date(user.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              if (user.id == currentUserId) ...[
                const SizedBox(height: 6),
                Text(
                  'Current signed-in admin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: roleColor(user.role),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: onEdit,
          tooltip: 'Edit user',
          icon: const Icon(Icons.edit_outlined),
        ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete user',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
    );
  }
}

Color roleColor(String role) {
  switch (role) {
    case 'admin':
      return AppColors.sky;
    case 'vendor':
      return AppColors.warning;
    default:
      return AppColors.primaryDark;
  }
}

IconData roleIcon(String role) {
  switch (role) {
    case 'admin':
      return Icons.admin_panel_settings_rounded;
    case 'vendor':
      return Icons.storefront_rounded;
    default:
      return Icons.person_outline_rounded;
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'admin' => AppColors.sky,
      'vendor' => AppColors.warning,
      _ => AppColors.primaryDark,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
