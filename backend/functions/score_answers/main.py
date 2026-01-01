"""Cloud Function to score user answers using Gemini AI."""

import json
import logging
import os
import traceback
from http import HTTPStatus

import functions_framework
from flask import Request, Response

from gemini_client import GeminiClient, GeminiClientError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = os.environ.get("GCP_PROJECT")


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
