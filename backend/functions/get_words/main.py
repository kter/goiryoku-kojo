"""HTTP function to get vocabulary words for the mobile app."""

import json
import logging
from datetime import date, timedelta
from http import HTTPStatus

import functions_framework
from flask import Request, Response

# In Cloud Functions, all source files are bundled in the same directory
from firestore_client import FirestoreClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger = logging.getLogger(__name__)

# CORS headers for Flutter app access
CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "3600",
}


def create_response(
    data: dict,
    status: int = HTTPStatus.OK
) -> Response:
    """Create a JSON response with CORS headers.
    
    Args:
        data: Response data dictionary.
        status: HTTP status code.
        
    Returns:
        Flask Response object.
    """
    response = Response(
        json.dumps(data, ensure_ascii=False),
        status=status,
        mimetype="application/json"
    )
    for key, value in CORS_HEADERS.items():
        response.headers[key] = value
    return response


@functions_framework.http
def get_words(request: Request) -> Response:
    """HTTP Cloud Function to get vocabulary words.
    
    Retrieves up to 30 days of words starting from today.
    Returns available words even if some dates are missing.
    
    Args:
        request: Flask request object.
        
    Returns:
        JSON response with words list.
    """
    # Handle CORS preflight request
    if request.method == "OPTIONS":
        return create_response({}, HTTPStatus.NO_CONTENT)

    if request.method != "GET":
        return create_response(
            {"error": "Method not allowed"},
            HTTPStatus.METHOD_NOT_ALLOWED
        )

    try:
        # Get optional query parameters
        days = request.args.get("days", default=30, type=int)
        days = min(max(days, 1), 30)  # Clamp between 1 and 30
        
        # Calculate date range
        today = date.today()
        end_date = today + timedelta(days=days - 1)
        
        # Fetch words from Firestore
        client = FirestoreClient()
        words = client.get_words_by_date_range(today, end_date)
        
        # Return available words (no error even if some dates are missing)
        return create_response({
            "success": True,
            "count": len(words),
            "words": words,
            "date_range": {
                "start": today.isoformat(),
                "end": end_date.isoformat()
            }
        })
        
    except Exception as e:
        logger.error(f"Error fetching words: {e}")
        return create_response(
            {
                "success": False,
                "error": "Internal server error",
                "words": []
            },
            HTTPStatus.INTERNAL_SERVER_ERROR
        )
