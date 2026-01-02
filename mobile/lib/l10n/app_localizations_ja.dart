// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '語彙力向上';

  @override
  String get selectLanguage => '言語選択';

  @override
  String get japanese => '日本語';

  @override
  String get english => '英語';

  @override
  String get selectGame => 'ゲーム選択';

  @override
  String get wordReplacement => '言葉の置き換え';

  @override
  String get wordReplacementDescription => '類義語や別の表現を見つけよう';

  @override
  String get rhyming => '韻を踏む';

  @override
  String get rhymingDescription => '与えられた言葉と韻を踏む言葉を見つけよう';

  @override
  String get todaysWord => '今日のお題';

  @override
  String get startGame => 'ゲーム開始';

  @override
  String get timeLimit => '制限時間';

  @override
  String seconds(int count) {
    return '$count秒';
  }

  @override
  String get enterYourAnswers => '回答を入力してください';

  @override
  String get submit => '回答完了';

  @override
  String get score => 'スコア';

  @override
  String get feedback => 'フィードバック';

  @override
  String get playAgain => 'もう一度プレイ';

  @override
  String get backToMenu => 'メニューに戻る';

  @override
  String get scoreHistory => 'スコア履歴';

  @override
  String get noScoresYet => 'まだスコアがありません';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get settings => '設定';

  @override
  String get yourAnswers => '入力した回答';

  @override
  String get noAnswers => '回答なし';

  @override
  String get scoreExcellent => '素晴らしい！語彙力の達人です！🎉';

  @override
  String get scoreGreat => '素晴らしい成績です！👏';

  @override
  String get scoreGood => 'よく頑張りました！💪';

  @override
  String get scoreOkay => 'もう少し練習しましょう！📚';

  @override
  String get scoreNeedsWork => '次はもっと頑張りましょう！🌟';
}
