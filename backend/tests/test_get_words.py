"""Tests for get_words function."""

import pytest
import json
from datetime import date
from unittest.mock import MagicMock, patch


class TestGetWords:
    """Tests for get_words HTTP function."""

    @patch('main.FirestoreClient')
    def test_get_words_success(self, mock_client_class):
        """Test successful word retrieval."""
        # Setup mock
        mock_client = MagicMock()
        mock_client_class.return_value = mock_client
        mock_client.get_words_by_date_range.return_value = [
            {"date": "2024-01-01", "word": "概念", "reading": "がいねん"},
            {"date": "2024-01-02", "word": "矛盾", "reading": "むじゅん"}
        ]
        
        # Import function after patching
        import sys
        sys.path.insert(0, 'functions/get_words')
        from main import get_words
        
        # Create mock request
        mock_request = MagicMock()
        mock_request.method = "GET"
        mock_request.args = {}
        
        # Test
        response = get_words(mock_request)
        data = json.loads(response.get_data(as_text=True))
        
        # Verify
        assert response.status_code == 200
        assert data["success"] is True
        assert data["count"] == 2
        assert len(data["words"]) == 2

    @patch('main.FirestoreClient')
    def test_get_words_with_missing_dates(self, mock_client_class):
        """Test that missing dates don't cause errors."""
        mock_client = MagicMock()
        mock_client_class.return_value = mock_client
        # Return only 1 word even though we might request 30 days
        mock_client.get_words_by_date_range.return_value = [
            {"date": "2024-01-01", "word": "概念", "reading": "がいねん"}
        ]
        
        import sys
        sys.path.insert(0, 'functions/get_words')
        from main import get_words
        
        mock_request = MagicMock()
        mock_request.method = "GET"
        mock_request.args = {"days": 30}
        
        response = get_words(mock_request)
        data = json.loads(response.get_data(as_text=True))
        
        # Should succeed with partial data
        assert response.status_code == 200
        assert data["success"] is True
        assert data["count"] == 1

    def test_get_words_cors_preflight(self):
        """Test CORS preflight request handling."""
        import sys
        sys.path.insert(0, 'functions/get_words')
        from main import get_words
        
        mock_request = MagicMock()
        mock_request.method = "OPTIONS"
        
        response = get_words(mock_request)
        
        assert response.status_code == 204
        assert response.headers.get("Access-Control-Allow-Origin") == "*"

    def test_get_words_method_not_allowed(self):
        """Test POST request returns 405."""
        import sys
        sys.path.insert(0, 'functions/get_words')
        from main import get_words
        
        mock_request = MagicMock()
        mock_request.method = "POST"
        
        response = get_words(mock_request)
        
        assert response.status_code == 405

    @patch('main.FirestoreClient')
    def test_get_words_days_parameter_clamped(self, mock_client_class):
        """Test days parameter is clamped between 1 and 30."""
        mock_client = MagicMock()
        mock_client_class.return_value = mock_client
        mock_client.get_words_by_date_range.return_value = []
        
        import sys
        sys.path.insert(0, 'functions/get_words')
        from main import get_words
        
        # Test with days > 30
        mock_request = MagicMock()
        mock_request.method = "GET"
        mock_request.args = {"days": 100}
        
        get_words(mock_request)
        
        # Verify the date range is 30 days max
        call_args = mock_client.get_words_by_date_range.call_args
        start_date, end_date = call_args[0]
        assert (end_date - start_date).days == 29  # 30 days inclusive
