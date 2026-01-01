"""Batch function to generate vocabulary words using Gemini 1.5 Flash."""

import logging
import os
import traceback
from datetime import date, timedelta
from http import HTTPStatus

import functions_framework
from flask import Request, Response

# In Cloud Functions, all source files are bundled in the same directory
from firestore_client import FirestoreClient
from gemini_client import GeminiClient, GeminiClientError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get project ID from environment variable
PROJECT_ID = os.environ.get("GCP_PROJECT")


def get_missing_dates(
    firestore_client: FirestoreClient,
    start_date: date,
    end_date: date
) -> list[str]:
    """Find dates that don't have words generated yet.
    
    Args:
        firestore_client: Firestore client instance.
        start_date: Start date (inclusive).
        end_date: End date (inclusive).
        
    Returns:
        List of missing date strings (YYYY-MM-DD).
    """
    existing_dates = firestore_client.get_existing_dates(start_date, end_date)
    
    missing_dates = []
    current = start_date
    while current <= end_date:
        date_str = current.isoformat()
        if date_str not in existing_dates:
            missing_dates.append(date_str)
        current += timedelta(days=1)
    
    return missing_dates


@functions_framework.http
def generate_words(request: Request) -> Response:
    """HTTP Cloud Function to generate vocabulary words.
    
    Triggered by Cloud Scheduler daily at 0:00 JST.
    Generates words for any missing dates in the next 7 days.
    
    Args:
        request: Flask request object.
        
    Returns:
        JSON response with generation results.
    """
    try:
        logger.info(f"Starting generate_words function. PROJECT_ID={PROJECT_ID}")
        
        # Initialize clients with explicit project ID
        firestore_client = FirestoreClient(project_id=PROJECT_ID)
        gemini_client = GeminiClient(project_id=PROJECT_ID)
        
        # Define date range: today to 7 days ahead
        today = date.today()
        end_date = today + timedelta(days=7)
        
        # Find missing dates
        missing_dates = get_missing_dates(firestore_client, today, end_date)
        
        if not missing_dates:
            logger.info("No missing dates found. Skipping generation.")
            return Response(
                '{"success": true, "message": "No generation needed", "generated": 0}',
                status=HTTPStatus.OK,
                mimetype="application/json"
            )
        
        logger.info(f"Generating words for {len(missing_dates)} dates: {missing_dates}")
        
        # Get recent words to avoid duplication
        recent_words = firestore_client.get_recent_words(days=10)
        recent_word_list = [w["word"] for w in recent_words]
        
        logger.info(f"Recent words to avoid: {recent_word_list}")
        
        # Generate words using Gemini
        generated_words = gemini_client.generate_words(
            dates=missing_dates,
            recent_words=recent_word_list
        )
        
        if not generated_words:
            logger.warning("No words generated from Gemini")
            return Response(
                '{"success": false, "error": "No words generated", "generated": 0}',
                status=HTTPStatus.INTERNAL_SERVER_ERROR,
                mimetype="application/json"
            )
        
        # Save to Firestore
        saved_count = firestore_client.save_words(generated_words)
        
        logger.info(f"Successfully generated and saved {saved_count} words")
        
        return Response(
            f'{{"success": true, "generated": {saved_count}, "dates": {missing_dates}}}',
            status=HTTPStatus.OK,
            mimetype="application/json"
        )
        
    except GeminiClientError as e:
        logger.error(f"Gemini API error: {e}")
        logger.error(traceback.format_exc())
        return Response(
            f'{{"success": false, "error": "AI generation failed: {str(e)}"}}',
            status=HTTPStatus.INTERNAL_SERVER_ERROR,
            mimetype="application/json"
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        logger.error(traceback.format_exc())
        return Response(
            f'{{"success": false, "error": "Internal server error: {str(e)}"}}',
            status=HTTPStatus.INTERNAL_SERVER_ERROR,
            mimetype="application/json"
        )
