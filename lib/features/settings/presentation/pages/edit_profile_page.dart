import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../../chat/presentation/viewmodels/survey_data_provider.dart';
import '../../../chat/presentation/viewmodels/skin_types_data.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final UserProfile userProfile;

  const EditProfilePage({super.key, required this.userProfile});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController ageController;
  late TextEditingController genderController;

  String? selectedSkinType;
  String? selectedSkinCondition;
  Set<String> selectedCosmetics = {};
  bool isLoading = false;
  String? originalSkinType; // 초기 Skin Type 저장 (변경 여부 확인용)

  // Skin Type 옵션 (영어)
  final skinTypeOptions = ['OILY', 'DRY', 'COMBINATION', 'SENSITIVE'];

  // 한국어-영어 변환 맵
  final koreanToEnglish = {
    '지성': 'OILY',
    '건성': 'DRY',
    '복합성': 'COMBINATION',
    '민감성': 'SENSITIVE',
  };

  final englishToKorean = {
    'OILY': '지성',
    'DRY': '건성',
    'COMBINATION': '복합성',
    'SENSITIVE': '민감성',
  };

  late Map<String, String> koreanToEnglishCondition;
  late Map<String, String> englishToKoreanCondition;

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController(
      text: widget.userProfile.username ?? '',
    );
    ageController = TextEditingController(
      text: widget.userProfile.age?.toString() ?? '',
    );
    genderController = TextEditingController(
      text: widget.userProfile.gender ?? '',
    );

    // Survey 데이터 가져오기
    final surveyData = ref.read(surveyDataProvider);

    // 초기 선택값 설정
    String? initialSkinType =
        surveyData.primaryType ?? widget.userProfile.skinType;
    if (initialSkinType != null) {
      if (koreanToEnglish.containsKey(initialSkinType)) {
        selectedSkinType = koreanToEnglish[initialSkinType];
      } else if (skinTypeOptions.contains(initialSkinType.toUpperCase())) {
        selectedSkinType = initialSkinType.toUpperCase();
      }
    }
    originalSkinType = selectedSkinType; // 초기 Skin Type 저장

    selectedSkinCondition =
        surveyData.secondaryType ?? widget.userProfile.skinCondition;

    // categories: surveyData 우선, 없으면 서버 프로필에서 가져오기
    if (surveyData.categories.isNotEmpty) {
      selectedCosmetics = surveyData.categories.toSet();
    } else if (widget.userProfile.categories != null &&
        widget.userProfile.categories!.isNotEmpty) {
      selectedCosmetics = widget.userProfile.categories!.toSet();
    }

    print('📝 EditProfilePage 초기값:');
    print('   surveyData.categories: ${surveyData.categories}');
    print('   userProfile.categories: ${widget.userProfile.categories}');
    print('   selectedCosmetics: $selectedCosmetics');

    // Skin Condition 변환 맵 생성
    koreanToEnglishCondition = {};
    englishToKoreanCondition = {};
    skinSubTypeDetails.forEach((korean, details) {
      final english = details['english'] ?? korean;
      koreanToEnglishCondition[korean] = english;
      englishToKoreanCondition[english] = korean;
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    ageController.dispose();
    genderController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validate username is not empty
    if (usernameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a username'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Validate username length
    if (usernameController.text.length > 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username must be 8 characters or less'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      // 영어로 선택된 skin type을 한국어로 변환
      final koreanSkinType = selectedSkinType != null
          ? (englishToKorean[selectedSkinType] ?? selectedSkinType)
          : null;

      // 영어로 선택된 skin condition을 한국어로 변환
      final koreanSkinCondition = selectedSkinCondition != null
          ? (englishToKoreanCondition[selectedSkinCondition] ??
                selectedSkinCondition)
          : null;

      // 카테고리를 대문자로 통일하고 중복 제거
      final uniqueCategories = selectedCosmetics
          .map((cat) => cat.toUpperCase())
          .toSet()
          .toList();

      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        email: widget.userProfile.email,
        username: usernameController.text.isNotEmpty
            ? usernameController.text
            : null,
        skinType: koreanSkinType,
        skinCondition: koreanSkinCondition,
        categories: uniqueCategories.isNotEmpty ? uniqueCategories : null,
        age: ageController.text.isNotEmpty
            ? int.tryParse(ageController.text)
            : null,
        gender: genderController.text.isNotEmpty ? genderController.text : null,
      );

      await ref.read(updateUserProfileProvider(updatedProfile).future);

      // Survey 데이터도 업데이트
      final surveyNotifier = ref.read(surveyDataProvider.notifier);
      if (selectedSkinType != null) {
        final koreanSkinType =
            englishToKorean[selectedSkinType] ?? selectedSkinType;
        surveyNotifier.setPrimaryType(koreanSkinType);
      }
      if (selectedSkinCondition != null) {
        final koreanSkinCondition =
            englishToKoreanCondition[selectedSkinCondition] ??
            selectedSkinCondition;
        surveyNotifier.setSecondaryType(koreanSkinCondition);
      }
      print('📦 Updating categories: $uniqueCategories');
      surveyNotifier.setCategories(uniqueCategories);

      if (mounted) {
        Navigator.pop(context, true); // true를 반환하여 성공 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) {
              // 저장 버튼 활성화 조건 계산
              final hasSkinType = selectedSkinType != null && selectedSkinType!.isNotEmpty;
              final hasSkinCondition = selectedSkinCondition != null && selectedSkinCondition!.isNotEmpty;
              final hasCosmetics = selectedCosmetics.isNotEmpty;
              final skinTypeChanged = selectedSkinType != originalSkinType;
              final hasUsername = usernameController.text.trim().isNotEmpty;
              
              // 저장 버튼 활성화 여부:
              // 1. 로딩 중이 아니고
              // 2. Username이 입력되어 있고
              // 3. 모든 필수 항목(SKIN TYPE, SKIN CONDITION, COSMETICS)이 선택되어 있어야 함
              // 4. Skin Type이 변경되었으면 Skin Condition도 반드시 선택되어 있어야 함
              final isSaveEnabled = !isLoading &&
                  hasUsername &&
                  hasSkinType &&
                  hasSkinCondition &&
                  hasCosmetics &&
                  (!skinTypeChanged || (skinTypeChanged && hasSkinCondition));
              
              return TextButton(
                onPressed: isSaveEnabled 
                    ? _saveProfile 
                    : () {
                        // 비활성화된 버튼을 눌렀을 때 경고 메시지 표시
                        List<String> missingFields = [];
                        if (!hasUsername) missingFields.add('Username');
                        if (!hasSkinType) missingFields.add('Skin Type');
                        if (!hasSkinCondition) missingFields.add('Skin Condition');
                        if (!hasCosmetics) missingFields.add('Categories');
                        
                        String message;
                        if (missingFields.isNotEmpty) {
                          message = 'Please fill in: ${missingFields.join(', ')}';
                        } else if (skinTypeChanged && !hasSkinCondition) {
                          message = 'Please select Skin Condition after changing Skin Type';
                        } else {
                          message = 'Please complete all required fields';
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: isSaveEnabled 
                      ? theme.colorScheme.primary 
                      : Colors.grey,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: isSaveEnabled 
                              ? theme.colorScheme.primary 
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username
            _buildSectionTitle('Username', isDark),
            const SizedBox(height: 8),
            TextField(
              controller: usernameController,
              maxLength: 8,
              onChanged: (_) => setState(() {}), // Rebuild to update Save button
              decoration: InputDecoration(
                hintText: 'Enter your username',
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: '', // Hide counter text
              ),
            ),
            const SizedBox(height: 24),

            // Skin Type
            _buildSectionTitle('Skin Type', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skinTypeOptions.map((type) {
                final isSelected = selectedSkinType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedSkinType = selected ? type : null;
                      selectedSkinCondition = null;
                    });
                  },
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.white,
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Skin Condition
            if (selectedSkinType != null) ...[
              _buildSectionTitle('Skin Condition', isDark),
              const SizedBox(height: 8),
              _buildSkinConditionDropdown(isDark, theme),
              const SizedBox(height: 24),
            ],

            // Age
            const SizedBox(height: 24),

            // Cosmetics Categories
            _buildSectionTitle('Cosmetics Categories', isDark),
            const SizedBox(height: 8),
            _buildCosmeticsSection(isDark, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[100] : Colors.black87,
      ),
    );
  }

  Widget _buildSkinConditionDropdown(bool isDark, ThemeData theme) {
    // 영어 skin type을 한국어로 변환
    final englishSkinType = selectedSkinType ?? '';
    final koreanSkinType = englishToKorean[englishSkinType] ?? englishSkinType;

    // skinSubTypes에서 한국어 키로 조회
    final conditions = skinSubTypes[koreanSkinType] ?? [];

    if (conditions.isEmpty) {
      return Text(
        'No conditions available for $englishSkinType',
        style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
      );
    }

    // 중복 제거 및 items 생성
    final uniqueConditions = conditions.toSet().toList();
    final items = uniqueConditions.map((koreanCondition) {
      // 한국어 컨디션을 영어로 변환하여 표시
      final englishCondition =
          skinSubTypeDetails[koreanCondition]?['english'] ?? koreanCondition;
      return DropdownMenuItem<String>(
        value: koreanCondition, // 값은 한국어로 저장
        child: Text(englishCondition), // 표시는 영어로
      );
    }).toList();

    // selectedSkinCondition이 items에 있는지 확인
    final validValue =
        selectedSkinCondition != null &&
            uniqueConditions.contains(selectedSkinCondition)
        ? selectedSkinCondition
        : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: const Text('Select skin condition'),
      items: items,
      onChanged: (value) {
        setState(() {
          selectedSkinCondition = value;
        });
      },
    );
  }

  Widget _buildCosmeticsSection(bool isDark, ThemeData theme) {
    final cosmeticCategories = [
      'CLEANSER',
      'TONER',
      'ESSENCE',
      'SERUM',
      'AMPOULE',
      'LOTION',
      'CREAM',
      'EYE CREAM',
      'SUNSCREEN',
      'MASK PACK',
      'MIST',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cosmeticCategories.map((category) {
        final isSelected = selectedCosmetics.contains(category);
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedCosmetics.add(category);
              } else {
                selectedCosmetics.remove(category);
              }
            });
          },
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
          checkmarkColor: theme.colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        );
      }).toList(),
    );
  }
}
