# Exemple d'intégration des limites offline KYC

## Backend Laravel

Le service `OfflineLimitService` est déjà intégré dans `OfflineEscrowController`. Voici les endpoints modifiés:

### GET /offline/balance
Retourne maintenant les informations de limites KYC:
```json
{
  "offline_balance": 50000,
  "limits": {
    "kyc_level": 2,
    "kyc_level_name": "partial",
    "trust_score": 65,
    "is_banned": false,
    "current_balance": 150000,
    "current_offline_balance": 50000,
    "max_offline_amount": 105000,
    "max_fixed_amount": 200000,
    "max_percentage": 70,
    "min_trust_score": 50,
    "remaining_available": 55000
  }
}
```

### POST /offline/allocate
Valide maintenant les limites KYC avant allocation:
```json
{
  "amount": 100000
}
```

Réponse en cas de dépassement:
```json
{
  "message": "Montant dépasse la limite autorisée pour votre niveau KYC",
  "limits": { ... }
}
```

## Flutter Client

### Utilisation dans un écran d'allocation offline

```dart
import 'package:virelo_core/virelo_core.dart';
import 'package:flutter/material.dart';

class OfflineAllocationScreen extends StatefulWidget {
  @override
  _OfflineAllocationScreenState createState() => _OfflineAllocationScreenState();
}

class _OfflineAllocationScreenState extends State<OfflineAllocationScreen> {
  final ApiClient _apiClient = ApiClient();
  late OfflineLimitService _limitService;
  OfflineLimitInfo? _limitInfo;
  final TextEditingController _amountController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _limitService = OfflineLimitService(_apiClient);
    _loadLimitInfo();
  }

  Future<void> _loadLimitInfo() async {
    setState(() => _isLoading = true);
    try {
      final limitInfo = await _limitService.getLimitInfo();
      setState(() {
        _limitInfo = limitInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validateAndAllocate() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      setState(() => _errorMessage = 'Montant invalide');
      return;
    }

    // Validation locale avec le service
    final validation = await _limitService.validateAllocation(amount);
    
    if (!validation['valid']) {
      setState(() => _errorMessage = validation['error']);
      return;
    }

    // Envoi au serveur
    try {
      final response = await _apiClient.dio.post('/offline/allocate', data: {
        'amount': amount,
      });
      
      // Succès
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de l\'allocation');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Allocation Offline')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage des informations KYC
            if (_limitInfo != null) ...[
              _buildKycInfoCard(_limitInfo!),
              SizedBox(height: 16),
            ],
            
            // Champ montant
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant à allouer (XOF)',
                errorText: _errorMessage,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Suggestions de montants
            if (_limitInfo != null)
              FutureBuilder<List<double>>(
                future: _limitService.getSuggestedAmounts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return SizedBox();
                  
                  return Wrap(
                    spacing: 8,
                    children: snapshot.data!.map((amount) {
                      return ActionChip(
                        label: Text('${_formatAmount(amount)} XOF'),
                        onPressed: () {
                          _amountController.text = amount.toString();
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            
            SizedBox(height: 24),
            
            // Bouton d'allocation
            ElevatedButton(
              onPressed: _validateAndAllocate,
              child: Text('Allouer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycInfoCard(OfflineLimitInfo info) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Niveau KYC: ${info.kycLevelName.toUpperCase()}', 
                 style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Score de confiance: ${info.trustScore}/100'),
            Text('Solde principal: ${_formatAmount(info.currentBalance)} XOF'),
            Text('Solde offline: ${_formatAmount(info.currentOfflineBalance)} XOF'),
            Divider(),
            Text('Maximum autorisé: ${_formatAmount(info.maxOfflineAmount)} XOF'),
            Text('Disponible: ${_formatAmount(info.remainingAvailable)} XOF'),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}
```

## Configuration des niveaux KYC

Pour modifier les limites, éditez `app/Modules/Wallet/Services/OfflineLimitService.php`:

```php
private const KYC_LEVELS = [
    0 => [
        'name' => 'non_verified',
        'max_amount' => 0,           // Montant fixe maximum
        'max_percentage' => 0,       // Pourcentage du solde principal
        'min_trust_score' => 0,      // Score de confiance minimum
    ],
    1 => [
        'name' => 'basic',
        'max_amount' => 50000,       // 50 000 XOF max
        'max_percentage' => 50,      // ou 50% du solde
        'min_trust_score' => 30,
    ],
    // ... autres niveaux
];
```

## Tests unitaires Laravel

```php
// tests/Unit/OfflineLimitServiceTest.php

use App\Modules\Wallet\Services\OfflineLimitService;
use App\Modules\Auth\Models\User;
use App\Modules\Wallet\Models\Wallet;
use App\Models\KycDocument;

test('kyc level 0 users cannot allocate offline', function () {
    $user = User::factory()->create(['trust_score' => 20]);
    Wallet::factory()->create(['user_id' => $user->id, 'balance' => 100000]);
    
    $service = new OfflineLimitService();
    $result = $service->canAllocateOffline($user, 10000);
    
    expect($result['allowed'])->toBeFalse();
});

test('kyc level 1 users can allocate up to 50% or 50000 XOF', function () {
    $user = User::factory()->create(['trust_score' => 40]);
    Wallet::factory()->create(['user_id' => $user->id, 'balance' => 200000]);
    
    $service = new OfflineLimitService();
    
    // 100000 = 50% de 200000, devrait être autorisé
    expect($service->canAllocateOffline($user, 100000)['allowed'])->toBeTrue();
    
    // 60000 > 50000 fixe, devrait être refusé
    expect($service->canAllocateOffline($user, 60000)['allowed'])->toBeFalse();
});
```
