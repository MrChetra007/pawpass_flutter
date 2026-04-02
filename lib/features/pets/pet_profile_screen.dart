import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/pet_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/widgets/paw_card.dart';
import 'add_edit_pet_screen.dart';

class PetProfileScreen extends ConsumerWidget {
  final String petId;

  const PetProfileScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petNotifierProvider);
    final theme = Theme.of(context);

    return petsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pet not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, ref, pet),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfo(context, pet),
                      const SizedBox(height: 24),
                      _buildDetailsSection(context, pet),
                      const SizedBox(height: 24),
                      if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                        _buildNotesSection(context, pet),
                        const SizedBox(height: 24),
                      ],
                      _buildHealthSection(context, pet),
                      const SizedBox(height: 24),
                      _buildDangerZone(context, ref, pet),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: pet.photoUrl != null
                  ? Image.network(
                      pet.photoUrl!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        pet.speciesEmoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${pet.species}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditPetScreen(pet: pet),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return PawCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(context, 'Species', pet.species),
          _buildInfoItem(context, 'Gender', _formatGender(pet.gender)),
          _buildInfoItem(context, 'Age', pet.ageString),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return PawCard(
      child: Column(
        children: [
          _buildDetailRow(context, 'Breed', pet.breed ?? 'Not specified'),
          const Divider(),
          _buildDetailRow(context, 'Color', pet.color ?? 'Not specified'),
          const Divider(),
          _buildDetailRow(context, 'Weight', pet.weightKg != null ? '${pet.weightKg} kg' : 'Not specified'),
          const Divider(),
          _buildDetailRow(context, 'Neutered', pet.neutered ? 'Yes' : 'No'),
          const Divider(),
          _buildDetailRow(context, 'Microchip', pet.microchip ?? 'Not specified'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return PawCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(pet.notes!, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildHealthSection(BuildContext context, Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        PawCard(
          onTap: () {},
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.vaccines,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vaccines', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Track vaccination records',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PawCard(
          onTap: () {},
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medications', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Manage medications',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PawCard(
          onTap: () {},
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight History', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Track weight over time',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref, Pet pet) {
    return PawCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        title: const Text(
          'Delete Pet',
          style: TextStyle(color: Colors.red),
        ),
        subtitle: const Text('This action cannot be undone'),
        onTap: () => _showDeleteConfirmation(context, ref, pet),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: Text(
          'Are you sure you want to delete ${pet.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(petNotifierProvider.notifier).deletePet(pet.id);
              if (context.mounted) {
                context.go('/pets');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Unknown';
    return gender[0].toUpperCase() + gender.substring(1);
  }
}
