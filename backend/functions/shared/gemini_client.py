"""Gemini client for vocabulary word generation using Vertex AI."""

import json
import logging
from typing import Optional

import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

logger = logging.getLogger(__name__)


class GeminiClientError(Exception):
    """Base exception for Gemini client errors."""
    pass


class GeminiParseError(GeminiClientError):
    """Raised when response cannot be parsed as expected JSON."""
    pass


class GeminiClient:
    """Client for generating vocabulary words using Gemini 2.5 Flash."""

    MODEL_NAME = "gemini-2.5-flash"
    
    SYSTEM_PROMPT = """あなたは日本語の語彙力トレーニングアプリのための単語生成AIです。

あなたの役割は、指定された日付に対して抽象的で少し難しい日本語の名詞を生成し、その英訳も提供することです。

## 出力ルール
- 必ず以下のJSON形式のみで出力してください。説明文や追加のテキストは一切含めないでください。
- 各単語は「word」(漢字表記)、「reading」(ひらがな読み)、「word_en」(英語訳)を含めてください。

## JSON形式
{
  "words": [
    {
      "date": "YYYY-MM-DD",
      "word": "単語",
      "reading": "たんご",
      "word_en": "English translation"
    }
  ]
}

## 単語選定基準
- 抽象的な概念を表す名詞を選ぶこと
- 日常会話ではあまり使われないが、知っていると語彙力が高いと感じられる単語
- 小学校高学年〜中学生レベルの漢字で構成される単語
- 例: 概念(concept)、帰結(consequence)、矛盾(contradiction)、逆説(paradox)、恩恵(blessing)"""

    def __init__(
        self,
        project_id: Optional[str] = None,
        location: str = "asia-northeast1"
    ):
        """Initialize Gemini client.
        
        Args:
            project_id: GCP project ID.
            location: Vertex AI location.
        """
        vertexai.init(project=project_id, location=location)
        self._model = GenerativeModel(
            self.MODEL_NAME,
            system_instruction=self.SYSTEM_PROMPT
        )
        self._generation_config = GenerationConfig(
            temperature=0.8,
            max_output_tokens=8192,
            response_mime_type="application/json"
        )

    def generate_words(
        self,
        dates: list[str],
        recent_words: list[str]
    ) -> list[dict]:
        """Generate vocabulary words for specified dates.
        
        Args:
            dates: List of date strings (YYYY-MM-DD) to generate words for.
            recent_words: List of recent words to avoid duplication.
            
        Returns:
            List of generated word dictionaries.
            
        Raises:
            GeminiParseError: If response cannot be parsed.
            GeminiClientError: For other API errors.
        """
        if not dates:
            return []

        # Build prompt with context
        recent_words_str = "、".join(recent_words) if recent_words else "なし"
        dates_str = ", ".join(dates)
        
        prompt = f"""以下の日付に対して、それぞれ1つずつ抽象的で少し難しい日本語の名詞を生成してください。

対象日付: {dates_str}

## 重複回避
以下の直近の単語とは重複しない単語を選んでください:
{recent_words_str}

上記の形式で、{len(dates)}件の単語をJSON形式で出力してください。"""

        try:
            response = self._model.generate_content(
                prompt,
                generation_config=self._generation_config
            )
            
            return self._parse_response(response.text)
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Gemini response: {e}")
            raise GeminiParseError(f"Invalid JSON response: {e}") from e
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise GeminiClientError(f"API error: {e}") from e

    def _parse_response(self, response_text: str) -> list[dict]:
        """Parse and validate the JSON response.
        
        Args:
            response_text: Raw response text from Gemini.
            
        Returns:
            List of validated word dictionaries.
            
        Raises:
            GeminiParseError: If parsing or validation fails.
        """
        try:
            # Clean response text (remove markdown code blocks if present)
            cleaned = response_text.strip()
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            if cleaned.startswith("```"):
                cleaned = cleaned[3:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()

            data = json.loads(cleaned)
            
            if "words" not in data:
                raise GeminiParseError("Response missing 'words' key")
            
            words = data["words"]
            validated_words = []
            
            for word in words:
                if not all(k in word for k in ["date", "word", "reading", "word_en"]):
                    logger.warning(f"Skipping invalid word entry: {word}")
                    continue
                validated_words.append({
                    "date": word["date"],
                    "word": word["word"],
                    "reading": word["reading"],
                    "word_en": word["word_en"]
                })
            
            return validated_words
            
            return validated_words
            
        except json.JSONDecodeError as e:
            raise GeminiParseError(f"Failed to parse JSON: {e}") from e

    def score_answers(
        self,
        word: str,
        answers: list[str],
        game_type: str,
        locale: str = "ja",
    ) -> dict:
        """Score user answers for vocabulary game.
        
        Args:
            word: The target word (お題).
            answers: List of user's answers.
            game_type: "word_replacement" or "rhyming".
            locale: Language for prompts ("ja" or "en").
            
        Returns:
            Dictionary with score (0-100) and feedback.
            
        Raises:
            GeminiClientError: For API errors.
        """
        is_english = locale == "en"
        game_context = self._get_game_context(game_type, is_english)
        
        if is_english:
            system_prompt = f"""You are a linguistics expert. Score the user's word list against the given topic using the following criteria, and return your response in JSON format.

Evaluation Criteria:
{game_context}

Response Format (must return in this exact JSON format):
{{
  "score": <integer from 0-100>,
  "feedback": "<feedback in English including scoring reasons and suggestions for improvement>"
}}

Scoring Guidelines:
- Each word is worth up to 10 points
- Score up to 10 words maximum (100 points total)
- Duplicate words are not scored
- Inappropriate or irrelevant words score 0
- Evaluate creativity and vocabulary richness"""
        else:
            system_prompt = f"""あなたは言語学の専門家です。提示された『お題』に対して、ユーザーが入力した『単語リスト』を以下の基準で採点し、JSON形式で返してください。

評価基準：
{game_context}

回答形式（必ずこの形式のJSONで返してください）：
{{
  "score": <0-100の整数>,
  "feedback": "<採点理由と改善点を含む日本語のフィードバック>"
}}

採点のポイント：
- 各単語は最大10点
- 最大10単語まで採点（100点満点）
- 重複した単語は採点しない
- 不適切または無関係な単語は0点
- 創造性と語彙力の豊かさを評価"""

        if is_english:
            game_type_name = "Word Replacement" if game_type == "word_replacement" else "Rhyming"
            answers_text = "\n".join(f"• {a}" for a in answers) if answers else "(No answers)"
            user_prompt = f"""【Game Type】{game_type_name}

【Topic】{word}

【User's Answers】
{answers_text}

Please score the above answers."""
        else:
            game_type_name = "言葉の置き換え" if game_type == "word_replacement" else "韻を踏む"
            answers_text = "\n".join(f"・{a}" for a in answers) if answers else "（回答なし）"
            user_prompt = f"""【ゲーム種別】{game_type_name}

【お題】{word}

【ユーザーの回答】
{answers_text}

上記の回答を採点してください。"""

        try:
            model = GenerativeModel(
                self.MODEL_NAME,
                system_instruction=system_prompt,
            )
            
            config = GenerationConfig(
                temperature=0.7,
                max_output_tokens=8192,
                response_mime_type="application/json",
            )
            
            response = model.generate_content(user_prompt, generation_config=config)
            return self._parse_score_response(response.text)
            
        except Exception as e:
            logger.error(f"Gemini API error during scoring: {e}")
            raise GeminiClientError(f"Scoring API error: {e}") from e

    def _get_game_context(self, game_type: str, is_english: bool = False) -> str:
        """Get evaluation context for the game type."""
        if game_type == "word_replacement":
            if is_english:
                return """【Word Replacement Game】
- Evaluate words with the same or similar meaning to the topic word
- Priority on appropriateness as synonyms
- Higher scores for more refined expressions or specialized alternatives"""
            else:
                return """【言葉の置き換えゲーム】
- お題の単語と同じ意味、または類似の意味を持つ単語を評価
- 同義語、類義語としての適切さを重視
- より洗練された表現や専門的な言い換えは高得点"""
        else:
            if is_english:
                return """【Rhyming Game】
- Evaluate whether words rhyme with the topic (matching end sounds)
- Evaluate not just sound matching but also cleverness of the word
- Higher scores for creative and unexpected rhymes"""
            else:
                return """【韻を踏むゲーム】
- お題の単語と韻を踏んでいるか（語尾の音が一致しているか）を評価
- 単なる音の一致だけでなく、言葉としての面白さも評価
- 創造的で意外性のある韻は高得点"""

    def _parse_score_response(self, response_text: str) -> dict:
        """Parse the scoring response."""
        try:
            cleaned = response_text.strip()
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            if cleaned.startswith("```"):
                cleaned = cleaned[3:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()
            
            data = json.loads(cleaned)
            
            return {
                "score": int(data.get("score", 0)),
                "feedback": str(data.get("feedback", "")),
            }
            
        except (json.JSONDecodeError, ValueError) as e:
            logger.error(f"Failed to parse score response: {e}")
            return {
                "score": 0,
                "feedback": "スコアの解析に失敗しました。",
            }

