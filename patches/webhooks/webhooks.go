package webhooks

import (
	"bytes"
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/rs/zerolog/log"
)

type WebhookConfig struct {
	URL string `json:"url"`
}

var httpClient = &http.Client{
	Timeout: 15 * time.Second,
}

func loadWebhooks(webhookFile string) (map[string]WebhookConfig, error) {
	data, err := os.ReadFile(webhookFile)
	if err != nil {
		return nil, err
	}
	var hooks map[string]WebhookConfig
	if err := json.Unmarshal(data, &hooks); err != nil {
		return nil, err
	}
	return hooks, nil
}

func TriggerWebhook(destination string, hookName string, payload map[string]interface{}) {
	webhookFile := filepath.Join(destination, "webhooks.json")

	log.Info().
		Str("webhookFile", webhookFile).
		Str("hookName", hookName).
		Msg("Looking up webhook")
	webhooks, err := loadWebhooks(webhookFile)
	if err != nil {
		if !os.IsNotExist(err) {
			log.Warn().
				Err(err).
				Str("file", webhookFile).
				Msg("Failed to read webhook file")
		} else {
			log.Info().
				Str("file", webhookFile).
				Msg("Webhook file does not exist, skipping webhook trigger")
		}
		return
	}

	configMap, ok := webhooks[hookName]
	if !ok {
		log.Info().
			Str("hookName", hookName).
			Msg("Webhook config is missing or not a map, skipping webhook trigger")
		return
	}

	if configMap.URL == "" {
		log.Warn().
			Str("hookName", hookName).
			Msg("Webhook URL is empty, skipping webhook trigger")
		return
	}

	log.Info().
		Str("url", configMap.URL).
		Str("hookName", hookName).
		Msg("Triggering webhook")

	body, err := json.Marshal(payload)
	if err != nil {
		log.Warn().
			Err(err).
			Msg("Failed to serialize webhook payload")
		return
	}

	req, err := http.NewRequest("POST", configMap.URL, bytes.NewBuffer(body))
	if err != nil {
		log.Warn().
			Err(err).
			Msg("Failed to create webhook request")
		return
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := httpClient.Do(req)
	if err != nil {
		log.Warn().
			Err(err).
			Str("url", configMap.URL).
			Msg("Webhook call failed")
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		log.Warn().
			Int("status", resp.StatusCode).
			Str("url", configMap.URL).
			Msg("Webhook call returned non-2xx status code")
	} else {
		log.Info().
			Int("status", resp.StatusCode).
			Str("url", configMap.URL).
			Msg("Webhook call succeeded")
	}
}
