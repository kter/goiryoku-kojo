"""Firestore client for vocabulary words management."""

from datetime import date, timedelta
from typing import Optional
from google.cloud import firestore


class FirestoreClient:
    """Client for interacting with Firestore to manage vocabulary words."""

    COLLECTION_NAME = "words"

    def __init__(self, project_id: Optional[str] = None):
        """Initialize Firestore client.
        
        Args:
            project_id: Optional GCP project ID. If None, uses default.
        """
        if project_id:
            self._db = firestore.Client(project=project_id)
        else:
            self._db = firestore.Client()

    def get_words_by_date_range(
        self, start_date: date, end_date: date
    ) -> list[dict]:
        """Get words within a date range.
        
        Args:
            start_date: Start date (inclusive).
            end_date: End date (inclusive).
            
        Returns:
            List of word documents found within the range.
            Missing dates are simply not included (no error).
        """
        start_str = start_date.isoformat()
        end_str = end_date.isoformat()

        docs = (
            self._db.collection(self.COLLECTION_NAME)
            .where("date", ">=", start_str)
            .where("date", "<=", end_str)
            .order_by("date")
            .stream()
        )

        return [doc.to_dict() for doc in docs]

    def get_recent_words(self, days: int = 10) -> list[dict]:
        """Get words from the last N days.
        
        Args:
            days: Number of days to look back.
            
        Returns:
            List of recent word documents.
        """
        end_date = date.today()
        start_date = end_date - timedelta(days=days)
        return self.get_words_by_date_range(start_date, end_date)

    def get_existing_dates(
        self, start_date: date, end_date: date
    ) -> set[str]:
        """Get set of dates that already have words.
        
        Args:
            start_date: Start date (inclusive).
            end_date: End date (inclusive).
            
        Returns:
            Set of date strings (YYYY-MM-DD) that exist.
        """
        words = self.get_words_by_date_range(start_date, end_date)
        return {word["date"] for word in words}

    def save_words(self, words: list[dict]) -> int:
        """Save generated words to Firestore.
        
        Args:
            words: List of word dictionaries with 'date', 'word', 'reading', 'word_en' keys.
            
        Returns:
            Number of words saved.
        """
        batch = self._db.batch()
        count = 0

        for word in words:
            # Use date as document ID for easy lookup and deduplication
            doc_ref = self._db.collection(self.COLLECTION_NAME).document(
                word["date"]
            )
            batch.set(doc_ref, word)
            count += 1

        batch.commit()
        return count

    def get_word_by_date(self, target_date: date) -> Optional[dict]:
        """Get a single word by date.
        
        Args:
            target_date: The date to look up.
            
        Returns:
            Word document if found, None otherwise.
        """
        doc_ref = self._db.collection(self.COLLECTION_NAME).document(
            target_date.isoformat()
        )
        doc = doc_ref.get()

        if doc.exists:
            return doc.to_dict()
        return None
