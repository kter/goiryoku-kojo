"""Cloud Function to score user answers using Gemini AI."""

import json
import logging
import os
import time
import traceback
from collections import defaultdict
from http import HTTPStatus
from threading import Lock

import functions_framework
from flask import Request, Response

from gemini_client import GeminiClient, GeminiClientError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = os.environ.get("GCP_PROJECT")

# Rate limiting configuration
RATE_LIMIT_WINDOW_SECONDS = 60  # 1 minute window
RATE_LIMIT_MAX_REQUESTS = 10  # Max 10 requests per window

# In-memory rate limiting storage
# Note: This is per-instance and not shared across Cloud Functions instances
_rate_limit_store: dict[str, list[float]] = defaultdict(list)
_rate_limit_lock = Lock()


def _get_client_ip(request: Request) -> str:
    """Extract client IP from request, considering proxies."""
    # X-Forwarded-For may contain multiple IPs; take the first one
    forwarded_for = request.headers.get("X-Forwarded-For", "")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    return request.remote_addr or "unknown"


def _cleanup_old_requests(timestamps: list[float], window_start: float) -> list[float]:
    """Remove timestamps older than the rate limit window."""
    return [ts for ts in timestamps if ts > window_start]


def _check_rate_limit(client_ip: str) -> tuple[bool, int]:
    """Check if the client IP has exceeded the rate limit.
    
    Returns:
        tuple: (is_allowed, retry_after_seconds)
            - is_allowed: True if request is allowed, False if rate limited
            - retry_after_seconds: Seconds until rate limit resets (0 if allowed)
    """
    current_time = time.time()
    window_start = current_time - RATE_LIMIT_WINDOW_SECONDS
    
    with _rate_limit_lock:
        # Cleanup old requests
        _rate_limit_store[client_ip] = _cleanup_old_requests(
            _rate_limit_store[client_ip], window_start
        )
        
        request_count = len(_rate_limit_store[client_ip])
        
        if request_count >= RATE_LIMIT_MAX_REQUESTS:
            # Calculate when the oldest request in the window will expire
            oldest_in_window = min(_rate_limit_store[client_ip])
            retry_after = int(oldest_in_window + RATE_LIMIT_WINDOW_SECONDS - current_time) + 1
            return False, max(1, retry_after)
        
        # Record this request
        _rate_limit_store[client_ip].append(current_time)
        return True, 0


@functions_framework.http
def score_answers(request: Request) -> Response:
    """HTTP Cloud Function to score user answers.
    
    Args:
        request: Flask request object with JSON body:
            - word: The target word (お題)
            - answers: List of user's answers
            - game_type: "word_replacement" or "rhyming"
        
    Returns:
        JSON response with score and feedback.
    """
    # Handle CORS preflight
    if request.method == "OPTIONS":
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "3600",
        }
        return Response("", status=HTTPStatus.NO_CONTENT, headers=headers)

    headers = {"Access-Control-Allow-Origin": "*"}

    # Rate limiting check
    client_ip = _get_client_ip(request)
    is_allowed, retry_after = _check_rate_limit(client_ip)
    
    if not is_allowed:
        logger.warning(f"Rate limit exceeded for IP: {client_ip}")
        rate_limit_headers = {
            **headers,
            "Retry-After": str(retry_after),
        }
        return Response(
            json.dumps(
                {
                    "success": False,
                    "error": "リクエスト制限を超えました。しばらくしてから再度お試しください。",
                },
                ensure_ascii=False,
            ),
            status=HTTPStatus.TOO_MANY_REQUESTS,
            mimetype="application/json",
            headers=rate_limit_headers,
        )

    try:
        request_json = request.get_json(silent=True)
        
        if not request_json:
            return Response(
                '{"success": false, "error": "Request body is required"}',
                status=HTTPStatus.BAD_REQUEST,
                mimetype="application/json",
                headers=headers,
            )

        word = request_json.get("word")
        answers = request_json.get("answers", [])
        game_type = request_json.get("game_type")

        if not word:
            return Response(
                '{"success": false, "error": "word is required"}',
                status=HTTPStatus.BAD_REQUEST,
                mimetype="application/json",
                headers=headers,
            )

        if not game_type or game_type not in ["word_replacement", "rhyming"]:
            return Response(
                '{"success": false, "error": "game_type must be word_replacement or rhyming"}',
                status=HTTPStatus.BAD_REQUEST,
                mimetype="application/json",
                headers=headers,
            )

        logger.info(f"Scoring answers for word: {word}, game_type: {game_type}, answers: {answers}")

        gemini_client = GeminiClient(project_id=PROJECT_ID)
        result = gemini_client.score_answers(
            word=word,
            answers=answers,
            game_type=game_type,
        )

        response_data = {
            "success": True,
            "score": result.get("score", 0),
            "feedback": result.get("feedback", ""),
        }

        return Response(
            json.dumps(response_data, ensure_ascii=False),
            status=HTTPStatus.OK,
            mimetype="application/json",
            headers=headers,
        )

    except GeminiClientError as e:
        logger.error(f"Gemini API error: {e}")
        logger.error(traceback.format_exc())
        return Response(
            json.dumps({"success": False, "error": f"AI scoring failed: {str(e)}"}, ensure_ascii=False),
            status=HTTPStatus.INTERNAL_SERVER_ERROR,
            mimetype="application/json",
            headers=headers,
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        logger.error(traceback.format_exc())
        return Response(
            json.dumps({"success": False, "error": f"Internal server error: {str(e)}"}, ensure_ascii=False),
            status=HTTPStatus.INTERNAL_SERVER_ERROR,
            mimetype="application/json",
            headers=headers,
        )
