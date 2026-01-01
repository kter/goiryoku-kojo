output "get_words_url" {
  description = "URL of the get_words HTTP function"
  value       = google_cloudfunctions2_function.get_words.service_config[0].uri
}

output "generate_words_url" {
  description = "URL of the generate_words HTTP function"
  value       = google_cloudfunctions2_function.generate_words.service_config[0].uri
}

output "service_account_email" {
  description = "Service account email used by Cloud Functions"
  value       = google_service_account.functions_sa.email
}

output "score_answers_url" {
  description = "URL of the score_answers HTTP function"
  value       = google_cloudfunctions2_function.score_answers.service_config[0].uri
}
