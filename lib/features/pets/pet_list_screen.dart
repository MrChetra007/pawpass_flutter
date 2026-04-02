import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/pet_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/paw_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/upgrade_modal.dart';
import 'add_edit_pet_screen.dart';

class PetListScreen extends ConsumerStatefulWidget {
  const PetListScreen({super.key});

  @override
  ConsumerState<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends ConsumerState<PetListScreen> with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(petNotifierProvider.notifier).loadPets();
    });
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petsState = ref.watch(petNotifierProvider);
    final userAsync = ref.watch(userProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Pets', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Manage your furry family members', style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: petsState.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonCard(),
                  ),
                  childCount: 3,
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _buildErrorState(e.toString()),
              ),
              data: (pets) {
                if (pets.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.pets,
                      title: 'No pets yet',
                      subtitle: 'Add your first pet to start tracking their health',
                      actionLabel: 'Add Pet',
                      onAction: () => _showAddPetModal(context, userAsync),
                    ),
                  );
                }
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_listAnimationController.isCompleted) {
                    _listAnimationController.forward();
                  }
                });
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPetCard(context, pet: pets[index], index: index),
                      ),
                    ),
                    childCount: pets.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: petsState.when(
        data: (pets) => userAsync.when(
          data: (user) {
            final maxPets = user?.maxPets ?? 1;
            final currentPets = pets.length;
            return _AnimatedFab(
              onPressed: () {
                if (currentPets >= maxPets && maxPets < 999) {
                  UpgradeModal.show(context);
                } else {
                  _showAddPetModal(context, userAsync);
                }
              },
              theme: theme,
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(petNotifierProvider.notifier).loadPets(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, {required Pet pet, required int index}) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/pets/${pet.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'pet-avatar-${pet.id}',
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  image: pet.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(pet.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pet.photoUrl == null
                    ? Center(
                        child: Text(
                          pet.speciesEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.species}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.labelLarge?.color,
                    ),
                  ),
                  if (pet.dob != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      pet.ageString,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPetModal(BuildContext context, AsyncValue<User?> userAsync) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPetScreen(),
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final ThemeData theme;

  const _AnimatedFab({required this.onPressed, required this.theme});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _controller.forward().then((_) {
            _controller.reverse();
            widget.onPressed();
          });
        },
        backgroundColor: widget.theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
