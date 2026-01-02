// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vocabulary Builder';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get japanese => 'Japanese';

  @override
  String get english => 'English';

  @override
  String get selectGame => 'Select Game';

  @override
  String get wordReplacement => 'Word Replacement';

  @override
  String get wordReplacementDescription =>
      'Find synonyms and alternative expressions';

  @override
  String get rhyming => 'Rhyming';

  @override
  String get rhymingDescription => 'Find words that rhyme with the given word';

  @override
  String get todaysWord => 'Today\'s Word';

  @override
  String get startGame => 'Start Game';

  @override
  String get timeLimit => 'Time Limit';

  @override
  String seconds(int count) {
    return '$count seconds';
  }

  @override
  String get enterYourAnswers => 'Enter your answers';

  @override
  String get submit => 'Done';

  @override
  String get score => 'Score';

  @override
  String get feedback => 'Feedback';

  @override
  String get playAgain => 'Play Again';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get scoreHistory => 'Score History';

  @override
  String get noScoresYet => 'No scores yet';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get settings => 'Settings';

  @override
  String get yourAnswers => 'Your Answers';

  @override
  String get noAnswers => 'No answers';

  @override
  String get scoreExcellent => 'Amazing! You\'re a vocabulary master! 🎉';

  @override
  String get scoreGreat => 'Excellent work! Keep it up! 👏';

  @override
  String get scoreGood => 'Nice work! You\'re improving steadily! 💪';

  @override
  String get scoreOkay => 'Great effort! Practice makes perfect! 📚';

  @override
  String get scoreNeedsWork =>
      'Nice try! Keep playing to boost your skills! 🌟';
}
