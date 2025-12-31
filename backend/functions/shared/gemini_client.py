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
    """Client for generating vocabulary words using Gemini 1.5 Flash."""

    MODEL_NAME = "gemini-1.5-flash"
    
    SYSTEM_PROMPT = """あなたは日本語の語彙力トレーニングアプリのための単語生成AIです。

あなたの役割は、指定された日付に対して抽象的で少し難しい日本語の名詞を生成することです。

## 出力ルール
- 必ず以下のJSON形式のみで出力してください。説明文や追加のテキストは一切含めないでください。
- 各単語は「word」(漢字表記)と「reading」(ひらがな読み)を含めてください。

## JSON形式
{
  "words": [
    {
      "date": "YYYY-MM-DD",
      "word": "単語",
      "reading": "たんご"
    }
  ]
}

## 単語選定基準
- 抽象的な概念を表す名詞を選ぶこと
- 日常会話ではあまり使われないが、知っていると語彙力が高いと感じられる単語
- 小学校高学年〜中学生レベルの漢字で構成される単語
- 例: 概念、帰結、矛盾、逆説、恩恵、弊害、風潮、慣習、素養、気概"""

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
            max_output_tokens=2048,
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
                if not all(k in word for k in ["date", "word", "reading"]):
                    logger.warning(f"Skipping invalid word entry: {word}")
                    continue
                validated_words.append({
                    "date": word["date"],
                    "word": word["word"],
                    "reading": word["reading"]
                })
            
            return validated_words
            
        except json.JSONDecodeError as e:
            raise GeminiParseError(f"Failed to parse JSON: {e}") from e
