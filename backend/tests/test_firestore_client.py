"""Tests for Firestore client."""

import pytest
from datetime import date, timedelta
from unittest.mock import MagicMock, patch


# Mock the firestore module before importing
with patch.dict('sys.modules', {'google.cloud': MagicMock(), 'google.cloud.firestore': MagicMock()}):
    import sys
    sys.path.insert(0, 'functions/shared')
    from firestore_client import FirestoreClient


class TestFirestoreClient:
    """Tests for FirestoreClient class."""

    @patch('firestore_client.firestore.Client')
    def test_get_words_by_date_range(self, mock_client_class):
        """Test fetching words by date range."""
        # Setup mock
        mock_db = MagicMock()
        mock_client_class.return_value = mock_db
        
        mock_doc1 = MagicMock()
        mock_doc1.to_dict.return_value = {
            "date": "2024-01-01",
            "word": "概念",
            "reading": "がいねん"
        }
        mock_doc2 = MagicMock()
        mock_doc2.to_dict.return_value = {
            "date": "2024-01-02",
            "word": "矛盾",
            "reading": "むじゅん"
        }
        
        mock_db.collection.return_value.where.return_value.where.return_value.order_by.return_value.stream.return_value = [
            mock_doc1, mock_doc2
        ]
        
        # Test
        client = FirestoreClient()
        result = client.get_words_by_date_range(
            date(2024, 1, 1),
            date(2024, 1, 2)
        )
        
        # Verify
        assert len(result) == 2
        assert result[0]["word"] == "概念"
        assert result[1]["word"] == "矛盾"

    @patch('firestore_client.firestore.Client')
    def test_get_existing_dates(self, mock_client_class):
        """Test getting set of existing dates."""
        mock_db = MagicMock()
        mock_client_class.return_value = mock_db
        
        mock_doc = MagicMock()
        mock_doc.to_dict.return_value = {
            "date": "2024-01-01",
            "word": "概念",
            "reading": "がいねん"
        }
        
        mock_db.collection.return_value.where.return_value.where.return_value.order_by.return_value.stream.return_value = [
            mock_doc
        ]
        
        client = FirestoreClient()
        result = client.get_existing_dates(
            date(2024, 1, 1),
            date(2024, 1, 3)
        )
        
        assert "2024-01-01" in result
        assert "2024-01-02" not in result

    @patch('firestore_client.firestore.Client')
    def test_save_words(self, mock_client_class):
        """Test saving words to Firestore."""
        mock_db = MagicMock()
        mock_client_class.return_value = mock_db
        mock_batch = MagicMock()
        mock_db.batch.return_value = mock_batch
        
        words = [
            {"date": "2024-01-01", "word": "概念", "reading": "がいねん"},
            {"date": "2024-01-02", "word": "矛盾", "reading": "むじゅん"}
        ]
        
        client = FirestoreClient()
        count = client.save_words(words)
        
        assert count == 2
        assert mock_batch.set.call_count == 2
        mock_batch.commit.assert_called_once()
