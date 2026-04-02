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

class _PetListScreenState extends ConsumerState<PetListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(petNotifierProvider.notifier).loadPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsState = ref.watch(petNotifierProvider);
    final userAsync = ref.watch(userProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
      ),
      body: petsState.when(
        loading: () => _buildLoadingState(),
        error: (e, _) => _buildErrorState(e.toString()),
        data: (pets) {
          if (pets.isEmpty) {
            return EmptyState(
              icon: Icons.pets,
              title: 'No pets yet',
              subtitle: 'Add your first pet to start tracking their health',
              actionLabel: 'Add Pet',
              onAction: () => _showAddPetModal(context, userAsync),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(petNotifierProvider.notifier).loadPets();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPetCard(context, pet),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: userAsync.when(
        data: (user) {
          final maxPets = user?.maxPets ?? 1;
          final currentPets = (petsState.value ?? []).length;
          return FloatingActionButton(
            onPressed: () {
              if (currentPets >= maxPets && maxPets < 999) {
                UpgradeModal.show(context);
              } else {
                _showAddPetModal(context, userAsync);
              }
            },
            child: const Icon(Icons.add),
          );
        },
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonCard(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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

  Widget _buildPetCard(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return PawCard(
      onTap: () => context.push('/pets/${pet.id}'),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: theme.textTheme.titleLarge,
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
          Icon(
            Icons.chevron_right,
            color: theme.textTheme.labelLarge?.color,
          ),
        ],
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
