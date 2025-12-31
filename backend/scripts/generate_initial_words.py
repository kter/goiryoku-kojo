#!/usr/bin/env python3
"""CLI script to generate initial vocabulary words.

This script generates vocabulary words for the specified number of days
starting from today. Use this for initial setup or manual generation.

Usage:
    python generate_initial_words.py --days 30
    python generate_initial_words.py --days 7 --dry-run
"""

import argparse
import logging
import sys
from datetime import date, timedelta
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "functions" / "shared"))

from firestore_client import FirestoreClient
from gemini_client import GeminiClient, GeminiClientError

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def get_missing_dates(
    firestore_client: FirestoreClient,
    start_date: date,
    end_date: date
) -> list[str]:
    """Find dates that don't have words generated yet."""
    existing_dates = firestore_client.get_existing_dates(start_date, end_date)
    
    missing_dates = []
    current = start_date
    while current <= end_date:
        date_str = current.isoformat()
        if date_str not in existing_dates:
            missing_dates.append(date_str)
        current += timedelta(days=1)
    
    return missing_dates


def main():
    parser = argparse.ArgumentParser(
        description="Generate initial vocabulary words"
    )
    parser.add_argument(
        "--days",
        type=int,
        default=30,
        help="Number of days to generate words for (default: 30)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be generated without saving"
    )
    parser.add_argument(
        "--project",
        type=str,
        default=None,
        help="GCP project ID (uses default if not specified)"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=10,
        help="Number of words to generate per API call (default: 10)"
    )
    
    args = parser.parse_args()
    
    logger.info(f"Starting word generation for {args.days} days")
    
    # Initialize clients
    firestore_client = FirestoreClient(project_id=args.project)
    gemini_client = GeminiClient(project_id=args.project)
    
    # Calculate date range
    today = date.today()
    end_date = today + timedelta(days=args.days - 1)
    
    # Find missing dates
    missing_dates = get_missing_dates(firestore_client, today, end_date)
    
    if not missing_dates:
        logger.info("All dates already have words. Nothing to generate.")
        return 0
    
    logger.info(f"Found {len(missing_dates)} dates needing words")
    
    # Get recent words to avoid duplication
    recent_words = firestore_client.get_recent_words(days=10)
    recent_word_list = [w["word"] for w in recent_words]
    
    logger.info(f"Recent words to avoid: {recent_word_list}")
    
    # Generate in batches
    all_generated = []
    for i in range(0, len(missing_dates), args.batch_size):
        batch_dates = missing_dates[i:i + args.batch_size]
        logger.info(f"Generating batch {i // args.batch_size + 1}: {batch_dates}")
        
        try:
            generated_words = gemini_client.generate_words(
                dates=batch_dates,
                recent_words=recent_word_list + [w["word"] for w in all_generated]
            )
            
            if args.dry_run:
                logger.info(f"[DRY RUN] Would save: {generated_words}")
            else:
                firestore_client.save_words(generated_words)
                logger.info(f"Saved {len(generated_words)} words")
            
            all_generated.extend(generated_words)
            
        except GeminiClientError as e:
            logger.error(f"Failed to generate words: {e}")
            return 1
    
    total = len(all_generated)
    if args.dry_run:
        logger.info(f"[DRY RUN] Would have generated {total} words total")
    else:
        logger.info(f"Successfully generated {total} words")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
