package webhooks

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"time"

	"github.com/rs/zerolog/log"
)

type WebhookConfig struct {
	URL string `json:"url"`
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

var httpClient = &http.Client{
	Timeout: 15 * time.Second,
}

func postWebhook(url string, payload any) (*http.Response, error) {
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	return httpClient.Do(req)
}

func isValidURL(raw string) bool {
	u, err := url.ParseRequestURI(raw)
	return err == nil && u.Scheme != "" && u.Host != ""
}

func TriggerWebhook(destination string, hookName string, payload map[string]any) {
	webhookFile := filepath.Join(destination, "webhooks.json")
	logger := log.With().
		Str("hookName", hookName).
		Str("webhookFile", webhookFile).
		Logger()
	logger.Info().
		Msg("Looking up webhook")

	webhooks, err := loadWebhooks(webhookFile)
	if err != nil {
		if !os.IsNotExist(err) {
			logger.Warn().
				Err(err).
				Msg("Failed to read webhook file")
		} else {
			logger.Info().
				Msg("Webhook file does not exist, skipping")
		}
		return
	}

	hookConfig, ok := webhooks[hookName]
	if !ok {
		logger.Info().
			Msg("Webhook config is missing, skipping")
		return
	}
	if !isValidURL(hookConfig.URL) {
		logger.Warn().
			Msg("Invalid webhook URL, skipping")
		return
	}

	logger.Info().
		Str("url", hookConfig.URL).
		Msg("Triggering webhook")

	resp, err := postWebhook(hookConfig.URL, payload)
	if err != nil {
		logger.Warn().
			Err(err).
			Str("url", hookConfig.URL).
			Msg("Failed to post webhook")
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		logger.Warn().
			Int("status", resp.StatusCode).
			Str("url", hookConfig.URL).
			Msg("Webhook call returned non-2xx status code")
	} else {
		logger.Info().
			Int("status", resp.StatusCode).
			Str("url", hookConfig.URL).
			Msg("Webhook call succeeded")
	}
}
