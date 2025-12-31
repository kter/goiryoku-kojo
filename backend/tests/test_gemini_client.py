"""Tests for Gemini client."""

import pytest
import json
from unittest.mock import MagicMock, patch


class TestGeminiClient:
    """Tests for GeminiClient class."""

    def test_parse_response_valid_json(self):
        """Test parsing valid JSON response."""
        with patch.dict('sys.modules', {
            'vertexai': MagicMock(),
            'vertexai.generative_models': MagicMock()
        }):
            import sys
            sys.path.insert(0, 'functions/shared')
            
            # Import with mocks in place
            from gemini_client import GeminiClient
            
            # Create client with mocked init
            with patch.object(GeminiClient, '__init__', lambda self, **kwargs: None):
                client = GeminiClient()
                client._model = MagicMock()
                
                response_text = json.dumps({
                    "words": [
                        {"date": "2024-01-01", "word": "概念", "reading": "がいねん"},
                        {"date": "2024-01-02", "word": "矛盾", "reading": "むじゅん"}
                    ]
                })
                
                result = client._parse_response(response_text)
                
                assert len(result) == 2
                assert result[0]["word"] == "概念"
                assert result[1]["date"] == "2024-01-02"

    def test_parse_response_with_markdown_code_block(self):
        """Test parsing JSON wrapped in markdown code block."""
        with patch.dict('sys.modules', {
            'vertexai': MagicMock(),
            'vertexai.generative_models': MagicMock()
        }):
            import sys
            sys.path.insert(0, 'functions/shared')
            
            from gemini_client import GeminiClient
            
            with patch.object(GeminiClient, '__init__', lambda self, **kwargs: None):
                client = GeminiClient()
                client._model = MagicMock()
                
                response_text = """```json
{
    "words": [
        {"date": "2024-01-01", "word": "逆説", "reading": "ぎゃくせつ"}
    ]
}
```"""
                
                result = client._parse_response(response_text)
                
                assert len(result) == 1
                assert result[0]["word"] == "逆説"

    def test_parse_response_missing_words_key(self):
        """Test error when response missing 'words' key."""
        with patch.dict('sys.modules', {
            'vertexai': MagicMock(),
            'vertexai.generative_models': MagicMock()
        }):
            import sys
            sys.path.insert(0, 'functions/shared')
            
            from gemini_client import GeminiClient, GeminiParseError
            
            with patch.object(GeminiClient, '__init__', lambda self, **kwargs: None):
                client = GeminiClient()
                client._model = MagicMock()
                
                response_text = json.dumps({"data": []})
                
                with pytest.raises(GeminiParseError):
                    client._parse_response(response_text)

    def test_parse_response_invalid_json(self):
        """Test error on invalid JSON."""
        with patch.dict('sys.modules', {
            'vertexai': MagicMock(),
            'vertexai.generative_models': MagicMock()
        }):
            import sys
            sys.path.insert(0, 'functions/shared')
            
            from gemini_client import GeminiClient, GeminiParseError
            
            with patch.object(GeminiClient, '__init__', lambda self, **kwargs: None):
                client = GeminiClient()
                client._model = MagicMock()
                
                response_text = "This is not valid JSON"
                
                with pytest.raises(GeminiParseError):
                    client._parse_response(response_text)

    def test_parse_response_skips_invalid_entries(self):
        """Test that invalid word entries are skipped."""
        with patch.dict('sys.modules', {
            'vertexai': MagicMock(),
            'vertexai.generative_models': MagicMock()
        }):
            import sys
            sys.path.insert(0, 'functions/shared')
            
            from gemini_client import GeminiClient
            
            with patch.object(GeminiClient, '__init__', lambda self, **kwargs: None):
                client = GeminiClient()
                client._model = MagicMock()
                
                response_text = json.dumps({
                    "words": [
                        {"date": "2024-01-01", "word": "概念", "reading": "がいねん"},
                        {"date": "2024-01-02", "word": "矛盾"},  # Missing reading
                        {"date": "2024-01-03", "word": "逆説", "reading": "ぎゃくせつ"}
                    ]
                })
                
                result = client._parse_response(response_text)
                
                # Should skip the invalid entry
                assert len(result) == 2
                assert result[0]["word"] == "概念"
                assert result[1]["word"] == "逆説"
