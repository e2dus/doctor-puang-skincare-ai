// 피부 타입별 세부 타입 맵
final Map<String, List<String>> skinSubTypes = {
  '지성': ['유분과다형', '수분부족형(지성 속건성)', '트러블형(지성)', '불균형형 지성'],
  '건성': ['단순건성', '수분부족형(건성)', '유분부족형 건성', '민감성 건성'],
  '복합성': ['T존지성형', 'U존지성형', '균형형 복합성', '트러블형 복합성'],
  '민감성': ['환경반응형', '화장품반응형', '트러블형(민감성)', '복합형 민감성'],
};

// 세부 타입별 이모지와 영어 단어 맵
final Map<String, Map<String, String>> skinSubTypeDetails = {
  '유분과다형': {'emoji': '💧', 'english': 'OILY'},
  '수분부족형(지성 속건성)': {'emoji': '💦', 'english': 'DRY-SHINY'},
  '트러블형(지성)': {'emoji': '💥', 'english': 'PIMPLY'},
  '불균형형 지성': {'emoji': '⚖️', 'english': 'UNBALANCED'},
  '단순건성': {'emoji': '🌬️', 'english': 'DRY'},
  '수분부족형(건성)': {'emoji': '🌵', 'english': 'THIRSTY'},
  '유분부족형 건성': {'emoji': '🧈', 'english': 'NO OIL'},
  '민감성 건성': {'emoji': '😥', 'english': 'FRAGILE'},
  'T존지성형': {'emoji': '➡️', 'english': 'T-OILY'},
  'U존지성형': {'emoji': '↩️', 'english': 'U-OILY'},
  '균형형 복합성': {'emoji': '✅', 'english': 'BALANCED'},
  '트러블형 복합성': {'emoji': '💢', 'english': 'MIXED-ACNE'},
  '환경반응형': {'emoji': '☀️', 'english': 'SENSITIVE'},
  '화장품반응형': {'emoji': '🧴', 'english': 'REACTIVE'},
  '트러블형(민감성)': {'emoji': '🚨', 'english': 'IRRITATED'},
  '복합형 민감성': {'emoji': '❓', 'english': 'COMPLEX'},
};

// 화장품 타입별 이모지와 영어 단어 맵
final Map<String, Map<String, String>> cosmeticTypeDetails = {
  'TONER': {'emoji': '💧', 'english': 'TONER'},
  'ESSENCE': {'emoji': '🧪', 'english': 'ESSENCE'},
  'AMPOULE': {'emoji': '💉', 'english': 'AMPOULE'},
  'SERUM': {'emoji': '✨', 'english': 'SERUM'},
  'LOTION': {'emoji': '🧴', 'english': 'LOTION'},
  'CREAM': {'emoji': '🧈', 'english': 'CREAM'},
  'EYE CREAM': {'emoji': '👁️', 'english': 'EYE CREAM'},
  'MIST': {'emoji': '🌫️', 'english': 'MIST'},
  'SUNSCREEN': {'emoji': '☀️', 'english': 'SUNSCREEN'},
  'CLEANSER': {'emoji': '🧼', 'english': 'CLEANSER'},
  'MASK PACK': {'emoji': '🎭', 'english': 'MASK PACK'},
};

// 화장품 타입 목록
final List<String> cosmeticTypes = [
  'TONER',
  'ESSENCE',
  'AMPOULE',
  'SERUM',
  'LOTION',
  'CREAM',
  'EYE CREAM',
  'MIST',
  'SUNSCREEN',
  'CLEANSER',
  'MASK PACK',
];

